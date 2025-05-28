#!/usr/bin/env bash

DISTRO=$(sed -n 's/^ID=//p' /etc/os-release)

apt list --manual-installed | cut -d / -f 1 | tail -n +2 | sort > "$DISTRO"/manual-installed.txt
apt list --installed | cut -d / -f 1 | tail -n +2 | sort > "$DISTRO"/installed.txt
dconf dump / > "$DISTRO"/dconf.conf
