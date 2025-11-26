
#!/bin/bash

#
# Ubuntu 25.10  
# Enable hyper-v linux hvsocket
# by installing linux-tools-virtual, xfce, and xrdp
# 
# Gnome 49+ is not compatible with hvsocket (uses xrdp) because of wayland
# But gnome is still accessible on the non-hvsocket virtual console 
#
# Make sure to run this on the host:

# powershell -c "Set-VM -Name 'UbuntuVMName' -EnhancedSessionTransportType HvSocket"
# PowerShell: Set-VM -VMName "Ubutun25" -EnhancedSessionTransportType HvSocket

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

apt update && apt upgrade -y

if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

apt install -y linux-tools-virtual linux-cloud-tools-virtual xrdp

systemctl stop xrdp
systemctl stop xrdp-sesman

#hyper-v xrdp setup
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

create_config_file() { 
  [ ! -e "$1" ] && echo "$2" > "$1"; 
}
create_config_file "/etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf" "blacklist vmw_vsock_vmci_transport"
create_config_file "/etc/modprobe.d/blacklist-simpledrm.conf" "blacklist simpledrm"
create_config_file "/etc/modules-load.d/hv_sock.conf" "hv_sock"

mkdir -p /etc/polkit-1/localauthority/50-local.d/
cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

#xfce setup 

systemctl daemon-reload
systemctl start xrdp

echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
