#!/bin/bash
pacman -S base dracut linux-cachyos linux-firmware ostree btrfs-progs e2fsprogs xfsprogs dosfstools skopeo dbus dbus-glib glib2 ostree fastfetch distrobox podman flatpak paru mesa sddm plasma firefox obs-studio
systemctl enable sddm && sudo cachyos-rate-mirrors

#setup cachyos repo
curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh
cd ../
rm -rf cachyos-repo