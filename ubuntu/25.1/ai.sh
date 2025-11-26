#!/bin/bash

# XRDP Setup Script for Ubuntu 25.10 ARM64 on Hyper-V
# Enables Enhanced Session Mode with XFCE fallback

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script with sudo or as root."
  exit 1
fi

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing XRDP and XFCE..."
apt install -y xrdp xorgxrdp xfce4 xfce4-goodies

echo "Disabling Wayland (required for XRDP)..."
sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
echo "Wayland disabled."

echo "Configuring XRDP to use XFCE..."
echo "startxfce4" > /etc/skel/.xsession
cp /etc/skel/.xsession /home/$SUDO_USER/
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.xsession

echo "Adding user to ssl-cert group..."
adduser $SUDO_USER ssl-cert

echo "Enabling XRDP service..."
systemctl enable xrdp --now

echo "Checking for HvSocket module..."
if ! lsmod | grep -q hv_sock; then
  echo "Loading hv_sock module..."
  echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
  modprobe hv_sock
fi

echo "Setup complete. Please reboot your VM and connect using Enhanced Session Mode."
