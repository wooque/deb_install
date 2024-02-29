#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

echo_sleep () { echo "$1"; sleep 1; }
ai () { sudo apt install --no-install-recommends --purge "$@"; }
gpgd () { sudo gpg --dearmour -o "$@"; }

id=$(grep ^ID= /etc/os-release)
DISTRO=${id/ID=/}

INSTALL_FONTS="fonts-noto-cjk fonts-noto-core fonts-liberation fonts-noto-color-emoji
fonts-dejavu-core"
INSTALL_GUI="gimp gtk2-engines-pixbuf meld mpv mesa-va-drivers mate-calc mousepad ristretto
webp-pixbuf-loader xarchiver zip p7zip-full zathura libreoffice-gtk3 libreoffice-writer
libreoffice-calc libreoffice-impress transmission-gtk exfalso python3-musicbrainzngs otpclient"
INSTALL_UTILS="apt-transport-https curl ffmpeg htop imagemagick librsvg2-bin qpdf lm-sensors ncdu
neofetch powertop qemu-system-x86 qemu-system-gui qemu-utils radeontop ranger rsync
samba tlp yt-dlp unattended-upgrades upower rclone syncthing ripgrep strace adb fastboot"
INSTALL_DEV="docker.io docker-compose git gitk mkcert libnss3-tools make python-venv build-essential"
INSTALL_EXTRA="brave-browser viber code signal-desktop nodejs asdf-vm
nicotine google-chrome-stable firefox dropbox beekeeper-studio"
INSTALL_SWAY_BASE="sway foot waybar swayidle swaylock wofi mako-notifier kanshi
xdg-desktop-portal-wlr grim slurp jq brightnessctl brightness-udev gammastep
thunar thunar-archive-plugin tumbler pavucontrol cmus cmus-plugin-ffmpeg ncal python3-i3ipc"
INSTALL_SWAY_DESKTOP="pipewire-audio rtkit network-manager xwayland gvfs gvfs-backends eject dconf-cli
gnome-keyring gnome-icon-theme playerctl"
INSTALL_BACKPORTS="yt-dlp"
INSTALL_PACKAGES="$INSTALL_FONTS $INSTALL_GUI $INSTALL_UTILS
$INSTALL_DEV $INSTALL_SWAY_BASE $INSTALL_SWAY_DESKTOP"

ENABLE_SERVICES="tlp"
DISABLE_SERVICES="NetworkManager-wait-online containerd docker nmbd smbd"
DISABLE_USER_SERVICES="gvfs-afc-volume-monitor gvfs-goa-volume-monitor gvfs-gphoto2-volume-monitor"

USER_GROUPS="docker"
CRON="0 17,23 * * * bash -ic backup"
FSTAB="LABEL=PODACI /mnt/PODACI ext4 rw,noatime,x-gvfs-show 0 1"
DOTFILES_GITHUB="wooque/dotfiles"

brave-browser () {
  local key=/usr/share/keyrings/brave-browser-archive-keyring.gpg
  sudo wget https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg -O $key
  echo "deb [signed-by=$key arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo apt update && ai brave-browser
}

viber () {
  # install Bullseye libraries
  echo "deb http://deb.debian.org/debian/ bullseye main" | sudo tee -a /etc/apt/sources.list
  sudo apt update
  ai libavformat58 libswscale5

  ai libgstreamer-plugins-bad1.0-0 libopengl0
  wget "https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb" -O /tmp/viber.deb
  ai /tmp/viber.deb
}

code () {
  wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O /tmp/code.deb
  ai /tmp/code.deb
}

asdf-vm () {
  local version="0.13.1"
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v${version}
  . "$HOME/.asdf/asdf.sh"
  asdf plugin-add nodejs
  asdf plugin-add python
}

dropbox () {
  local version="2023.09.06"
  wget --header "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0" \
    "https://www.dropbox.com/download?dl=packages/debian/dropbox_${version}_amd64.deb" -O /tmp/dropbox.deb
  ai /tmp/dropbox.deb
}

nodejs () {
  local version=20
  local key=/etc/apt/keyrings/nodesource.gpg
  wget -O- https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpgd $key
  echo "deb [signed-by=$key] https://deb.nodesource.com/node_$version.x nodistro main" \
    | sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt update && ai nodejs

  # install additional nodejs tools
  sudo npm -g install yarn diff2html-cli
}

signal-desktop () {
  local key=/usr/share/keyrings/signal-desktop-keyring.gpg
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpgd $key
  echo "deb [arch=amd64 signed-by=$key] https://updates.signal.org/desktop/apt xenial main" \
    | sudo tee /etc/apt/sources.list.d/signal-xenial.list
  sudo apt update && ai signal-desktop
}

beekeeper-studio () {
  local key=/etc/apt/keyrings/beekeeper-studio.gpg
  wget -O- https://deb.beekeeperstudio.io/beekeeper.key | gpgd $key
  echo "deb [signed-by=$key] https://deb.beekeeperstudio.io stable main" \
    | sudo tee /etc/apt/sources.list.d/beekeeper-studio-app.list
  sudo apt update && ai beekeeper-studio
}

nicotine () {
  local key=/etc/apt/keyrings/nicotine-team-ubuntu-stable.gpg
  wget -O- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6E60F93DCD3E27CBE2F0CCA16CEB6050A30E5769" \
    | gpgd $key
  echo "deb [signed-by=$key] https://ppa.launchpadcontent.net/nicotine-team/stable/ubuntu jammy main" \
    | sudo tee /etc/apt/sources.list.d/nicotine-team-ubuntu-stable.list
  sudo apt update && ai nicotine
}

google-chrome-stable () {
  wget "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O /tmp/chrome.deb
  ai /tmp/chrome.deb
}

firefox () {
  local key=/etc/apt/keyrings/packages.mozilla.org.asc
  wget https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee $key
  echo "deb [signed-by=$key] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list
  sudo apt update && ai firefox
}

main () {
  echo_sleep "Install packages..."
  ai $INSTALL_PACKAGES
  sudo dpkg-reconfigure unattended-upgrades

  echo_sleep "Setup and install backports..."
  echo "deb http://deb.debian.org/debian bookworm-backports main non-free-firmware" | sudo tee -a /etc/apt/sources.list
  sudo apt update
  sudo apt install --no-install-recommends -t bookworm-backports $INSTALL_BACKPORTS

  echo_sleep "Fix network..."
  if [ -f /etc/network/interfaces ]; then
    sudo rm /etc/network/interfaces
  fi

  echo_sleep "Add groups..."
  sudo usermod -a -G "$USER_GROUPS" "$USER"

  echo_sleep "Enable services..."
  sudo systemctl enable --now $ENABLE_SERVICES

  echo_sleep "Disable system services..."
  sudo systemctl disable --now $DISABLE_SERVICES

  echo_sleep "Disable user services..."
  systemctl --user mask --now $DISABLE_USER_SERVICES

  echo_sleep "Update GRUB..."
  sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
  GRUB_OPTS="quiet loglevel=3 systemd.show_status=false mitigations=off amd_iommu=off nowatchdog"
  sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"${GRUB_OPTS//\./\\.}\"/" \
    /etc/default/grub
  echo 'GRUB_BACKGROUND=""' | sudo tee -a /etc/default/grub
  sudo update-grub

  echo_sleep "Update initramfs..."
  sudo sed -i 's/MODULES=.*/MODULES=dep/' /etc/initramfs-tools/initramfs.conf
  sudo update-initramfs -u

  echo_sleep "Setup systemd tweaks..."
  sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=10M/' /etc/systemd/journald.conf
  sudo sed -i 's/#RuntimeMaxUse=/RuntimeMaxUse=10M/' /etc/systemd/journald.conf
  sudo sed -i 's/#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=5s/' /etc/systemd/system.conf
  sudo sed -i 's/#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=5s/' /etc/systemd/user.conf
  sudo sed -i 's/#KillUserProcesses=.*/KillUserProcesses=yes/' /etc/systemd/logind.conf

  echo_sleep "Disable Bluetooth hardware volume..."
  sudo mkdir -p /etc/wireplumber/bluetooth.lua.d
  sudo cp /usr/share/wireplumber/bluetooth.lua.d/50-bluez-config.lua \
    /etc/wireplumber/bluetooth.lua.d
  sudo sed -i 's/\-\-\["bluez5.enable\-hw\-volume"\] = true/\["bluez5.enable\-hw\-volume"\] = false/' \
    /etc/wireplumber/bluetooth.lua.d/50-bluez-config.lua

  echo_sleep "Setup TLP..."
  sudo cp ./tlp.conf /etc/tlp.d/custom.conf

  echo_sleep "Setup fonts..."
  sudo cp ./fonts.conf /etc/fonts/local.conf

  echo_sleep "Setup fstab..."
  # set noatime for root
  sudo sed -i 's/errors=remount-ro/errors=remount-ro,noatime/' /etc/fstab
  if ! grep -Fxq "$FSTAB" /etc/fstab; then
    echo "$FSTAB" | sudo tee -a /etc/fstab
  fi

  echo_sleep "Setup cron..."
  if ! sudo grep -Fxq "$CRON" /var/spool/cron/crontabs/"$USER"; then
    echo "$CRON" | sudo -g crontab tee -a /var/spool/cron/crontabs/"$USER"
  fi
  sudo chown "$USER":crontab /var/spool/cron/crontabs/"$USER"
  sudo chmod 0600 /var/spool/cron/crontabs/"$USER"

  if [ "$DISTRO" = "debian" ]; then
    echo_sleep "Debian modules fixes..."
    echo "cpufreq_powersave" | sudo tee /etc/modules-load.d/cpufreq.conf
    echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf
  fi

  echo_sleep "Load dconf..."
  dconf load / < "./$DISTRO/dconf.conf"

  echo_sleep "Setup autologin..."
  sudo mkdir /etc/systemd/system/getty@tty1.service.d
  sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty -o '-p -f -- \\u' --skip-login --nonewline --noissue  --noclear --autologin $USER %I \$TERM
EOF

  echo_sleep "Fetch dotfiles..."
  cd "/home/$USER"
  git init
  git remote add origin "https://github.com/$DOTFILES_GITHUB"
  git fetch --set-upstream origin master
  git reset --hard origin/master
  git remote set-url origin "git@github.com:$DOTFILES_GITHUB.git"

  # flaky installs at the end
  for app in $INSTALL_EXTRA; do
    echo_sleep "Install $app..."
    $app
  done

  echo_sleep "asdf install..."
  . "$HOME/.asdf/asdf.sh"
  asdf nodejs update nodebuild
  asdf install
}
main "$@"
