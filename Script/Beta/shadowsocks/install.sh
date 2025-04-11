#!/bin/bash
#!name = ss 一键安装脚本 Beta
#!desc = 安装 & 配置
#!date = 2025-04-11 20:01:09
#!author = ChatGPT

# 终止脚本执行遇到错误时退出，并启用管道错误检测
set -e -o pipefail

#############################
#         颜色变量         #
#############################
red="\033[31m"    # 红色
green="\033[32m"  # 绿色
yellow="\033[33m" # 黄色
blue="\033[34m"   # 蓝色
cyan="\033[36m"   # 青色
reset="\033[0m"   # 重置颜色

#############################
#       全局变量定义       #
#############################
sh_ver="1.0.0"
use_cdn=false
distro="unknown"  # 系统类型：debian, ubuntu, alpine, fedora
arch=""           # 系统架构
arch_raw=""       # 原始架构信息

#############################
#       系统检测函数       #
#############################
check_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu)
                distro="$ID"
                pkg_update="apt update && apt upgrade -y"
                pkg_install="apt install -y"
                service_enable() { systemctl enable shadowsocks; }
                service_restart() { systemctl daemon-reload; systemctl start shadowsocks; }
                ;;
            alpine)
                distro="alpine"
                pkg_update="apk update && apk upgrade"
                pkg_install="apk add"
                service_enable() { rc-update add shadowsocks default; }
                service_restart() { rc-service shadowsocks restart; }
                ;;
            fedora)
                distro="fedora"
                pkg_update="dnf upgrade --refresh -y"
                pkg_install="dnf install -y"
                service_enable() { systemctl enable shadowsocks; }
                service_restart() { systemctl daemon-reload; systemctl start shadowsocks; }
                ;;
            arch)
                distro="arch"
                pkg_update="pacman -Syu --noconfirm"
                pkg_install="pacman -S --noconfirm"
                service_enable() { systemctl enable shadowsocks; }
                service_restart() { systemctl daemon-reload; systemctl start shadowsocks; }
                ;;
            *)
                echo -e "${red}不支持的系统：${ID}${reset}"
                exit 1
                ;;
        esac
    else
        echo -e "${red}无法识别当前系统类型${reset}"
        exit 1
    fi
}

#############################
#       网络检测函数       #
#############################
check_network() {
    if ! curl -s --head --fail --connect-timeout 3 -o /dev/null "https://www.google.com"; then
        echo -e "${green}检测到没有有科学环境，使用 CDN${reset}" >&2
        use_cdn=true
    else
        echo -e "${green}检测到有科学环境，不使用 CDN${reset}" >&2
        use_cdn=false
    fi
}

#############################
#        URL 处理函数       #
#############################
get_url() {
    local url=$1
    local final_url
    if [ "$use_cdn" = true ]; then
        final_url="https://gh-proxy.com/$url"
        if ! curl --silent --head --fail --connect-timeout 3 -L "$final_url" -o /dev/null; then
            final_url="https://github.boki.moe/$url"
        fi
    else
        final_url="$url"
    fi
    if ! curl --silent --head --fail --connect-timeout 3 -L "$final_url" -o /dev/null; then
        echo -e "${red}连接失败，可能是网络或代理站点不可用，请检查后重试！${reset}" >&2
        return 1
    fi
    echo "$final_url"
}

#############################
#    系统更新及安装函数    #
#############################
update_system() {
    eval "$pkg_update"
    eval "$pkg_install curl git gzip wget nano iptables tzdata jq unzip"
}

#############################
#     系统架构检测函数     #
#############################
get_schema() {
    arch_raw=$(uname -m)
    case "$arch_raw" in
        x86_64)
            arch="amd64"
            ;;
        x86|i686|i386)
            arch="386"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        armv7l)
            arch="armv7"
            ;;
        s390x)
            arch="s390x"
            ;;
        *)
            echo -e "${red}不支持的架构：${arch_raw}${reset}"
            exit 1
            ;;
    esac
}

#############################
#      远程版本获取函数     #
#############################
download_version() {
    local version_url="https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest"
    version=$(curl -sSL "$version_url" | jq -r '.tag_name' | sed 's/v//') || {
        echo -e "${red}获取 shadowsocks 远程版本失败${reset}";
        exit 1;
    }
}

#############################
#     shadowsocks 下载函数      #
#############################
download_shadowsocks() {
    download_version
    local version_file="/root/shadowsocks/version.txt"
    local filename="shadowsocks-v${version}.${arch_raw}-unknown-linux-gnu.tar.xz"
    local download_url="https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${version}/${filename}"
    wget -t 3 -T 30 -O "$filename" "$(get_url "$download_url")" || {
        echo -e "${red}shadowsocks 下载失败，请检查网络后重试${reset}"
        exit 1
    }
    tar -xJf "$filename" || {
        echo -e "${red}shadowsocks 解压失败${reset}"
        exit 1
    }
    if [ -f "ssserver" ]; then
        mv "ssserver" shadowsocks
    else
        echo -e "${red}找不到解压后的 ssserver 文件${reset}"
        exit 1
    fi
    rm -f "$filename"
    chmod +x shadowsocks
    echo "$version" > "$version_file"
}

#############################
#   系统服务配置下载函数    #
#############################
download_service() {
    if [ "$distro" = "alpine" ]; then
        local service_file="/etc/init.d/shadowsocks"
        local service_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Service/shadowsocks.openrc"
        wget -t 3 -T 30 -O "$service_file" "$(get_url "$service_url")" || {
            echo -e "${red}系统服务下载失败，请检查网络后重试${reset}"
            exit 1
        }
        chmod +x "$service_file"
        service_enable
    else
        local service_file="/etc/systemd/system/shadowsocks.service"
        local service_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Service/shadowsocks.service"
        wget -t 3 -T 30 -O "$service_file" "$(get_url "$service_url")" || {
            echo -e "${red}系统服务下载失败，请检查网络后重试${reset}"
            exit 1
        }
        chmod +x "$service_file"
        service_enable
    fi
}

#############################
#    管理脚本下载函数      #
#############################
download_shell() {
    local shell_file="/usr/bin/ssr"
    local sh_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Script/Beta/shadowsocks/shadowsocks.sh"
    [ -f "$shell_file" ] && rm -f "$shell_file"
    wget -t 3 -T 30 -O "$shell_file" "$(get_url "$sh_url")" || {
        echo -e "${red}管理脚本下载失败，请检查网络后重试${reset}"
        exit 1
    }
    chmod +x "$shell_file"
    hash -r
}

#############################
#       配置文件生成函数     #
#############################
enable_systfo() {
    kernel_major=$(uname -r | cut -d. -f1)
    if [ "$kernel_major" -ge 3 ]; then
        # 开启 TCP Fast Open（若文件存在则设置值为 3）
        if [ -f /proc/sys/net/ipv4/tcp_fastopen ]; then
            echo 3 > /proc/sys/net/ipv4/tcp_fastopen
        fi

        # 定义 sysctl 配置文件路径
        SYSCTL_CONF="/etc/sysctl.d/99-systfo.conf"
        # 如果配置文件不存在，则写入网络优化参数
        if [ ! -f "$SYSCTL_CONF" ]; then
            cat <<EOF > "$SYSCTL_CONF"
fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 4096
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_ecn = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
            # 应用配置
            sysctl --system >/dev/null 2>&1
        fi
        echo -e "${Green_font_prefix}TCP Fast Open 已启用并应用网络优化参数${Font_color_suffix}"
    else
        echo -e "${Red_font_prefix}系统内核版本过低，无法支持 TCP Fast Open！${Font_color_suffix}"
    fi
}

config_shadowsocks() {
    local config_file="/root/shadowsocks/config.json"
    local config_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Config/shadowsocks.json"
    wget -t 3 -T 30 -q -O "$config_file" "$(get_url "$config_url")" || { 
        echo -e "${red}配置文件下载失败${reset}"
        exit 1
    }
    echo -e "${green}开始配置 Shadowsocks ${reset}"
    
    # 提示是否快速生成配置文件
    read -rp "是否快速生成配置文件？(y/n 默认[y]): " quick_confirm
    quick_confirm=${quick_confirm:-y}
    
    if [[ "$quick_confirm" == [Yy] ]]; then
        # 自动随机生成端口
        PORT=$(shuf -i 10000-65000 -n 1)
        
        # 选择加密方式
        echo -e "请选择加密方式："
        echo -e "${green}1${reset}、aes-128-gcm"
        echo -e "${green}2${reset}、aes-256-gcm"
        echo -e "${green}3${reset}、chacha20-ietf-poly1305"
        echo -e "${green}4${reset}、2022-blake3-aes-128-gcm"
        echo -e "${green}5${reset}、2022-blake3-aes-256-gcm"
        echo -e "${green}6${reset}、2022-blake3-chacha20-ietf-poly1305"
        read -rp "输入数字选择加密方式 (1-6 默认[1]): " method_choice
        method_choice=${method_choice:-1}
        case $method_choice in
            1) METHOD="aes-128-gcm" ;;
            2) METHOD="aes-256-gcm" ;;
            3) METHOD="chacha20-ietf-poly1305" ;;
            4) METHOD="2022-blake3-aes-128-gcm" ;;
            5) METHOD="2022-blake3-aes-256-gcm" ;;
            6) METHOD="2022-blake3-chacha20-ietf-poly1305" ;;         
            *) METHOD="aes-128-gcm" ;;
        esac

        # 选择认证方式：自定义密码或自动生成 UUID
        echo -e "请选择认证模式："
        echo -e "${green}1${reset}、自定义密码"
        echo -e "${green}2${reset}、自动生成 UUID 当作密码"
        read -rp "输入数字选择认证模式 (1-2 默认[1]): " auth_choice
        auth_choice=${auth_choice:-1}
        if [[ "$auth_choice" == "1" ]]; then
            read -rp "请输入 Shadowsocks 密码 (留空则自动生成 UUID): " PASSWORD
            if [[ -z "$PASSWORD" ]]; then
                PASSWORD=$(cat /proc/sys/kernel/random/uuid)
            fi
        else
            PASSWORD=$(cat /proc/sys/kernel/random/uuid)
        fi
    else
        # 手动模式：用户输入端口、加密方式以及认证信息
        read -p "请输入监听端口 (留空以随机生成端口): " PORT
        if [[ -z "$PORT" ]]; then
            PORT=$(shuf -i 10000-65000 -n 1)
        elif [[ "$PORT" -lt 10000 || "$PORT" -gt 65000 ]]; then
            echo -e "${red}端口号必须在10000到65000之间。${reset}"
            exit 1
        fi
        
        echo -e "请选择加密方式："
        echo -e "${green}1${reset}、aes-128-gcm"
        echo -e "${green}2${reset}、aes-256-gcm"
        echo -e "${green}3${reset}、chacha20-ietf-poly1305"
        echo -e "${green}4${reset}、2022-blake3-aes-128-gcm"
        echo -e "${green}5${reset}、2022-blake3-aes-256-gcm"
        echo -e "${green}6${reset}、2022-blake3-chacha20-ietf-poly1305"
        read -rp "输入数字选择加密方式 (1-6 默认[1]): " method_choice
        method_choice=${method_choice:-1}
        case $method_choice in
            1) METHOD="aes-128-gcm" ;;
            2) METHOD="aes-256-gcm" ;;
            3) METHOD="chacha20-ietf-poly1305" ;;
            4) METHOD="2022-blake3-aes-128-gcm" ;;
            5) METHOD="2022-blake3-aes-256-gcm" ;;
            6) METHOD="2022-blake3-chacha20-ietf-poly1305" ;;         
            *) METHOD="aes-128-gcm" ;;
        esac
        
        echo -e "请选择认证模式："
        echo -e "${green}1${reset}、自定义密码"
        echo -e "${green}2${reset}、自动生成 UUID 当作密码"
        read -rp "输入数字选择认证模式 (1-2 默认[2]): " auth_choice
        auth_choice=${auth_choice:-1}
        if [[ "$auth_choice" == "2" ]]; then
            read -rp "请输入 Shadowsocks 密码 (留空则自动生成 UUID): " PASSWORD
            if [[ -z "$PASSWORD" ]]; then
                PASSWORD=$(cat /proc/sys/kernel/random/uuid)
            fi
        else
            PASSWORD=$(cat /proc/sys/kernel/random/uuid)
        fi
    fi

    echo -e "${green}生成的配置参数如下：${reset}"
    echo -e "  - 端口: ${green}$PORT${reset}"
    echo -e "  - 加密方式: ${green}$METHOD${reset}"
    echo -e "  - 密码: ${green}$PASSWORD${reset}"

    echo -e "${green}读取配置文件模板${reset}"
    config=$(cat "$config_file")
    echo -e "${green}修改配置文件${reset}"
    config=$(echo "$config" | jq --arg port "$PORT" --arg password "$PASSWORD" --arg method "$METHOD" '
        .server_port = ($port | tonumber) |
        .password = $password |
        .method = $method
    ')
    
    echo -e "${green}写入配置文件${reset}"
    echo "$config" > "$config_file"
    
    echo -e "${green}验证修改后的配置文件格式${reset}"
    if ! jq . "$config_file" >/dev/null 2>&1; then
        echo -e "${red}修改后的配置文件格式无效，请检查文件${reset}"
        exit 1
    fi
    
    service_restart
    echo -e "${green}Shadowsocks 配置已完成并保存到 ${config_file} 文件${reset}"
    echo -e "${green}Shadowsocks 配置完成，正在启动中${reset}"
    echo -e "${red}管理命令${reset}"
    echo -e "${cyan}=========================${reset}"
    echo -e "${green}命令: ssr 进入管理菜单${reset}"
    echo -e "${cyan}=========================${reset}"
    echo -e "${green}Shadowsocks 已成功启动并设置为开机自启${reset}"
}

#############################
#       安装主流程函数      #
#############################
install_shadowsocks() {
    local folders="/root/shadowsocks"
    rm -rf "$folders"
    mkdir -p "$folders" && cd "$folders"
    enable_systfo
    check_distro
    echo -e "${yellow}当前系统版本：${reset}[ ${green}${distro}${reset} ]"
    get_schema
    echo -e "${yellow}当前系统架构：${reset}[ ${green}${arch_raw}${reset} ]"
    download_version
    echo -e "${yellow}当前软件版本：${reset}[ ${green}${version}${reset} ]"
    download_shadowsocks
    download_service
    download_shell
    echo -e "${green}恭喜你! shadowsocks 已经安装完成${reset}"
    echo -e "${red}输入 y/Y 下载默认配置${reset}"
    echo -e "${red}输入 n/N 取消下载默认配置${reset}"
    echo -e "${red}把你自己的配置上传到 ${folders} 目录下(文件名必须为 config.yaml)${reset}"
    read -p "$(echo -e "${yellow}请输入选择(y/n) [默认: y]: ${reset}")" confirm
    confirm=${confirm:-y}
    case "$confirm" in
        [Yy]*)
            config_shadowsocks
            ;;
        [Nn]*)
            echo -e "${green}跳过配置文件下载${reset}"
            ;;
         *)
            echo -e "${red}无效选择，跳过配置文件下载，需自己手动上传${reset}"
            ;;
    esac
    rm -f /root/install.sh
}

#############################
#           主流程          #
#############################
check_distro
check_network
update_system
install_shadowsocks