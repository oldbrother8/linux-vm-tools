#!/usr/bin/env bash
set -e

sudo add-apt-repository universe -y
sudo add-apt-repository multiverse -y
sudo apt update
sudo apt upgrade -y

# Essential build tools
sudo apt install -y \
  build-essential git meson ninja-build pkg-config autoconf automake libtool gettext cmake cargo ragel yasm bison flex gperf

# GNOME and X11 base libraries
sudo apt install -y \
  libgtk-4-dev libadwaita-1-dev libglib2.0-dev libpango1.0-dev libharfbuzz-dev \
  libx11-dev libxext-dev libxrandr-dev libxi-dev libxtst-dev \
  xserver-xorg-dev xorg-dev libxkbcommon-dev libwayland-dev \
  gobject-introspection gtk-doc-tools valac libsoup-3.0-dev

# Documentation & tools
sudo apt install -y \
  python3-dev python3-pip intltool itstool help2man texinfo asciidoc \
  doxygen graphviz xmlto docbook docbook-xsl docbook-utils

# Core developer libraries
sudo apt install -y \
  libpcre3-dev libxml2-dev libxslt1-dev libtasn1-dev libgcrypt20-dev libgpgme-dev \
  libyaml-dev libunwind-dev check libdb-dev liblmdb-dev libstemmer-dev libelf-dev valgrind \
  llvm-dev libclang-dev ruby ruby-dev

# X11/XCB/input/display
sudo apt install -y \
  libx11-xcb-dev libxkbcommon-x11-dev libstartup-notification0-dev \
  libxcb-dri2-0-dev libxcb-randr0-dev libxcb-res0-dev xvfb \
  libgbm-dev libv4l-dev libexif-dev libevdev-dev libmtdev-dev liblcms2-dev argyll

# Sound & multimedia
sudo apt install -y \
  libopus-dev libflac-dev libtag1-dev libwavpack-dev libasound2-dev libpulse-dev \
  libcanberra-dev libcanberra-gtk3-dev libsndfile1-dev libvorbis-dev libsbc-dev \
  libvpx-dev libavfilter-dev libavformat-dev libavcodec-dev libavutil-dev \
  libopenjp2-7-dev libraw-dev libbluray-dev libdvdread-dev libmusicbrainz5-dev espeak-ng

# System, security, and hardware libraries
sudo apt install -y \
  libdbus-1-dev libdbus-glib-1-dev libpolkit-gobject-1-dev \
  libsystemd-dev libudev-dev libseccomp-dev libpam0g-dev libcap-dev libarchive-dev file \
  libusb-1.0-0-dev libusbredirhost-dev libvirt-dev fuse libsmbclient-dev \
  libimobiledevice-dev libnfs-dev libcdio-paranoia-dev libgphoto2-dev libmtp-dev libsane-dev \
  libgnutls28-dev libp11-kit-dev libnss3-dev libnspr4-dev libcurl4-openssl-dev libproxy-dev \
  libndp-dev libnl-3-dev libnl-genl-3-dev libnl-route-3-dev libbluetooth-dev libavahi-glib-dev \
  libldap2-dev libsasl2-dev libpwquality-dev

# Internationalization & input methods
sudo apt install -y \
  anthy libanthy-dev libhangul-dev libxklavier-dev hyphen-en-us hyphen-en-gb

# Miscellaneous / utilities
sudo apt install -y \
  cups libcups2-dev libgraphviz-dev libdotconf-dev libudisks2-dev libdmapsharing-3.0-dev \
  policykit-1-gnome xserver-xorg-input-wacom ppp readline libreadline-dev smbclient \
  dotconf libplymouth-dev libavahi-gobject-dev cvt x11-xserver-utils \
  libkyotocabinet-dev liboauth-dev libboost-all-dev libexempi-dev
 
sudo apt install \
  libdmapsharing-dev \
  libreadline-dev \
  libdotconf-dev \
  x11-xserver-utils

 
sudo apt install \
  libcups2-dev \
  libgraphviz-dev \
  libcanberra-gtk3-dev \
  libplymouth-dev \
  libhunspell-dev \
  libavahi-gobject-dev \
  ppp \
  hyphen-en-us \
  policykit-1-gnome \
  libreadline-dev \
  xserver-xorg-input-wacom \
  file \
  libclang-dev \
  x11-xserver-utils \
  libudisks2-dev \
  libdotconf-dev \
  espeak-ng \
  libgpgme-dev \
  libdmapsharing-dev

# Set up jhbuild
sudo apt install -y jhbuild

jhbuild sysdeps --install