#!/usr/bin/env bash
#set -x

#add yaourt repo
echo "[archlinuxfr]"                           >> /etc/pacman.conf
echo 'Server = http://repo.archlinux.fr/$arch' >> /etc/pacman.conf

#install base and stuffs
pacman -Syu --noconfirm base-devel fakeroot yaourt apache php php-apache

#grab rtorrent and depends PKGBUILD

mkdir -p /home/$USER/tmp
cd /home/$USER/tmp

sudo -u $USER yaourt -G mod_scgi rtorrent libtorrent xmlrpc-c #can use other AUR tools, but ATM yaourt seems the easies

#make xmlrpc-c
cd xmlrpc-c && sudo -u $USER makepkg -s --noconfirm
pacman -U --noconfirm *tar.xz

#make libtorrent
cd ../libtorrent && sudo -u $USER makepkg -s --noconfirm
pacman -U --noconfirm *tar.xz

#make rtorrent
cd ../rtorrent && sudo -u $USER makepkg -s --noconfirm
pacman -U --noconfirm *tar.xz

#make mod_scgi
cd ../mod_scgi && sudo -u $USER makepkg -s --noconfirm
pacman -U --noconfirm *tar.xz

ldconfig #just to play it safe link shared libs
echo "Client installed!"

#add http to daemons
echo -e "/etc/rc.d/httpd start" >> /etc/rc.local

#Setup httpd
echo -e "LoadModule php5_module modules/libphp5.so"  >> /etc/httpd/conf/httpd.conf
echo -e "LoadModule scgi_module modules/mod_scgi.so" >> /etc/httpd/conf/httpd.conf
echo -e "Include conf/extra/php5_module.conf"        >> /etc/httpd/conf/httpd.conf
echo -e "SCGIMount /rutorrent/master 127.0.0.1:5000" >> /etc/httpd/conf/httpd.conf

sed -i 's/User http/User www-data/'                                /etc/httpd/conf/httpd.conf
sed -i 's/Group http/Group www-data/'                              /etc/httpd/conf/httpd.conf
sed -i 's/DocumentRoot \"\/srv\/httpd"/DocumentRoot "\/var\/www"/' /etc/httpd/conf/httpd.conf
sed -i 's/<Directory \"\/srv\/httpd"/<Directory \"\/var\/www">/'   /etc/httpd/conf/httpd.conf

#configure php
sed -i 's/;extension=sockets.so/extension=sockets.so/' /etc/php/php.ini
sed -i 's/;extension=xmlrpc.so/extension=xmlrpc.so/'   /etc/php/php.ini
sed -i 's/open_basedir = \/srv\/http\/:\/home\/:\/tmp\/:\/usr\/share\/pear\//open_basedir = \/srv\/http\/:\/home\/:\/tmp\/:\/usr\/share\/pear\/:\/var\/www\//' /etc/php/php.ini

#remove http and add www-data as apache user
mkdir /var/www
useradd --home-dir /var/www --system --shell /bin/false www-data
chown -R www-data:www-data /var/www
userdel http

#start apcahe
/etc/rc.d/httpd start

