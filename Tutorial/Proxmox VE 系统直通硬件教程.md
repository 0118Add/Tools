# Proxmox VE 直通硬件教程

- PS：打开PVE节点的shell操作

- PS：推荐SSH工具【[点击进入下载 MobaXterm](https://mobaxterm.mobatek.net/download.html)】、【[点击进入下载 FinalShell](https://www.hostbuf.com/t/988.html)】

## 一、开启硬件直通

### 1、启动内核IOMMU支持

#### 1.1、使用以下命令

```bash
nano /etc/default/grub
```

#### 1.2、找到下面内容

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
```

#### 1.3、Intel CPU 修改成下面类容、编辑完文件后按 Ctrl + X  再按 Y 保存、按回车建，继续输入以下命令。

```bash
PVE 8.X
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
PVE 7.X
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on video=efifb:off,vesafb:off pcie_acs_override=downstream,multifunction"
```

#### 1.4、AMD CPU 修改成下面类容、编辑完文件后按 Ctrl + X  再按 Y 保存、按回车建，继续输入以下命令。

```bash
PVE 8.X
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on"
PVE 7.X
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on video=efifb:off,vesafb:off pcie_acs_override=downstream,multifunction"
```

### 2、加载硬件直通相关模块

#### 2.1、使用以下命令，（PVE 7.X 需要）

```bash
nano /etc/modules
```

#### 2.2、拷贝下面内全部类容，粘贴进去，编辑完文件后按 Ctrl + X  再按 Y 保存、按回车建，继续输入以下命令。

```bash
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
coretemp
it87 
```

### 3、添加设备黑名单 HDMI 输出（不需要的可以不设置）

#### 3.1、使用以下命令

```bash
nano /etc/modprobe.d/pve-blacklist.conf
```

#### 3.2、拷贝下面内全部类容，粘贴进去，编辑完文件后按 Ctrl + X  再按 Y 保存、按回车建，继续输入以下命令。

```bash
blacklist i915
blacklist snd_hda_intel
```

### 4、更新配置信息并重启PVE主机

- PS：一行一行复制

```bash
update-grub
update-initramfs -u -k all
reboot
```

### 5、更新命令

```bash
apt update && apt dist-upgrade -y
```

## 二、上传local-ISO镜像方式安装IMG系统代码

- PS：在PVE的shell操作， “100” 修改成你的实际ID数字，“替换文件名” 修改成你实际的文件名称

```bash
qm importdisk 100 /var/lib/vz/template/iso/替换文件名.img local-lvm
```
