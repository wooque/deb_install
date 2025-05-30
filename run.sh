#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

echo_sleep () { echo "$1"; sleep 1; }
ai () { sudo apt install --no-install-recommends --purge "$@"; }
gpgd () { sudo gpg --dearmour -o "$@"; }

DISTRO=$(sed -n 's/^ID=//p' /etc/os-release)

PACKAGES="
# system
sway
foot
fuzzel
waybar
network-manager
network-manager-applet
lxpolkit
pipewire-audio
rtkit
pavucontrol
blueman
playerctl
ncal
mako-notifier
gammastep
wl-clipboard
cliphist
python3-i3ipc
kanshi
dconf-cli
brightnessctl
brightness-udev
swayidle
swaylock
grim
slurp
jq
xdg-desktop-portal-wlr
xwayland
thunar
thunar-archive-plugin
tumbler
gvfs
gvfs-backends
eject
gnome-keyring
adwaita-icon-theme-legacy
# fonts
fonts-font-awesome
fonts-liberation
fonts-dejavu-core
fonts-noto-cjk
fonts-noto-core
fonts-noto-color-emoji
# GUI apps
mate-calc
xarchiver
7zip
mousepad
ristretto
webp-pixbuf-loader
zathura
libreoffice-gtk3
libreoffice-writer
libreoffice-calc
libreoffice-impress
gimp
mpv
mesa-va-drivers
mesa-vulkan-drivers
transmission-gtk
thunderbird
exfalso
nicotine
# cli utils
curl
ripgrep
ranger
cmus
cmus-plugin-ffmpeg
tlp
upower
htop
lm-sensors
strace
ncdu
radeontop
fastfetch
yt-dlp
ffmpeg
imagemagick
rclone
syncthing
unattended-upgrades
qemu-system-x86
qemu-system-gui
qemu-utils
samba
# dev
docker.io
docker-cli
docker-buildx
docker-compose
git
gitk
meld
build-essential
python3-venv
awscli
tokei"
INSTALL_PACKAGES=$(echo "$PACKAGES" | grep -vE '^#|^\s*$')

EXTRA_PACKAGES="
wl-clip-persist
firefox
brave-browser
google-chrome-stable
viber
code
cursor
beekeeper-studio
nodejs
asdf-vm
dropbox
signal-desktop
slack-desktop"
INSTALL_EXTRA=$(echo "$EXTRA_PACKAGES" | grep -vE '^#|^\s*$')
INSTALL_PYTHON_BUILD_DEPS="libbz2-dev libffi-dev liblzma-dev libncurses-dev libreadline-dev libsqlite3-dev libssl-dev tk-dev uuid-dev zlib1g-dev"

wl-clip-persist () {
  cd /tmp
  git clone https://github.com/Linus789/wl-clip-persist
  cd ./wl-clip-persist
  ai cargo
  cargo build --release
  sudo mv ./target/release/wl-clip-persist /usr/local/bin
  sudo apt purge --auto-remove -y cargo
  rm -rf $HOME/.cargo
}

firefox () {
  local key=/usr/share/keyrings/packages.mozilla.org.gpg
  wget -qO - https://packages.mozilla.org/apt/repo-signing-key.gpg | gpgd $key
  sudo tee /etc/apt/sources.list.d/mozilla.sources <<EOF
Types: deb
URIs: https://packages.mozilla.org/apt/
Suites: mozilla
Components: main
Signed-By: $key
EOF
  sudo apt update && ai firefox
}

brave-browser () {
  local key=/usr/share/keyrings/brave-browser-archive-keyring.gpg
  wget -qO- https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | sudo tee $key >/dev/null
  sudo tee /etc/apt/sources.list.d/brave-browser-release.sources <<EOF
Types: deb
URIs: https://brave-browser-apt-release.s3.brave.com/
Suites: stable
Components: main
Signed-By: $key
EOF
  sudo apt update && ai brave-browser
}

google-chrome-stable () {
  local key=/usr/share/keyrings/google-chrome.gpg
  wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpgd $key
  sudo tee /etc/apt/sources.list.d/google-chrome.sources <<EOF
Types: deb
URIs: https://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Signed-By: $key
EOF
  sudo apt update && ai google-chrome-stable
}

viber () {
  ai libopengl0
  wget "https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb" -O /tmp/viber.deb
  ai /tmp/viber.deb
}

code () {
  local key=/usr/share/keyrings/microsoft.gpg
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpgd $key
  sudo tee /etc/apt/sources.list.d/vscode.sources <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code/
Suites: stable
Components: main
Signed-By: $key
EOF
  sudo apt update && ai code
}

cursor () {
  ai libfuse2t64
  local downloadUrl=$(wget -qO- "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable" | jq .downloadUrl)
  wget ${downloadUrl//\"/} -qO /tmp/cursor.appimage
  chmod +x /tmp/cursor.appimage
  mkdir -p $HOME/.local/bin
  mv /tmp/cursor.appimage $HOME/.local/bin/cursor-appimage
}

beekeeper-studio () {
  local key=/usr/share/keyrings/beekeeper-studio.gpg
  wget -qO- https://deb.beekeeperstudio.io/beekeeper.key | gpgd $key
  sudo tee /etc/apt/sources.list.d/beekeeper-studio-app.sources <<EOF
Types: deb
URIs: https://deb.beekeeperstudio.io/
Suites: stable
Components: main
Signed-By: $key
EOF
  sudo apt update && ai beekeeper-studio
}

nodejs () {
  local key=/usr/share/keyrings/nodesource.gpg
  wget -qO- https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpgd $key
  sudo tee /etc/apt/sources.list.d/nodesource.sources <<EOF
Types: deb
URIs: https://deb.nodesource.com/node_22.x/
Suites: nodistro
Components: main
Signed-By: $key
EOF
  sudo apt update && ai nodejs

  # install additional nodejs tools
  sudo npm -g install diff2html-cli
}

asdf-vm () {
  version=$(git ls-remote --tags --refs https://github.com/asdf-vm/asdf.git | awk -F/ '{print $NF}' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^v//' | sort -V | tail -n1)
  echo "Installing asdf-vm version: $version"
  wget -qO- "https://github.com/asdf-vm/asdf/releases/download/v$version/asdf-v$version-linux-amd64.tar.gz" | tar -xzf - -C /tmp
  sudo mv /tmp/asdf /usr/local/bin
}

dropbox () {
  local key=/usr/share/keyrings/dropbox.gpg
  wget -qO- https://linux.dropboxstatic.com/fedora/rpm-public-key.asc | gpgd $key
  sudo tee /etc/apt/sources.list.d/dropbox.sources <<EOF
Types: deb
URIs: http://linux.dropbox.com/debian/
Suites: trixie
Components: main
Signed-By: $key
EOF
  sudo apt update && ai dropbox
}

signal-desktop () {
  local key=/usr/share/keyrings/signal-desktop-keyring.gpg
  wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpgd $key
  sudo tee /etc/apt/sources.list.d/signal-xenial.sources <<EOF
Types: deb
URIs: https://updates.signal.org/desktop/apt/
Suites: xenial
Components: main
Signed-By: $key
EOF
  sudo apt update && ai signal-desktop
}

slack-desktop () {
  local key=/usr/share/keyrings/slack.gpg
  ai libglib2.0-bin
  sudo tee /etc/apt/sources.list.d/slack.sources <<EOF
Types: deb
URIs: https://packagecloud.io/slacktechnologies/slack/debian/
Suites: jessie
Components: main
Signed-By: /etc/apt/trusted.gpg.d/slack-desktop.gpg
EOF
  sudo apt update && ai slack-desktop
  # to insert key
  sudo /etc/cron.daily/slack
}

DISABLE_SERVICES="docker containerd nmbd smbd"
DISABLE_USER_SERVICES="gvfs-afc-volume-monitor gvfs-goa-volume-monitor gvfs-gphoto2-volume-monitor"

USER_GROUPS="docker"
FSTAB="LABEL=PODACI /mnt/PODACI ext4 rw,noatime,x-gvfs-show 0 1"
CRON="0 17,23 * * * bash -ic backup"
DOTFILES_GITHUB="wooque/dotfiles"

main () {
  echo_sleep "Setup apt..."
  sudo tee /etc/apt/apt.conf.d/99norecommends <<EOF
APT::Install-Recommends "false";
EOF
  sudo sed -i '/^deb-src /d' /etc/apt/sources.list
  sudo apt modernize-sources

  echo_sleep "Install packages..."
  ai $INSTALL_PACKAGES
  sudo dpkg-reconfigure unattended-upgrades

  echo_sleep "Fix network..."
  if [ -f /etc/network/interfaces ]; then
    sudo rm /etc/network/interfaces
  fi

  echo_sleep "Add groups..."
  sudo usermod -a -G "$USER_GROUPS" "$USER"

  echo_sleep "Disable system services..."
  sudo systemctl disable --now $DISABLE_SERVICES

  echo_sleep "Disable user services..."
  systemctl --user mask --now $DISABLE_USER_SERVICES

  echo_sleep "Update GRUB..."
  sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
  GRUB_OPTS="quiet loglevel=3 mitigations=off nowatchdog"
  sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"${GRUB_OPTS//\./\\.}\"/" \
    /etc/default/grub
  sudo update-grub

  echo_sleep "Update initramfs..."
  sudo sed -i 's/MODULES=.*/MODULES=dep/' /etc/initramfs-tools/initramfs.conf
  sudo update-initramfs -u

  echo_sleep "Setup systemd tweaks..."
  sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=10M/' /etc/systemd/journald.conf
  sudo sed -i 's/#RuntimeMaxUse=/RuntimeMaxUse=10M/' /etc/systemd/journald.conf

  echo_sleep "Setup TLP..."
  sudo cp ./tlp.conf /etc/tlp.d/custom.conf

  echo_sleep "Fix bluetooth sleep..."
  sudo tee /usr/lib/systemd/system-sleep/mysleep <<'EOF'
#!/bin/sh
[ "$1" = "pre" ] && echo "disconnecting bt..." && bluetoothctl disconnect
EOF
  sudo chmod +x /usr/lib/systemd/system-sleep/mysleep

  echo_sleep "Fix bluetooth autoconnect..."
  sudo mkdir -p /etc/wireplumber/wireplumber.conf.d
  sudo tee /etc/wireplumber/wireplumber.conf.d/99-my-config.conf <<EOF
monitor.bluez.rules = [
  {
    matches = [
      {
        ## This matches all bluetooth devices.
        device.name = "~bluez_card.*"
      }
    ]
    actions = {
      update-props = {
        bluez5.auto-connect = [ hfp_hf hsp_hs a2dp_sink hfp_ag hsp_ag a2dp_source ]
      }
    }
  }
]
EOF

  echo_sleep "Setup fonts..."
  sudo cp ./fonts.conf /etc/fonts/local.conf

  echo_sleep "Setup fstab..."
  # set noatime for root
  sudo sed -i 's/errors=remount-ro/errors=remount-ro,noatime/' /etc/fstab
  if ! grep -Fxq "$FSTAB" /etc/fstab; then
    echo "$FSTAB" | sudo tee -a /etc/fstab
  fi

  echo_sleep "Setup cron..."
  echo "$CRON" | crontab -

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

  echo_sleep "key signing workaround..."
  sudo mkdir -p /etc/crypto-policies/back-ends
  sudo tee /etc/crypto-policies/back-ends/apt-sequoia.config <<EOF
[hash_algorithms]
sha1.collision_resistance = "always"
sha1.second_preimage_resistance = "always"
EOF
  sudo apt update

  # flaky installs at the end
  for app in $INSTALL_EXTRA; do
    echo_sleep "Install $app..."
    $app
  done
}
main "$@"
