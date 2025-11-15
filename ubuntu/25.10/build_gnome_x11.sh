#!/bin/bash

# GNOME X11 Build Script for Ubuntu 25.10 - Corrected Version
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

BUILD_DIR="$HOME/gnome-x11-build"
PKG_BUILD_DIR="$BUILD_DIR/pkgbuild"
LOG_DIR="$BUILD_DIR/logs"
mkdir -p "$BUILD_DIR" "$PKG_BUILD_DIR" "$LOG_DIR"

install_dependencies() {
    print_status "Installing build dependencies..."
    sudo apt update
    sudo apt install -y \
        build-essential meson ninja-build pkg-config gettext \
        libgirepository1.0-dev libglib2.0-dev libgtk-4-dev \
        libgraphene-1.0-dev libjson-glib-dev libpango1.0-dev \
        libcairo2-dev libx11-dev libxext-dev libxi-dev libxtst-dev \
        libxfixes-dev libxcomposite-dev libxdamage-dev libxrandr-dev \
        libxinerama-dev libxcursor-dev libxkbcommon-dev libxkbcommon-x11-dev \
        libinput-dev libsystemd-dev libgudev-1.0-dev libpipewire-0.3-dev \
        libpulse-dev libcanberra-dev gobject-introspection libdrm-dev \
        libgbm-dev libegl-dev libgles2 libwayland-dev wayland-protocols \
        xwayland git wget curl
}

build_mutter() {
    print_status "Building mutter with X11 support..."
    
    cd "$PKG_BUILD_DIR"
    if [ ! -d "mutter" ]; then
        git clone https://gitlab.gnome.org/GNOME/mutter.git
    fi
    
    cd mutter
    git checkout main 2>/dev/null || git checkout gnome-49 2>/dev/null || true
    git pull
    
    rm -rf build
    mkdir build
    cd build
    
    # CORRECTED: Use proper meson option values
    meson setup \
        --prefix=/usr \
        --buildtype=release \
        -Ddocs=false \
        -Dtests=false \
        -Dxwayland=enabled \
        -Dwayland=enabled \
        -Dsystemd=enabled \
        -Dnative_backend=enabled \
        -Dlibinput=enabled \
        -Dx11_egl_stream=enabled \
        -Dx11=enabled \
        .. 2>&1 | tee "$LOG_DIR/mutter_configure.log"
    
    ninja 2>&1 | tee "$LOG_DIR/mutter_build.log"
    sudo ninja install 2>&1 | tee "$LOG_DIR/mutter_install.log"
    
    print_status "mutter built successfully"
}

build_gdm() {
    print_status "Building GDM with X11 support..."
    
    cd "$PKG_BUILD_DIR"
    if [ ! -d "gdm" ]; then
        git clone https://gitlab.gnome.org/GNOME/gdm.git
    fi
    
    cd gdm
    git checkout main 2>/dev/null || git checkout gnome-49 2>/dev/null || true
    git pull
    
    rm -rf build
    mkdir build
    cd build
    
    # CORRECTED: Use x11-support instead of x11
    meson setup \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault-pam-config=arch \
        -Dgdm-xsession=true \
        -Dipv6=true \
        -Dplymouth=disabled \
        -Dselinux=disabled \
        -Dsystemd-journal=true \
        -Dwayland=enabled \
        -Dx11-support=enabled \
        .. 2>&1 | tee "$LOG_DIR/gdm_configure.log"
    
    ninja 2>&1 | tee "$LOG_DIR/gdm_build.log"
    sudo ninja install 2>&1 | tee "$LOG_DIR/gdm_install.log"
    
    print_status "GDM built successfully"
}

build_gnome_session() {
    print_status "Building gnome-session with X11 support..."
    
    cd "$PKG_BUILD_DIR"
    if [ ! -d "gnome-session" ]; then
        git clone https://gitlab.gnome.org/GNOME/gnome-session.git
    fi
    
    cd gnome-session
    git checkout main 2>/dev/null || git checkout gnome-49 2>/dev/null || true
    git pull
    
    rm -rf build
    mkdir build
    cd build
    
    # CORRECTED: Use proper meson option values
    meson setup \
        --prefix=/usr \
        --buildtype=release \
        -Ddocbook=false \
        -Dman=false \
        -Dsystemd=enabled \
        -Dconsolekit=disabled \
        -Dwayland=enabled \
        -Dx11=enabled \
        .. 2>&1 | tee "$LOG_DIR/gnome_session_configure.log"
    
    ninja 2>&1 | tee "$LOG_DIR/gnome_session_build.log"
    sudo ninja install 2>&1 | tee "$LOG_DIR/gnome_session_install.log"
    
    print_status "gnome-session built successfully"
}

build_gnome_shell() {
    print_status "Building gnome-shell..."
    
    cd "$PKG_BUILD_DIR"
    if [ ! -d "gnome-shell" ]; then
        git clone https://gitlab.gnome.org/GNOME/gnome-shell.git
    fi
    
    cd gnome-shell
    git checkout main 2>/dev/null || git checkout gnome-49 2>/dev/null || true
    git pull
    
    rm -rf build
    mkdir build
    cd build
    
    meson setup \
        --prefix=/usr \
        --buildtype=release \
        -Ddocs=false \
        -Dtests=false \
        -Dman=false \
        -Dsystemd=enabled \
        -Dnetworkmanager=enabled \
        .. 2>&1 | tee "$LOG_DIR/gnome_shell_configure.log"
    
    ninja 2>&1 | tee "$LOG_DIR/gnome_shell_build.log"
    sudo ninja install 2>&1 | tee "$LOG_DIR/gnome_shell_install.log"
    
    print_status "gnome-shell built successfully"
}

configure_system() {
    print_status "Configuring system for X11..."
    
    # Backup original GDM config
    sudo cp /etc/gdm3/custom.conf /etc/gdm3/custom.conf.backup 2>/dev/null || true
    
    # Configure GDM to use X11
    sudo tee /etc/gdm3/custom.conf > /dev/null << 'EOF'
[daemon]
WaylandEnable=false

[security]

[xdmcp]

[chooser]

[debug]
EOF

    # Create X11 session file
    sudo tee /usr/share/xsessions/gnome-x11.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=GNOME on X11
Comment=This session logs you into GNOME with X11
Exec=gnome-session
TryExec=gnome-session
Type=XSession
DesktopNames=GNOME
X-GDM-SessionRegisters=true
EOF

    # Update system databases
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
    sudo update-desktop-database
    sudo gtk-update-icon-cache /usr/share/icons/hicolor
    
    print_status "System configured for X11"
}

main_build() {
    print_status "Starting GNOME X11 build process..."
    
    install_dependencies
    
    # Build components in correct order
    build_mutter
    build_gdm  
    build_gnome_session
    build_gnome_shell
    
    configure_system
    
    print_status "Build completed successfully!"
    print_warning "Please reboot and select 'GNOME on X11' from GDM login screen"
    print_warning "Logs are available in: $LOG_DIR/"
}

# Recovery function
recover_system() {
    print_status "Restoring original system state..."
    
    # Reinstall original packages
    sudo apt update
    sudo apt install --reinstall gnome-shell mutter gdm3 gnome-session -y
    
    # Restore original GDM config
    if [ -f /etc/gdm3/custom.conf.backup ]; then
        sudo mv /etc/gdm3/custom.conf.backup /etc/gdm3/custom.conf
    fi
    
    sudo systemctl restart gdm
    print_status "System recovery completed"
}

# Check current build options
check_options() {
    print_status "Checking current build options..."
    
    cd "$PKG_BUILD_DIR"
    
    for comp in mutter gdm gnome-session; do
        if [ -d "$comp" ]; then
            print_status "=== $comp options ==="
            cd "$comp"
            mkdir -p test-build
            cd test-build
            meson .. --help 2>&1 | grep -E "x11|x11-support" | head -5 || true
            cd ../..
        fi
    done
}

case "${1:-build}" in
    "build")
        main_build
        ;;
    "recover")
        recover_system
        ;;
    "check")
        check_options
        ;;
    "help")
        echo "Usage: $0 [build|recover|check|help]"
        echo "  build   - Build GNOME with X11 support"
        echo "  recover - Restore original system packages"
        echo "  check   - Check available build options"
        ;;
    *)
        main_build
        ;;
esac