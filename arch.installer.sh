#!/usr/bin/env bash

ARCH RTORRENT INSTALL

!install francharc repo and sys upgrade install yaourt
!add to the end of /etc/pacman.conf

[archlinuxfr] 
Server = http://repo.archlinux.fr/$arch

pacman -Syu yaourt

!install rtorrent and apache as of https://wiki.archlinux.org/index.php/Rtgui saves compiling right?

pacman -S rtorrent apache php php-apache

!install mod_scgi

yaourt -S mod_scgi

CONFIGUATION APACHE PHP

!base for apache configs is /etc/httpd/conf/httpd.conf

!we add as lines 121, 122

LoadModule php5_module modules/libphp5.so
LoadModule scgi_module modules/mod_scgi.so

!change line 173 from DocumentRoot "/src/http" to read

DocumentRoot "/var/www"

!Change line 200 from <Directory "/src/http">

<Directory "/var/www">

//just to localise the rutorrent scripts

!add as lines 468, 469

# PHP Config
Include conf/extra/php5_module.conf

!add SCGIMount to the end

SCGIMount /RPC2 127.0.0.1:5000

//line 483 in my conf

!php conf in /etc/php/php.ini
!add to line 379 /var/www/
!so it reads as

open_basedir = /srv/http/:/home/:/tmp/:/usr/share/pear/:/var/www/

!change line 890 from  allow_url_fopen = Off to read

allow_url_fopen = On

!remove the ; from lines 974, 981

;extension=sockets.so
;extension=xmlrpc.so

//read as before changes

!restart apche

/etc/rc.d/httpd restart

!install rutorrent from he is the same as before.

ADDING HTTPD TO DAEMONS
!this can be done in /etc/rc.conf
!line 97 newly installed deamon line reads

DAEMONS=(syslog-ng network netfs crond)

!mine reads just need to add httpd before the )

DAEMONS=(syslog-ng dbus hal network netfs crond alsa gdm httpd)

//add to daemons to load at boot


LEGAND
! = subtitles
// = little comments
