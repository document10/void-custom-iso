#!/bin/sh
xbps-install -Syu
xbps-install -y qemu-user-static liblz4
set -eu
. ./lib.sh
PROGNAME=$(basename "$0")
ARCH=$(uname -m)
IMAGES="base enlightenment xfce mate cinnamon gnome kde lxde lxqt"
TRIPLET=
REPO=
DATE=$(date -u +%Y%m%d)

help() {
    echo "$PROGNAME: [-a arch] [-b base|enlightenment|xfce|mate|cinnamon|gnome|kde|lxde|lxqt] [-d date] [-t arch-date-variant] [-r repo]" >&2
}

while getopts "a:b:d:t:hr:V" opt; do
case $opt in
    a) ARCH="$OPTARG";;
    b) IMAGES="$OPTARG";;
    d) DATE="$OPTARG";;
    h) help; exit 0;;
    r) REPO="-r $OPTARG $REPO";;
    t) TRIPLET="$OPTARG";;
    V) version; exit 0;;
    *) help; exit 1;;
esac
done
shift $((OPTIND - 1))

INCLUDEDIR=$(mktemp -d)
trap "cleanup" INT TERM

cleanup() {
    rm -r "$INCLUDEDIR"
}

setup_pipewire() {
    PKGS="$PKGS pipewire alsa-pipewire"
    mkdir -p "$INCLUDEDIR"/etc/xdg/autostart
    ln -s /usr/share/applications/pipewire.desktop "$INCLUDEDIR"/etc/xdg/autostart/
    mkdir -p "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d
    ln -s /usr/share/examples/wireplumber/10-wireplumber.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
    ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
    mkdir -p "$INCLUDEDIR"/etc/alsa/conf.d
    ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf "$INCLUDEDIR"/etc/alsa/conf.d
    ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf "$INCLUDEDIR"/etc/alsa/conf.d
}

build_variant() {
    IMG=void-live-${ARCH}-${DATE}-${variant}.iso
    GRUB_PKGS="grub-i386-efi grub-x86_64-efi"
    A11Y_PKGS="espeakup void-live-audio brltty"
    PKGS="dialog cryptsetup lvm2 mdadm void-docs-browse xtools-minimal xmirror $A11Y_PKGS $GRUB_PKGS"
    XORG_PKGS="xorg xorg-input-drivers xorg-video-drivers setxkbmap xauth font-misc-misc terminus-font dejavu-fonts-ttf openbox obconf lxappearance lxrandr lightdm octoxbps xbps alacritty neofetch"
    SERVICES="sshd acpid dhcpcd wpa_supplicant lightdm dbus polkitd"

    LIGHTDM_SESSION='openbox'
    mkdir -p "$INCLUDEDIR"/etc/lightdm
    echo "$LIGHTDM_SESSION" > "$INCLUDEDIR"/etc/lightdm/.session
    setup_pipewire
    ./mklive.sh -a "$ARCH" -o "$IMG" -p "$PKGS" -S "$SERVICES" -I "$INCLUDEDIR" ${REPO} "$@"
}

if [ ! -x mklive.sh ]; then
    echo mklive.sh not found >&2
    exit 1
fi

if [ -x installer.sh ]; then
    MKLIVE_VERSION="$(PROGNAME='' version)"
    installer=$(mktemp)
    sed "s/@@MKLIVE_VERSION@@/${MKLIVE_VERSION}/" installer.sh > "$installer"
    install -Dm755 "$installer" "$INCLUDEDIR"/usr/bin/void-installer
    rm "$installer"
else
    echo installer.sh not found >&2
    exit 1
fi

build_variant
