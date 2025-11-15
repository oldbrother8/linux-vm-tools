#!/bin/bash

# GNOME X11 Build Script for Ubuntu 25.10
# This script builds GNOME components with X11 session support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    exit 1
fi

# Configuration
BUILD_DIR="$HOME/gnome-x11-build"
PKG_BUILD_DIR="$BUILD_DIR/pkgbuild"
LOG_DIR="$BUILD_DIR/logs"
BACKUP_DIR="$BUILD_DIR/backups"

# Create directories
mkdir -p "$BUILD_DIR" "$PKG_BUILD_DIR" "$LOG_DIR" "$BACKUP_DIR"

# Install build dependencies
install_dependencies() {
    print_status "Installing build dependencies..."
    
    sudo apt update
    sudo apt install -y \
        build-essential \
        meson \
        ninja-build \
        pkg-config \
        gettext \
        libgirepository1.0-dev \
        libglib2.0-dev \
        libgtk-4-dev \
        libgraphene-1.0-dev \
        libjson-glib-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libx11-dev \
        libxext-dev \
        libxi-dev \
        libxtst-dev \
        libxfixes-dev \
        libxcomposite-dev \
        libxdamage-dev \
        libxrandr-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxkbcommon-dev \
        libxkbcommon-x11-dev \
        libinput-dev \
        libsystemd-dev \
        libgudev-1.0-dev \
        libpipewire-0.3-dev \
        libpulse-dev \
        libcanberra-dev \
        gobject-introspection \
        libdrm-dev \
        libgbm-dev \
        libegl-dev \
        libgles2 \
        libwayland-dev \
        wayland-protocols \
        xwayland \
        git \
        wget \
        curl \
        devscripts \
        debhelper \
        dh-autoreconf \
        apt-src \
        gnome-software-dev \
        libgnome-desktop-4-dev \
        libgnome-bluetooth-3.0-dev \
        libpolkit-gobject-1-dev \
        libupower-glib-dev \
        libsecret-1-dev \
        libsoup-3.0-dev \
        libgcr-4-dev \
        libnma-dev \
        libadwaita-1-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev
    
    print_status "Dependencies installed successfully"
}

# Backup original packages
backup_packages() {
    print_status "Backing up original packages..."
    
    local packages=("gnome-shell" "mutter" "gdm3" "gnome-session")
    
    for pkg in "${packages[@]}"; do
        if dpkg -l | grep -q "ii  $pkg "; then
            dpkg -l "$pkg" > "$BACKUP_DIR/${pkg}_version.txt"
            print_status "Backed up $pkg version info"
        fi
    done
    
    # Backup current package states
    dpkg --get-selections | grep -E "(gnome-shell|mutter|gdm3|gnome-session)" > "$BACKUP_DIR/package_selections.txt"
}

# Clone and build mutter
build_mutter() {
    print_status "Building mutter with X11 support..."
    
    cd "$PKG_BUILD_DIR"
    
    if [ ! -d "mutter" ]; then
        git clone https://gitlab.gnome.org/GNOME/mutter.git
    fi
    
    cd mutter
    
    # Use GNOME 49 branch for better compatibility
    git checkout main
    git pull
    
    # Check available branches and use a stable one if main fails
    if ! git checkout main 2>/dev/null; then
        print_warning "main branch not available, trying gnome-49"
        git checkout gnome-49
    fi
    
    # Create build directory
    rm -rf build
    mkdir build
    cd build
    
    # Configure with X11 support - using correct meson option values
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
        -Dx11=enabled \
        ..
    
    # Build and install
    ninja 2>&1 | tee "$LOG_DIR/mutter_build.log"
    sudo ninja install 2>&1 | tee "$LOG_DIR/mutter_install.log"
    
    print_status "mutter built and installed successfully"
}

# Clone and build gdm
build_gdm() {
    print_status "Building GDM with X11 support..."
    
    cd "$PKG_BUILD_DIR"
    
    if [ ! -d "gdm" ]; then
        git clone https://gitlab.gnome.org/GNOME/gdm.git
    fi
    
    cd gdm
    
    # Use compatible branch
    git checkout main
    git pull
    
    # Check available branches
    if ! git checkout main 2>/dev/null; then
        print_warning "main branch not available, trying gnome-49"
        git checkout gnome-49
    fi
    
    # Create build directory
    rm -rf build
    mkdir build
    cd build
    
    # Configure with X11 support - using correct meson option values
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
        -Dx11=enabled \
        ..
    
    # Build and install
    ninja 2>&1 | tee "$LOG_DIR/gdm_build.log"
    sudo ninja install 2>&1 | tee "$LOG_DIR/gdm_install.log"
    
    print_status "GDM built and installed successfully"
}

# Clone and build gnome-session
build_gnome_session() {
    print_status "Building gnome-session with X11 support..."
    
    cd "$PKG_BUILD_DIR"
    
    if [ ! -d "gnome-session" ]; then
        git clone https://gitlab.gnome.org/GNOME/gnome-session.git
    fi
    
    cd gnome-session
    
    # Use compatible branch
    git checkout main
    git pull
    
    # Check available branches
    if ! git checkout main 2>/dev/null; then
        print_warning "main branch not available, trying gnome-49"
        git checkout gnome-49
    fi
    
    # Create build directory
    rm -rf build
    mkdir build
    cd build
    
    # Configure with X11 support - using correct meson option values
    meson setup \
        --prefix=/usr \
        --buildtype=release \
        -Ddocbook=false \
        -Dman=false \
        -Dsystemd=enabled \
        -Dconsolekit=disabled \
        -Dwayland=enabled \
        -Dx11=enabled \
        ..
    
    # Build and install
    ninja 2>&1 | tee "$LOG_DIR/gnome_session_build.log"
    sudo ninja install 2>&1 | tee "$LOG_DIR/gnome_session_install.log"
    
    print_status "gnome-session built and installed successfully"
}

# Clone and build gnome-shell
build_gnome_shell() {
    print_status "Building gnome-shell with X11 support..."
    
    cd "$PKG_BUILD_DIR"
    
    if [ ! -d "gnome-shell" ]; then
        git clone https://gitlab.gnome.org/GNOME/gnome-shell.git
    fi
    
    cd gnome-shell
    
    # Use compatible branch
    git checkout main
    git pull
    
    # Check available branches
    if ! git checkout main 2>/dev/null; then
        print_warning "main branch not available, trying gnome-49"
        git checkout gnome-49
    fi
    
    # Create build directory
    rm -rf build
    mkdir build
    cd build
    
    # Configure - gnome-shell doesn't have direct X11 options
    meson setup \
        --prefix=/usr \
        --buildtype=release \
        -Ddocs=false \
        -Dtests=false \
        -Dman=false \
        -Dsystemd=enabled \
        -Dnetworkmanager=enabled \
        ..
    
    # Build and install
    ninja 2>&1 | tee "$LOG_DIR/gnome_shell_build.log"
    sudo ninja install 2>&1 | tee "$LOG_DIR/gnome_shell_install.log"
    
    print_status "gnome-shell built and installed successfully"
}

# Check available meson options for a component
check_meson_options() {
    local component="$1"
    local path="$2"
    
    print_status "Checking available meson options for $component..."
    
    cd "$path"
    
    if [ -d "build" ]; then
        rm -rf build
    fi
    
    mkdir build
    cd build
    
    # This will show available options and their possible values
    meson setup --help 2>&1 | grep -A 20 "Project-specific options" || true
    
    # Try to configure to see actual available options
    meson setup .. 2>&1 | grep -E "(Option|Value|Possible)" || true
}

# Update system databases
update_system() {
    print_status "Updating system databases..."
    
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
    sudo update-desktop-database
    sudo gtk-update-icon-cache /usr/share/icons/hicolor
    
    print_status "System databases updated"
}

# Configure GDM for X11
configure_gdm() {
    print_status "Configuring GDM for X11 session..."
    
    # Backup original GDM config
    sudo cp /etc/gdm3/custom.conf /etc/gdm3/custom.conf.backup 2>/dev/null || true
    
    # Create GDM custom configuration
    sudo tee /etc/gdm3/custom.conf > /dev/null << 'EOF'
# GDM configuration storage
[daemon]
# Uncomment the line below to force the login screen to use Xorg
WaylandEnable=false

[security]

[xdmcp]

[chooser]

[debug]
# Uncomment the line below to turn on debugging
#Enable=true
EOF

    print_status "GDM configured for X11"
}

# Create session file for X11
create_x11_session() {
    print_status "Creating X11 session file..."
    
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

    print_status "X11 session file created"
}

# Verify build components
verify_build() {
    print_status "Verifying built components..."
    
    local components=("mutter" "gdm" "gnome-session" "gnome-shell")
    local success=true
    
    for comp in "${components[@]}"; do
        if [ -f "$LOG_DIR/${comp}_install.log" ] && grep -q "Installation succeeded" "$LOG_DIR/${comp}_install.log"; then
            print_status "✓ $comp installed successfully"
        else
            print_error "✗ $comp installation may have failed"
            success=false
        fi
    done
    
    if $success; then
        print_status "All components verified successfully"
    else
        print_warning "Some components may not have installed correctly. Check logs in $LOG_DIR/"
    fi
}

# Main build function
main_build() {
    print_status "Starting GNOME X11 build process..."
    
    # Install dependencies
    install_dependencies
    
    # Backup original packages
    backup_packages
    
    # Build components in correct order
    build_mutter
    build_gdm
    build_gnome_session
    build_gnome_shell
    
    # Update system
    update_system
    
    # Configure system
    configure_gdm
    create_x11_session
    
    # Verify build
    verify_build
    
    print_status "GNOME X11 build completed successfully!"
    print_warning "Please reboot your system to use GNOME with X11"
    print_warning "Select 'GNOME on X11' from the GDM login screen"
    print_warning "Build logs are available in: $LOG_DIR/"
}

# Recovery function
recover_system() {
    print_status "Attempting system recovery..."
    
    if [ -f "$BACKUP_DIR/package_selections.txt" ]; then
        print_status "Restoring original packages..."
        sudo apt update
        sudo dpkg --set-selections < "$BACKUP_DIR/package_selections.txt"
        sudo apt-get dselect-upgrade -y
    else
        print_warning "No backup found, reinstalling GNOME..."
        sudo apt install --reinstall gnome-shell mutter gdm3 gnome-session -y
    fi
    
    # Restore original GDM config
    if [ -f /etc/gdm3/custom.conf.backup ]; then
        sudo mv /etc/gdm3/custom.conf.backup /etc/gdm3/custom.conf
    fi
    
    sudo systemctl restart gdm
    print_status "Recovery completed. Please check if normal login works."
}

# Check meson options for troubleshooting
check_options() {
    print_status "Checking meson options for all components..."
    
    cd "$PKG_BUILD_DIR"
    
    for comp in mutter gdm gnome-session gnome-shell; do
        if [ -d "$comp" ]; then
            check_meson_options "$comp" "$comp"
        else
            print_warning "$comp not cloned yet, skipping option check"
        fi
    done
}

# Show usage
usage() {
    echo "GNOME X11 Build Script for Ubuntu 25.10"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  build     - Build and install GNOME with X11 support (default)"
    echo "  recover   - Restore original system state"
    echo "  clean     - Clean build directories"
    echo "  options   - Check available meson options for troubleshooting"
    echo "  help      - Show this help message"
    echo ""
    echo "Build directory: $BUILD_DIR"
    echo "Logs directory: $LOG_DIR"
}

# Clean build directories
clean_build() {
    print_status "Cleaning build directories..."
    rm -rf "$PKG_BUILD_DIR"
    print_status "Build directories cleaned"
}

# Main script logic
case "${1:-build}" in
    "build")
        main_build
        ;;
    "recover")
        recover_system
        ;;
    "clean")
        clean_build
        ;;
    "options")
        check_options
        ;;
    "help"|"-h"|"--help")
        usage
        ;;
    *)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
esac