#!/usr/bin/env bash

ubuntu_version=$(lsb_release -rs)
echo "Detected Ubuntu version: $ubuntu_version"
case "$ubuntu_version" in
"18.04")
        apt update
	apt install -y install binutils gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-8-dev libpython3.8 libsqlite3-0 libstdc++-8-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev -y
	;;
"20.04")
        apt update
	apt install -y binutils gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-10-dev libpython3.8 libsqlite3-0 libstdc++-10-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev
	;;
"22.04")
        apt update
	apt install -y apt-get install binutils gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-10-dev libpython3.8 libsqlite3-0 libstdc++-10-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev
	;;
*)
	echo "Unsupported Ubuntu version: $ubuntu_version. This script supports 18.04, 20.04, and 22.04."
	exit 1
	;;
esac
