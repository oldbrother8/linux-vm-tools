#!/bin/bash

# This script prepares Ubuntu for XRDP enhanced session by configuring X11 and XRDP.
# It ensures X11 is the default and installs necessary components for XRDP compatibility.

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# Update and upgrade system packages
apt update && apt upgrade -y

# Check if reboot is required
if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

# Ensure X.Org is installed and configured as the default
# 'xserver-xorg' is the core X server package.
# 'gnome-session-xorg' provides the session option for GDM.
# 'ubuntu-desktop' ensures the full desktop environment with Xorg support.
apt install -y xserver-xorg gnome-session-xorg ubuntu-desktop

# Disable Wayland in GDM configuration
if grep -q "^#WaylandEnable=false" /etc/gdm3/custom.conf; then
    sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
elif ! grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf; then
    sed -i '/\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf
fi

# Install hv_kvp utils (Hyper-V KVP utilities)
HWE="" # Set to "-hwe-22.04" for specific HWE kernel, otherwise leave empty for generic
apt install -y linux-tools-virtual${HWE} linux-cloud-tools-virtual${HWE}

# Install and configure XRDP service
apt install -y xrdp

systemctl stop xrdp
systemctl stop xrdp-sesman

# Configure XRDP ini files
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# Create and configure startubuntu.sh for XRDP sessions
if [ ! -e /etc/xrdp/startubuntu.sh ]; then
cat << EOF > /etc/xrdp/startubuntu.sh
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
exec /etc/xrdp/startwm.sh
EOF
chmod a+x /etc/xrdp/startubuntu.sh
fi

# Use the startubuntu.sh script in sesman.ini
sed -i_orig -e 's/startwm/startubuntu/g' /etc/xrdp/sesman.ini

# Rename redirected drives
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Configure Xwrapper.config for allowed_users
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Blacklist vmw_vsock_vmci_transport module
if [ ! -e /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf ]; then
  echo "blacklist vmw_vsock_vmci_transport" > /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf
fi

# Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
  echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Configure polkit policy for Colord
mkdir -p /etc/polkit-1/localauthority/50-local.d/
cat << EOF > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# Reload systemd daemon and start XRDP
systemctl daemon-reload
systemctl start xrdp

echo "XRDP and X11 configuration complete."
echo "Please reboot your machine to apply all changes and begin using XRDP enhanced session."