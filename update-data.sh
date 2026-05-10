#!/usr/bin/env bash

DISTRO=$(sed -n 's/^ID=//p' /etc/os-release)

apt list --manual-installed | cut -d / -f 1 | tail -n +2 | sort > "$DISTRO"/manual-installed.txt
apt list --installed | cut -d / -f 1 | tail -n +2 | sort > "$DISTRO"/installed.txt
dconf dump / | \
sed '/^\[org\/blueman\/plugins\/autoconnect\]/,/^$/d' | \
sed '/^\[org\/blueman\/plugins\/recentconns\]/,/^$/d' | \
sed '/^\[org\/gnome\/nm-applet\/eap/,/^$/d' | \
sed '/^\[org\/gnome\/gitg\/state/,/^$/d' | \
grep -vE '^(size=\(|window-properties=\[|state=|width=|height=)' > "$DISTRO"/dconf.conf
