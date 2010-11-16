#!/usr/bin/env bash

pacman -Syu --noconfirm base-devel fakeroot #update core install base

#add yaourt
echo "[archlinuxfr]" >> /etc/pacman.conf
echo 'Server = http://repo.archlinux.fr/$arch' >> /etc/pacman.conf

pacman -Syu --noconfirm yaourt

#install abs
pacman -Syu --noconfirm abs

sed -i 's:REPO=(core extra community testing community-testing):REPO=(core extra community !testing !community-testing):' /etc/abs.conf

abs #update abs

#install apache and others

pacman -S --noconfirm apache php php-apache

#grab rtorrent and depends PKGBUILD

mkdir $HOME/abs

yaourt -G mod_scgi

mv $HOME/mod-scgi                   $HOME/abs/
cp -r /var/abs/community/rtorrent   $HOME/abs/ 
cp -r /var/abs/community/libtorrent $HOME/abs/
cp -r /var/abs/community/xmlrpc-c   $HOME/abs/

chown -R $USER:$USER rtorrent libtorrent xmlrpc-c

#make xmlrpc-c
cd xmlrpc-c && makepkg -s
pacman -U *tar.xz

#make libtorrent
cd ../libtorrent && makepkg -s 
pacman -U *tar.xz

#make rtorrent
cd ../rtorrent && makepkg -s
pacman -U *tar.xz

#make mod_scgi
cd ../mod_scgi && makepkg -s
pacman -U *tar.xz 

echo "Client installed!"
cd $BASE

#add http to daemons
sed -i 's:DAEMONS=(syslog-ng network netfs crond):DAEMONS=(syslog-ng network netfs crond httpd):' /etc/rc.conf

#if that works WOW!
#make some changes to httpd.conf

sed -i 's:DocumentRoot .*:DocumentRoot "/var/www"' /etc/httpd/conf/httpd.conf
sed -i 's:<Directory .*:<Directory "/var/www">'   /etc/httpd/conf/httpd.conf

echo -e "LoadModule php5_module modules/libphp5.so\nLoadModule scgi_module modules/mod_scgi.so" >> /etc/httpd/conf/httpd.conf
echo "Include conf/extra/php5_module.conf" >> /etc/httpd/conf/httpd.conf
echo "SCGIMount /rutorrent/master 127.0.0.1:5000" >> /etc/httpd/conf/httpd.conf

sed -i 's|open_basedir = .*|open_basedir = /srv/http/:/home/:/tmp/:/usr/share/pear/:/var/www/|' /etc/php/php.ini

#that will need some looking into!!

sed -i 's:allow_url_fopen .*:allow_url_fopen = On:'   /etc/php/php.ini
sed -i 's:;extension=sockets.so:extension=sockets.so:' /etc/php/php.ini
sed -i 's:;extension=xmlrpc.so:extension=xmlrpc.so:'   /etc/php/php.ini
