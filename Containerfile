FROM docker.io/cachyos/cachyos-v3:latest





# Credit Goes to Xenia OS for a great starting point! 



#Set up CachyOS repo just in case

RUN pacman-key --recv-key F3B607488DB35A47 --keyserver keyserver.ubuntu.com



RUN pacman-key --init && pacman-key --lsign-key F3B607488DB35A47



RUN pacman -U 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' --noconfirm



RUN pacman -U 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-22-1-any.pkg.tar.zst' --noconfirm



RUN echo -e 'Include = /etc/pacman.d/cachyos-v3-mirrorlist' >> /etc/pacman.conf



ENV DEV_DEPS="base-devel git rust"



ENV DRACUT_NO_XATTR=1




RUN pacman -Syyu --noconfirm

RUN pacman -S --noconfirm \
      base \
      dracut \
      linux-cachyos \
      linux-firmware \
      ostree \
      btrfs-progs \
      e2fsprogs \
      xfsprogs \
      dosfstools \
      skopeo \
      dbus \
      dbus-glib \
      glib2 \
      ostree \
      fastfetch \
      distrobox \
      podman \
      flatpak \
      paru \
      mesa \
      sddm \
      plasma \
      firefox \
      obs-studio \
      flameshot \
      cachyos-rate-mirrors \
      shadow && \
RUN systemctl enable sddm
RUN sudo cachyos-rate-mirrors

# Regression with newer dracut broke this
RUN mkdir -p /etc/dracut.conf.d && \
    printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /etc/dracut.conf.d/fix-bootc.conf


RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root \
    pacman -S --noconfirm base-devel git rust && \
    git clone "https://github.com/bootc-dev/bootc.git" /tmp/bootc && \
    make -C /tmp/bootc bin install-all install-initramfs-dracut && \
    sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"' && \
    pacman -Rns --noconfirm base-devel git rust && \
    pacman -S --clean --noconfirm



# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv && \
    mkdir -p /var /sysroot /boot /usr/lib/ostree && \
    ln -s var/opt /opt && \
    ln -s var/roothome /root && \
    ln -s var/home /home && \
    ln -s sysroot/ostree /ostree && \
    echo "$(for dir in opt usrlocal home srv mnt ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    echo "d /var/roothome 0700 root root -" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    echo "d /run/media 0755 root root -" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    printf "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | tee "/usr/lib/ostree/prepare-root.conf"

# Setup a temporary root passwd (changeme) for dev purposes
# RUN pacman -S whois --noconfirm
# RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root


RUN bootc container lint