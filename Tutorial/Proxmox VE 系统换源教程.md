# Proxmox VE 换源教程

- PS：打开 PVE 节点的 Shell 操作

- PS：推荐 SSH 工具【[点击进入下载 MobaXterm](https://mobaxterm.mobatek.net/download.html)】、【[点击进入下载 FinalShell](https://www.hostbuf.com/t/988.html)】

## 一、更换企业源

### 1、使用以下命令，添加源

```bash
cat << EOF > /etc/apt/sources.list.d/pve-enterprise.list
deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/pve bookworm pve-no-subscription
EOF
```

## 二、更换其他源

### 1、使用以下命令，添加源（二选一）

#### PS：下面的源也适用于 Debian 12 系统 （包括 LXC 安装的系统）

- ## （清华）

```bash
cat << EOF > /etc/apt/sources.list
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
```

- ## （中科大）

```bash
cat << EOF > /etc/apt/sources.list
deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
```

## 三、修复源401错误、增加pve无订阅源

### 使用以下命令，修复源401错误

```bash
cat << EOF > /etc/apt/sources.list.d/ceph.list
deb https://mirrors.ustc.edu.cn/proxmox/debian/ceph-quincy bookworm no-subscription
EOF
```

### 使用以下命令，增加pve无订阅源

```bash
cat << EOF > /etc/apt/sources.list.d/pve-no-subscription.list
deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian bookworm pve-no-subscription
EOF
```

## 四、更换LXC源

### 使用以下命令

```bash
sed -i 's|http://download.proxmox.com|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
```

## 五、删除订阅弹窗

### 使用以下命令，执行完成后，需注销PVE登录后, 重新启动浏览器

```bash
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
```

## 六、重启网络服务

```bash
systemctl restart pvedaemon.service
```
