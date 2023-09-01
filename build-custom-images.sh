#!/bin/sh
set -eu
PROGNAME=$(basename "$0")
ARCH=$(uname -m)
REPO=
DATE=$(date -u +%Y%m%d)
INCLUDEDIR=$(mktemp -d)
trap "cleanup" INT TERM

cleanup() {
    rm -r "$INCLUDEDIR"
}

if [ ! -x mklive.sh ]; then
    echo mklive.sh not found >&2
    exit 1
fi

if [ -x installer.sh ]; then
    MKLIVE_VERSION="$(PROGNAME='')"
    installer=$(mktemp)
    sed "s/@@MKLIVE_VERSION@@/${MKLIVE_VERSION}/" installer.sh > "$installer"
    install -Dm755 "$installer" "$INCLUDEDIR"/usr/bin/void-installer
    rm "$installer"
else
    echo installer.sh not found >&2
    exit 1
fi
xbps-install -Syu xbps
xbps-install -Syu
xbps-install -y qemu-user-static liblz4
IMG=void-live-${ARCH}-${DATE}-openbox.iso
PKGS="pipewire alsa-pipewire dialog cryptsetup lvm2 mdadm void-docs-browse xtools-minimal xmirror grub-i386-efi grub-x86_64-efi xterm xclock menumaker micro exa neofetch xorg xorg-input-drivers xorg-video-drivers setxkbmap xauth font-misc-misc terminus-font dejavu-fonts-ttf budgie-desktop budgie-screensaver polkit-gnome lightdm octoxbps xbps alacritty neofetch lightdm-gtk-greeter"
SERVICES="sshd acpid dhcpcd wpa_supplicant lightdm dbus polkitd"
LIGHTDM_SESSION='budgie-desktop'
mkdir -p "$INCLUDEDIR"/etc/lightdm
echo "$LIGHTDM_SESSION" > "$INCLUDEDIR"/etc/lightdm/.session
mkdir -p "$INCLUDEDIR"/etc/xdg/autostart
ln -s /usr/share/applications/pipewire.desktop "$INCLUDEDIR"/etc/xdg/autostart/
mkdir -p "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d
ln -s /usr/share/examples/wireplumber/10-wireplumber.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
mkdir -p "$INCLUDEDIR"/etc/alsa/conf.d
ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf "$INCLUDEDIR"/etc/alsa/conf.d
ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf "$INCLUDEDIR"/etc/alsa/conf.d

./mklive.sh -a "$ARCH" -o "$IMG" -p "$PKGS" -S "$SERVICES" -I "$INCLUDEDIR"
