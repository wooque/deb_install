#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo_sleep () { echo "$1"; sleep 1; }

id=$(grep ^ID= /etc/os-release)
DISTRO=${id/ID=/}

INSTALL_FONTS="fonts-noto-cjk fonts-noto-core fonts-liberation fonts-noto-color-emoji"
INSTALL_GNOME="gnome-shell-extension-appindicator gnome-shell-extension-bluetooth-quick-connect gnome-tweaks gnome-power-manager gstreamer1.0-vaapi libavif-gdk-pixbuf"
INSTALL_GUI="gimp meld mpv"
INSTALL_UTILS="apt-transport-https curl ffmpeg htop imagemagick lm-sensors ncdu neofetch powertop qemu-system-x86 qemu-system-gui qemu-utils radeontop ranger rsync samba tlp yt-dlp unattended-upgrades"
INSTALL_DEV="docker.io docker-compose git gitk"
INSTALL_BUILD="build-essential zlib1g-dev libbz2-dev libncurses-dev libffi-dev libreadline-dev libssl-dev libsqlite3-dev liblzma-dev"
INSTALL_EXTRA="brave-browser viber code signal-desktop nodejs asdf-vm beekeeper-studio dropbox"
INSTALL_PACKAGES="amd64-microcode $INSTALL_FONTS $INSTALL_GNOME $INSTALL_GUI $INSTALL_UTILS $INSTALL_DEV $INSTALL_BUILD"

REMOVE_GNOME="baobab cheese evolution-data-server fwupd gnome-calendar gnome-characters gnome-clocks gnome-font-viewer gnome-games gnome-logs gnome-maps gnome-music gnome-online-accounts gnome-shell-extensions gnome-software gnome-sound-recorder gnome-sushi gnome-system-monitor gnome-weather ibus totem yelp"
REMOVE_GAMES="aisleriot gnome-mahjongg gnome-mines gnome-sudoku"
REMOVE_SYSTEM="low-memory-monitor needrestart snapd systemd-oomd"
REMOVE_APPS="deja-dup remmina shotwell simple-scan synaptic thunderbird"
REMOVE_LIBREOFFICE_EXTRAS="libreoffice-help-en-us mythes-en-us hyphen-en-us"
REMOVE_PACKAGES="$REMOVE_SYSTEM $REMOVE_GNOME $REMOVE_GAMES $REMOVE_APPS $REMOVE_LIBREOFFICE_EXTRAS"

ENABLE_SERVICES="tlp"

DISABLE_PREINSTALLED="avahi-daemon bolt cups cups-browsed ModemManager switcheroo-control"
if [ "$DISTRO" = "ubuntu" ]; then
  DISABLE_PREINSTALLED="$DISABLE_PREINSTALLED kerneloops rsyslog"
fi
DISABLE_INSTALLED="containerd docker nmbd smbd"
DISABLE_SERVICES="$DISABLE_PREINSTALLED $DISABLE_INSTALLED"

DISABLE_GNOME="org.gnome.SettingsDaemon.Color org.gnome.SettingsDaemon.PrintNotifications org.gnome.SettingsDaemon.Sharing org.gnome.SettingsDaemon.Smartcard org.gnome.SettingsDaemon.Wacom tracker-miner-fs-3"
DISABLE_GVFS="gvfs-afc-volume-monitor gvfs-goa-volume-monitor gvfs-gphoto2-volume-monitor"
DISABLE_USER_SERVICES="$DISABLE_GNOME $DISABLE_GVFS"

USER_GROUPS="docker"
CRON="0 11,17,23 * * * bash -ic backup"
FSTAB="LABEL=PODACI /mnt/PODACI ext4 rw,noatime,x-gvfs-show 0 1"
DOTFILES_GITHUB="wooque/dotfiles"

brave-browser () {
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"| sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo apt update && sudo apt install brave-browser
}

viber () {
  wget "https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb" -O /tmp/viber.deb
  sudo apt install /tmp/viber.deb
}

code () {
  wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O /tmp/code.deb
  sudo apt install /tmp/code.deb
}

asdf-vm () {
  version="0.11.2"
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v${version}
  . "$HOME/.asdf/asdf.sh"
  asdf plugin-add nodejs
  asdf plugin-add python
}

dropbox () {
  version="2022.12.05"
  wget --header "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0" "https://linux.dropbox.com/packages/ubuntu/dropbox_${version}_amd64.deb" -O /tmp/dropbox.deb
  sudo apt install /tmp/dropbox.deb
  sudo apt update && sudo apt upgrade
  apt-key export 5044912E | sudo gpg --dearmour -o /usr/share/keyrings/dropbox.gpg
  sudo sed -i 's/arch=i386,amd64]/arch=i386,amd64 signed-by=\/usr\/share\/keyrings\/dropbox.gpg]/' /etc/apt/sources.list.d/dropbox.list
}

nodejs () {
  wget -O- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
  echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x bookworm main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt update && sudo apt install nodejs
}

signal-desktop () {
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | sudo gpg --dearmor -o /usr/share/keyrings/signal-desktop-keyring.gpg
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee /etc/apt/sources.list.d/signal-xenial.list
  sudo apt update && sudo apt install signal-desktop
}

beekeeper-studio () {
  curl https://deb.beekeeperstudio.io/beekeeper.key | sudo gpg --dearmor -o /usr/share/keyrings/beekeeper-studio.gpg
  echo "deb [signed-by=/usr/share/keyrings/beekeeper-studio.gpg] https://deb.beekeeperstudio.io stable main" | sudo tee /etc/apt/sources.list.d/beekeeper-studio-app.list
  sudo apt update && sudo apt install beekeeper-studio
}

main () {
  echo_sleep "Install packages..."
  sudo apt install --no-install-recommends --purge $INSTALL_PACKAGES

  for app in $INSTALL_EXTRA; do
    echo_sleep "Install $app..."
    $app
  done

  echo_sleep "Remove packages..."
  # workaround so snap removal doesn't fail
  [ -d /var/snap/firefox/common/host-hunspell ] && sudo umount /var/snap/firefox/common/host-hunspell
  sudo apt purge --auto-remove $REMOVE_PACKAGES
  [ -d "$HOME"/snap ] && rm -rf "$HOME"/snap

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
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 mitigations=off amd_iommu=off nowatchdog"/' /etc/default/grub
  sudo update-grub

  echo_sleep "Setup systemd tweaks..."
  sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=10M/' /etc/systemd/journald.conf
  sudo sed -i 's/#RuntimeMaxUse=/RuntimeMaxUse=10M/' /etc/systemd/journald.conf

  echo_sleep "Disable Bluetooth hardware volume..."
  sudo mkdir -p /etc/wireplumber/bluetooth.lua.d
  sudo cp /usr/share/wireplumber/bluetooth.lua.d/50-bluez-config.lua /etc/wireplumber/bluetooth.lua.d
  sudo sed -i 's/\-\-\["bluez5.enable\-hw\-volume"\] = true/\["bluez5.enable\-hw\-volume"\] = false/' /etc/wireplumber/bluetooth.lua.d/50-bluez-config.lua

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
  sudo sed -i "s/#  AutomaticLoginEnable/AutomaticLoginEnable/" /etc/gdm3/daemon.conf
  sudo sed -i "s/#  AutomaticLogin = user1/AutomaticLogin = $USER/" /etc/gdm3/daemon.conf

  echo_sleep "Fetch dotfiles..."
  cd "/home/$USER"
  git init
  git remote add origin "https://github.com/$DOTFILES_GITHUB"
  git fetch --set-upstream origin master
  git reset --hard origin/master
  git remote set-url origin "git@github.com:$DOTFILES_GITHUB.git"

  echo_sleep "Remove default directories..."
  find "$HOME" -mindepth 1 -maxdepth 1 -type d -not -path "$HOME/.*" -exec rm -rf {} \;

  echo_sleep "Reset app grid..."
  gsettings set org.gnome.shell app-picker-layout "[]"

  echo_sleep "asdf install..."
  . "$HOME/.asdf/asdf.sh"
  asdf nodejs update nodebuild
  asdf install
}
main "$@"
