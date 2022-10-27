#!/usr/bin/env bash

id=$(grep ^ID= /etc/os-release)
DISTRO=${id/ID=/}

apt list --manual-installed | cut -d / -f 1 | tail -n +2 | sort > "$DISTRO"/manual-installed.txt
apt list --installed | cut -d / -f 1 | tail -n +2 | sort > "$DISTRO"/installed.txt
dconf dump / > "$DISTRO"/dconf.conf
