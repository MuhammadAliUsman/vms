#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

WORKDIR=/root/os-installer
mkdir -p $WORKDIR

install_deps() {
  apt update
  apt install -y wget qemu-utils libvirt-daemon-system libvirt-clients virtinst bridge-utils cloud-image-utils
}

clear
echo "========================================"
echo "   Universal OS & KVM VPS Installer"
echo "========================================"
echo "1) Reinstall MAIN VPS (Disk Wipe)"
echo "2) Create KVM VPS (Virtual Machine)"
echo "3) Exit"
echo "========================================"
read -p "Select option: " MAIN

########################################
# MAIN VPS REINSTALL
########################################
if [ "$MAIN" = "1" ]; then
  clear
  echo "---- VPS Reinstall ----"
  echo "1) Ubuntu 22.04"
  echo "2) Ubuntu 24.04"
  echo "3) Debian 11"
  echo "4) Debian 12"
  read -p "Select OS: " OS

  case $OS in
    1) URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"; TYPE=img ;;
    2) URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"; TYPE=img ;;
    3) URL="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"; TYPE=qcow2 ;;
    4) URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"; TYPE=qcow2 ;;
    *) exit 1 ;;
  esac

  lsblk
  read -p "Target disk (example /dev/vda): " DISK
  read -p "Type YES to WIPE DISK: " CONFIRM
  [ "$CONFIRM" != "YES" ] && exit 0

  install_deps
  cd $WORKDIR
  wget -O os.img $URL

  if [ "$TYPE" = "qcow2" ]; then
    qemu-img convert -O raw os.img os.raw
    IMAGE=os.raw
  else
    IMAGE=os.img
  fi

  dd if=$IMAGE of=$DISK bs=4M status=progress conv=fsync
  sync
  echo "✅ VPS Installed. Reboot now."
  exit 0
fi

########################################
# KVM VPS CREATOR
########################################
if [ "$MAIN" = "2" ]; then
  clear
  echo "---- KVM VPS Creator ----"
  echo "1) Ubuntu 22.04"
  echo "2) Ubuntu 24.04"
  echo "3) Debian 11"
  echo "4) Debian 12"
  read -p "Select OS: " OS

  case $OS in
    1) NAME=ubuntu22; URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" ;;
    2) NAME=ubuntu24; URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img" ;;
    3) NAME=debian11; URL="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2" ;;
    4) NAME=debian12; URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2" ;;
    *) exit 1 ;;
  esac

  read -p "VM Name: " VMNAME
  read -p "RAM (MB): " RAM
  read -p "CPU Cores: " CPU
  read -p "Disk Size (GB): " DISKGB

  install_deps
  cd $WORKDIR

  BASE_IMAGE=$NAME-base.qcow2
  VM_DISK=/var/lib/libvirt/images/$VMNAME.qcow2

  [ ! -f $BASE_IMAGE ] && wget -O $BASE_IMAGE $URL

  qemu-img create -f qcow2 -b $BASE_IMAGE $VM_DISK ${DISKGB}G

  virt-install \
    --name $VMNAME \
    --ram $RAM \
    --vcpus $CPU \
    --disk path=$VM_DISK,format=qcow2 \
    --os-variant detect=on \
    --import \
    --network network=default \
    --noautoconsole

  echo "========================================"
  echo "🎉 VPS Created Successfully!"
  echo "VM Name: $VMNAME"
  echo "Manage with: virsh list --all"
  echo "========================================"
  exit 0
fi
