# Linux 系统安装 AdGuardHome 教程

- PS：适用于 Alpine & Debian & Ubuntu 系统；

- PS：推荐SSH工具【[点击进入下载 MobaXterm](https://mobaxterm.mobatek.net/download.html)】、【[点击进入下载 FinalShell](https://www.hostbuf.com/t/988.html)】；

- PS：升级更新更换好【[点击此处查看 LXC 源](https://github.com/axcsz/Collect/wiki/Proxmox-VE-%E7%B3%BB%E7%BB%9F-%E6%8D%A2%E6%BA%90%E6%95%99%E7%A8%8B)】；

- PS：如果使用第三方工具需要先开启允许登录。【[点击此处查看如何开启](https://github.com/axcsz/Collect/wiki/Linux-%E7%B3%BB%E7%BB%9F-ROOT-%E8%BF%9C%E7%A8%8B%E7%99%BB%E9%99%86%E5%BC%80%E5%90%AF%E6%95%99%E7%A8%8B)】。

## Debian & Ubuntu 系统 AdGuard Home 安装教程

### 一、使用以下命令，更新

```bash
apt update && apt dist-upgrade -y
```

### 二、使用以下命令，安装必要插件

```bash
apt install -y curl git wget nano
```

### 三、使用以下命令，一键安装

#### 使用下面命令，安装 AdGuardHome

```bash
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
```

#### 使用下面命令，安装 AdGuardHome （国内加速地址）

```bash
curl -s -S -L https://mirror.ghproxy.com/https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
```

---

## Alpine 系统 AdGuard Home 安装教程

### 1、使用以下命令，更新

```bash
apk update && apk upgrade
```

### 2、使用以下命令，安装必要插件

```bash
apk add curl
```

### 2、使用以下命令，一键安装

```bash
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
```
