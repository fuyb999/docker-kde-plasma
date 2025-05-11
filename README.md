[![Docker Build](https://github.com/ai-dock/linux-desktop/actions/workflows/docker-build.yml/badge.svg)](https://github.com/ai-dock/linux-desktop/actions/workflows/docker-build.yml)

# Linux Desktop

Run a hardware accelerated KDE desktop in a container. This image is heavily influenced by [Selkies Project](https://github.com/selkies-project) to provide an accelerated desktop environment for NVIDIA, AMD and Intel machines.  

Please see this [important notice](#selkies-notice) from the Selkies development team.


## Documentation

All AI-Dock containers share a common base which is designed to make running on cloud services such as [vast.ai](https://link.ai-dock.org/vast.ai) as straightforward and user friendly as possible.

Common features and options are documented in the [base wiki](https://github.com/ai-dock/base-image/wiki) but any additional features unique to this image will be detailed below.


#### Version Tags

The `:latest` tag points to `:latest-cuda`

Tags follow these patterns:

##### _CUDA_
- `:cuda-[x.x.x]{-cudnn[x]}-[base|runtime|devel]-[ubuntu-version]`

- `:latest-cuda` &rarr; `:cuda-12.1.1-cudnn8-runtime-22.04`

##### _ROCm_
- `:rocm-[x.x.x]-[core|runtime|devel]-[ubuntu-version]`

- `:latest-rocm` &rarr; `:rocm-6.0-runtime-22.04`

ROCm builds are experimental. Please give feedback.

##### _CPU (iGPU)_
- `:cpu-[ubuntu-version]`

- `:latest-cpu` &rarr; `:cpu-22.04`

Browse [here](https://github.com/ai-dock/linux-desktop/pkgs/container/linux-desktop) for an image suitable for your target environment. 

Supported Desktop Environments: `KDE Plasma`

Supported Platforms: `NVIDIA CUDA`, `AMD ROCm`, `CPU/iGPU`


## Pre-Configured Templates

**Vast.​ai**

[linux-desktop:latest](https://link.ai-dock.org/template-vast-linux-desktop)


---

## Selkies Notice

This project has been developed and is supported in part by the National Research Platform (NRP) and the Cognitive Hardware and Software Ecosystem Community Infrastructure (CHASE-CI) at the University of California, San Diego, by funding from the National Science Foundation (NSF), with awards #1730158, #1540112, #1541349, #1826967, #2138811, #2112167, #2100237, and #2120019, as well as additional funding from community partners, infrastructure utilization from the Open Science Grid Consortium, supported by the National Science Foundation (NSF) awards #1836650 and #2030508, and infrastructure utilization from the Chameleon testbed, supported by the National Science Foundation (NSF) awards #1419152, #1743354, and #2027170. This project has also been funded by the Seok-San Yonsei Medical Scientist Training Program (MSTP) Song Yong-Sang Scholarship, College of Medicine, Yonsei University, the MD-PhD/Medical Scientist Training Program (MSTP) through the Korea Health Industry Development Institute (KHIDI), funded by the Ministry of Health & Welfare, Republic of Korea, and the Student Research Bursary of Song-dang Institute for Cancer Research, College of Medicine, Yonsei University.

---

_The author ([@robballantyne](https://github.com/robballantyne)) may be compensated if you sign up to services linked in this document. Testing multiple variants of GPU images in many different environments is both costly and time-consuming; This helps to offset costs_

### coturn
```shell
sudo docker run --name coturn --restart=always -d -p 3478:3478 -p 3478:3478/udp -p 65500-65535:65500-65535 \
    -p 65500-65535:65500-65535/udp ghcr.nju.edu.cn/coturn/coturn -n --listening-ip="0.0.0.0" --listening-ip="::" \
    --external-ip="192.168.75.16" --min-port=65500 --max-port=65535 --lt-cred-mech --user=n0TaRealCoTURNAuthSecret:ThatIsSixtyFourLengthsLongPlaceholdPlace

```

### moonlight undefined symbol: SDL_GetTouchName
```shell
wget https://www.libsdl.org/release/SDL2-2.0.22.tar.gz
./configure --prefix=/usr/     --enable-video-x11     --enable-alsa     --enable-pulseaudio     --enable-input-libinput     --enable-h264     --enable-hevc     --enable-network     --enable-openssl
make -j$(nproc)
sudo make install
sudo mv build/.libs/libSDL2-2.0.so.0.22.0 /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0
```


### make ubuntu2204 server iso 

```shell
sudo apt install squashfs-tools genisoimage isolinux xorriso overlayroot linux-modules-extra-$(uname -r)
mkdir ~/iso

# if in docker, need privileged: true
sudo mount -o loop ubuntu-22.04.4-live-server-amd64.iso ~/iso
mkdir ~/livecd
cp -rT ~/iso ~/livecd

# 解压文件系统 (第二次做的时候，可以忽略这一步)
sudo unsquashfs -d ~/squashfs ~/livecd/casper/ubuntu-server-minimal.squashfs

# chroot到解压后的文件系统
sudo chroot ~/squashfs

# install pkg
sudo apt-get install -y bash curl gpg lsb-core software-properties-common && \
    # nvidia-container-toolkit
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
    # docker-ce
    curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | apt-key add - &&  \
    add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable" && \
    # install apt-offline
    curl -fSsL https://github.com/rickysarraf/apt-offline/releases/download/v1.8.5/apt-offline-1.8.5.tar.gz -o - | tar --strip-components=1 -zx -C /usr/bin && \
    
sudo apt-get install -y bash git curl wget jq tar bzip2 zip unzip xz-utils rar unrar p7zip-full vim openssh-server net-tools build-essential g++ gcc make cmake libglvnd-dev pkg-config language-pack-zh-hans language-pack-zh-hans-base nvidia-container-toolkit docker-ce openresolv telnet openssl socat libseccomp-dev ipvsadm bind9 bind9utils bind9-doc dnsutils

curl -L "https://github.com/docker/compose/releases/download/v2.36.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose

# 退出chroot环境
exit

# 重新创建文件系统
sudo rm ~/livecd/casper/ubuntu-server-minimal.squashfs
sudo mksquashfs ~/squashfs ~/livecd/casper/ubuntu-server-minimal.squashfs

# 更新文件的MD5值
sudo rm ~/livecd/md5sum.txt
sudo sh -c "cd ~/livecd && find . -type f -print0 | xargs -0 md5sum > md5sum.txt"

# 创建新的ISO

```

创建新的ISO

查看iso信息
```shell
xorriso -indev ubuntu-22.04.4-live-server-amd64.iso -report_el_torito as_mkisofs
```
输出
```text
xorriso 1.5.4 : RockRidge filesystem manipulator, libburnia project.

xorriso : NOTE : Loading ISO image tree from LBA 0
xorriso : UPDATE :     820 nodes read in 1 seconds
libisofs: NOTE : Found hidden El-Torito image for EFI.
libisofs: NOTE : EFI image start and size: 1024860 * 2048 , 10068 * 512
xorriso : NOTE : Detected El-Torito boot information which currently is set to be discarded
Drive current: -indev 'ubuntu-22.04.4-live-server-amd64.iso'
Media current: stdio file, overwriteable
Media status : is written , is appendable
Boot record  : El Torito , MBR protective-msdos-label grub2-mbr cyl-align-off GPT
Media summary: 1 session, 1027543 data blocks, 2007m data, 57.6g free
Volume id    : 'Ubuntu-Server 22.04.4 LTS amd64'
-V 'Ubuntu-Server 22.04.4 LTS amd64'
--modification-date='2024021623523000'
--grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:'ubuntu-22.04.4-live-server-amd64.iso'
--protective-msdos-label
-partition_cyl_align off
-partition_offset 16
--mbr-force-bootable
-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:4099440d-4109507d::'ubuntu-22.04.4-live-server-amd64.iso'
-appended_part_as_gpt
-iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7
-c '/boot.catalog'
-b '/boot/grub/i386-pc/eltorito.img'
-no-emul-boot
-boot-load-size 4
-boot-info-table
--grub2-boot-info
-eltorito-alt-boot
-e '--interval:appended_partition_2_start_1024860s_size_10068d:all::'
-no-emul-boot
-boot-load-size 10068
```

提取引导
```shell
# mbr引导
dd if=ubuntu-22.04.4-live-server-amd64.iso bs=1 count=432 of=/tmp/boot_hybrid.img

# efi引导，计算 skip=--interval:local_fs:4099440d-4109507d   count=-boot-load-size
dd if=ubuntu-22.04.4-live-server-amd64.iso bs=512 skip=4109507 count=10068 of=/tmp/efi.img
```

制作
```shell
sudo xorriso -as mkisofs -r \
-V 'Ubuntu-22.04.4-live-server-by-fuyb' \
-o ubuntu-22.04.4-live-server-by-fuyb.iso \
--grub2-mbr /tmp/boot_hybrid.img \
-partition_offset 16 \
--mbr-force-bootable \
-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b /tmp/efi.img \
-appended_part_as_gpt \
-iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
-c '/boot.catalog' \
-b '/boot/grub/i386-pc/eltorito.img' \
-no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
-eltorito-alt-boot \
-e '--interval:appended_partition_2:::' \
-no-emul-boot \
~/livecd
```
