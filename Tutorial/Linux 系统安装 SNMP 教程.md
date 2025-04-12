# Linux 系统安装 SNMP 教程

- PS：适用于 Alpine & Debian & Ubuntu 系统；

- PS：推荐SSH工具【[点击进入下载 MobaXterm](https://mobaxterm.mobatek.net/download.html)】、【[点击进入下载 FinalShell](https://www.hostbuf.com/t/988.html)】；

- PS：升级更新更换好【[点击此处查看 LXC 源](https://github.com/axcsz/Collect/wiki/Proxmox-VE-%E7%B3%BB%E7%BB%9F-%E6%8D%A2%E6%BA%90%E6%95%99%E7%A8%8B)】；


## Debian & Ubuntu 系统 AdGuard Home 安装教程

### 一、使用以下命令，更新

```bash
apt update
apt install snmp snmpd -y
```


### 二、使用以下命令，一键安装

#### 在下面目录，找到下面代码

```bash
nano /etc/snmp/snmpd.conf

agentaddress  127.0.0.1,[::1]
```

#### 修改成

```bash
agentaddress  udp:161,udp6:161
```

#### 重启、查看

```bash
systemctl restart snmpd
systemctl status snmpd
```