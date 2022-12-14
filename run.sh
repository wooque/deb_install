#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo_sleep () { echo "$1"; sleep 1; }

id=$(grep ^ID= /etc/os-release)
DISTRO=${id/ID=/}

INSTALL_FONTS="fonts-noto-cjk fonts-noto-core fonts-liberation fonts-noto-color-emoji"
INSTALL_GNOME="gnome-shell-extension-appindicator gnome-shell-extension-bluetooth-quick-connect gnome-tweaks gstreamer1.0-vaapi libdbus-glib-1-2"
INSTALL_GUI="gimp meld mpv"
INSTALL_UTILS="apt-transport-https curl ffmpeg htop imagemagick lm-sensors ncdu neofetch powertop qemu-system-x86 radeontop ranger rsync samba tlp yt-dlp"
INSTALL_DEV="docker.io docker-compose git gitk"
INSTALL_BUILD="build-essential zlib1g-dev libbz2-dev libncurses-dev libffi-dev libreadline-dev libssl-dev libsqlite3-dev liblzma-dev"
INSTALL_EXTRA="brave-browser viber code beekeeper-studio asdf-vm dropbox insomnia firefox"
INSTALL_PACKAGES="amd64-microcode $INSTALL_FONTS $INSTALL_GNOME $INSTALL_GUI $INSTALL_UTILS $INSTALL_DEV $INSTALL_BUILD"

REMOVE_GNOME="baobab cheese evolution-data-server fwupd gnome-calendar gnome-characters gnome-clocks gnome-font-viewer gnome-games gnome-logs gnome-maps gnome-music gnome-online-accounts gnome-software gnome-sound-recorder gnome-sushi gnome-system-monitor gnome-weather ibus totem"
REMOVE_GAMES="aisleriot gnome-mahjongg gnome-mines gnome-sudoku"
REMOVE_SYSTEM="snapd systemd-oomd needrestart"
if [ "$DISTRO" = "debian" ]; then
  # removing plymouth speeds up boot
  REMOVE_SYSTEM="plymouth $REMOVE_SYSTEM"
fi
REMOVE_APPS="deja-dup firefox-esr remmina shotwell simple-scan thunderbird"
REMOVE_PACKAGES="$REMOVE_SYSTEM $REMOVE_GNOME $REMOVE_GAMES $REMOVE_APPS"

ENABLE_SERVICES="tlp"

DISABLE_PREINSTALLED="avahi-daemon bolt cups cups-browsed kerneloops ModemManager rsyslog switcheroo-control NetworkManager-wait-online"
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
  sudo apt update
  sudo apt install brave-browser
}

viber () {
  wget "https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb" -O /tmp/viber.deb
  sudo apt install /tmp/viber.deb
}

code () {
  wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O /tmp/code.deb
  sudo apt install /tmp/code.deb
}

beekeeper-studio () {
  curl https://deb.beekeeperstudio.io/beekeeper.key | sudo gpg --dearmor -o /usr/share/keyrings/beekeeper-studio.gpg
  echo "deb [signed-by=/usr/share/keyrings/beekeeper-studio.gpg] https://deb.beekeeperstudio.io stable main" | sudo tee /etc/apt/sources.list.d/beekeeper-studio-app.list
  sudo apt update
  sudo apt install beekeeper-studio
}

asdf-vm () {
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
  . "$HOME/.asdf/asdf.sh"
  asdf plugin-add nodejs
  asdf plugin-add python
}

dropbox () {
  version="2020.03.04"
  wget "https://linux.dropbox.com/packages/ubuntu/dropbox_${version}_amd64.deb" -O /tmp/dropbox.deb
  sudo apt install /tmp/dropbox.deb
  apt-key export 5044912E | sudo gpg --dearmour -o /usr/share/keyrings/dropbox.gpg
  sudo sed -i 's/arch=i386,amd64]/arch=i386,amd64 signed-by=\/usr\/share\/keyrings\/dropbox.gpg]/' /etc/apt/sources.list.d/dropbox.list
}

insomnia () {
  wget "https://updates.insomnia.rest/downloads/ubuntu/latest?&app=com.insomnia.app&source=website" -O /tmp/insomnia.deb
  sudo apt install /tmp/insomnia.deb
}

firefox () {
  wget "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US" -O /tmp/firefox.tar.bz2
  tar -xvf /tmp/firefox.tar.bz2 -C "$HOME/.local/share"
  cat >> "$HOME/.local/share/applications/firefox.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=Firefox Web Browser
Comment=Browse the World Wide Web
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer
Exec=$HOME/.local/share/firefox/firefox %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=$HOME/.local/share/firefox/browser/chrome/icons/default/default128.png
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=false
EOF
}

main () {
  echo_sleep "Install packages..."
  sudo apt install $INSTALL_PACKAGES

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
  sudo systemctl disable --now $DISABLE_SERVICES || true

  echo_sleep "Disable user services..."
  systemctl --user mask --now $DISABLE_USER_SERVICES

  echo_sleep "Update GRUB..."
  sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
  if [ "$DISTRO" = "debian" ]; then
  sudo sed -i 's/quiet/quiet loglevel=3 systemd.show_status=auto mitigations=off amd_iommu=off nowatchdog/' /etc/default/grub
  echo 'GRUB_BACKGROUND=""' | sudo tee -a /etc/default/grub
  elif [ "$DISTRO" = "ubuntu" ]; then
  sudo sed -i 's/quiet splash/quiet splash mitigations=off amd_iommu=off/' /etc/default/grub
  fi
  sudo update-grub

  echo_sleep "Setup systemd tweaks..."
  sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=10M/' /etc/systemd/journald.conf
  sudo sed -i 's/#RuntimeMaxUse=/RuntimeMaxUse=10M/' /etc/systemd/journald.conf

  #echo_sleep "Disable Bluetooth auto-enable"
  #sudo sed -i 's/AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf

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
