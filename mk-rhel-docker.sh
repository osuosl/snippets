#!/bin/bash
# Build a minimal test-kitchen docker image for RHEL
# NOTE: IMAGE SHOULD NOT TO BE PUBLICLY DISTRIBUTED!

set -xe
BUILDDATE=$(date +%Y%m%d)
mkdir rhelbuild-"${BUILDDATE}"
cd rhelbuild-"${BUILDDATE}"
mkdir img
mkdir -m 755 img/dev
mknod -m 600 img/dev/console c 5 1
mknod -m 600 img/dev/initctl p
mknod -m 666 img/dev/full c 1 7
mknod -m 666 img/dev/null c 1 3
mknod -m 666 img/dev/ptmx c 5 2
mknod -m 666 img/dev/random c 1 8
mknod -m 666 img/dev/tty c 5 0
mknod -m 666 img/dev/tty0 c 4 0
mknod -m 666 img/dev/urandom c 1 9
mknod -m 666 img/dev/zero c 1 5

yum --installroot="$PWD"/img \
  --releasever=/ \
  --setopt=tsflags=nodocs \
  --setopt=group_package_types=mandatory -y install \
  bash yum vim-minimal yum-plugin-ovl curl emacs-nox gnupg2 initscripts \
  iptables iputils lsof nc net-tools nmap openssl procps strace systemd-sysv \
  tcpdump telnet vim wget which bind-utils less
cp -a /etc/yum* /etc/rhsm/* /etc/pki/* img/etc/
yum --installroot="$PWD"/img clean all

rm -fr img/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
rm -fr img/usr/share/{man,doc,info,gnome/help}
rm -fr img/usr/share/cracklib
rm -fr img/usr/share/i18n
rm -fr img/etc/ld.so.cache
rm -fr img/var/cache/ldconfig/*

tar -cJf docker.tar.xz -C img/ .

cat << EOF >> Dockerfile
FROM scratch
ADD docker.tar.xz /

LABEL name="RHEL test-kitchen image" \\
    vendor="RHEL" \\
    license="GPLv2" \\
    build-date="$BUILDDATE"
CMD [ '/usr/lib/systemd/systemd' ]
EOF

docker build --tag rhel .
