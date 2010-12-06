#!/usr/bin/env bash
trap ctrl_c SIGINT
#trap 'echo "ERROR ON LINE: ${LINENO}"' ERR

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

##################################################################
VERSION='0.9.9~svn'                                              #
DATE='Dec 01 2010'                                               #
##################################################################
source includes/functions.sh  # Source in our functions

##[ Check command line switches ]##
while [ $# -gt 0 ]; do
  	case $1 in
		-p|--pass)  # Generate strong random 'user defined length' passwords
			if [[ $2 ]]; then opt=$2
			else error "Specify Length --pass x ";fi
			mkpass ;;
		-v|--version)  # Output version and date
			echo -e "\n v$VERSION  $DATE \n"
			exit ;;
		*)  # Output usage information
			echo " Invalid Option"
			usage ;;
	esac
done

checkroot

##[ Find Config and Load it ]##
if [[ -f config.ini ]]; then
	source config.ini ; E_=$?
	if [[ $E_ != 0 ]]; then 
		error "config.ini found but not readable!"
	elif [[ $iDiDNTEDiTMYCONFiG ]]; then  # Die if it hasnt been edited
		error "PLEASE EDiT THE CONFiG"
	elif [[ $PWD != $BASE ]]; then  # Check if the user declared BASE correctly in the config
		echo "Wrong Directory Detected..."
		error "Does not match $BASE"
	fi
else error "config.ini not found!"  # Cant continue without a config so produce an error and exit
fi

init

#!=======================>> DiSCLAiMER <<=======================!#
if [[ ! -f $LOG ]]; then  # only show for first run
cat << "EOF"
                      ______
                   .-"      "-.
                  /            \\
                 |              |
                 |,  .-.  .-.  ,|
                 | )(__/  \__)( |
                 |/     /\     \|
       (@_       (_     ^^     _)
  _     ) \_______\__|IIIIII|__/__________________________
 (_)@8@8{}<________|-\IIIIII/-|___________________________>
        )_/        \          /
       (@           '--------'

  WARNING:

  The installation is quite stable and functional when run on a freshly
  installed supported Operating System. Systems that have already had
  these programs installed and/or removed could run into problems, but
  not likely. If you do run into problems, please let us know so we can
  fix it.

  You can update your system along with installing those "must have"
  programs by simply running this script with the --dry option.

  The systems currently supported are:
     Ubuntu [ 9.04 -> 10.10 ]
     Debian [ 5.0  ->  6.0  ]

  If your OS is not listed, this script will most likey explode.
EOF
echo -e " ${undred}_______________________${rst}"
echo -e " Distro:${bldylw} $DISTRO $RELEASE/$NAME ${rst}"
echo -e " Kernel:${bldylw} $KERNEL${rst}-${bldylw}$ARCH ${rst}"

echo -en "\n Continue? [y/n]: "
	if ! yes; then  # Cleanup and die if no
		cleanup ; clear ; exit
	fi
fi
log "\n*** SCRiPT STARTiNG | $(date) ***"

if [[ $DISTRO = 'Arch' ]]; then
	source arch.installer.sh
	exit
fi

if [[ ! -f $REPO_PATH/autoinstaller.list ]]; then
	source includes/repositories.sh  # Add repositories if not already present
else log "Repositories Already Present, skipping"
fi

clear
source includes/questionnaire.sh  # Load questionnaire

#!=====================>> iNSTALLATiON <<=======================!#
echo -e "\n********************************"
echo -e   "****${bldred} BEGiNiNG iNSTALLATiON ${rst}*****"
echo -e   "********************************\n"

mksslcert
base_install

cd $BASE
##[ APACHE ]##
if [[ $http = 'apache' ]]; then
	notice "iNSTALLiNG APACHE"
	$INSTALL apache2 apache2-mpm-prefork libapache2-mod-php5 libapache2-mod-python libapache2-mod-scgi libapache2-mod-suphp suphp-common apachetop 2>> $LOG
	E_=$? ; debug_error "Apache2 failed to install"

	cp modules/apache/scgi.conf /etc/apache2/mods-available/scgi.conf  # Add mountpoint

	a2enmod auth_digest ssl php5 scgi expires deflate mem_cache  # Enable modules
	a2dismod cgi
	a2ensite default-ssl

	sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s:AllowOverride .*:AllowOverride All:' /etc/apache2/sites-available/default*
	sed -i 's:ServerSignature On:ServerSignature Off:' /etc/apache2/apache2.conf
	sed -i 's:Timeout 300:Timeout 30:'                 /etc/apache2/apache2.conf
	sed -i 's:KeepAliveTimeout 15:KeepAliveTimeout 5:' /etc/apache2/apache2.conf
	sed -i 's:ServerTokens Full:ServerTokens Prod:'    /etc/apache2/apache2.conf
	echo   "ServerName $HOSTNAME" >>                   /etc/apache2/apache2.conf

	PHPini=/etc/php5/apache/php.ini
	log "Apache Installation | Completed"
	debug_wait "apache.installed"

##[ LiGHTTPd ]##
elif [[ $http = 'lighttp' ]]; then
	notice "iNSTALLiNG LiGHTTP"
	$INSTALL lighttpd apache2-utils 2>> $LOG
	E_=$? ; debug_error "Lighttpd failed to install"

	if [[ ! -f /etc/lighttpd/server.pem ]]; then  # Create SSL Certificate
		make-ssl-cert $SSLCERT /etc/lighttpd/server.pem
	fi

	cp modules/lighttp/scgi.conf /etc/lighttpd/conf-available/20-scgi.conf        # Add mountpoint and secure it with auth
	cat < modules/lighttp/auth.conf >> /etc/lighttpd/conf-available/05-auth.conf  # apend contents of our auth.conf into lighttp's auth.conf

	lighty-enable-mod scgi fastcgi fastcgi-php auth access accesslog compress ssl # Enable modules

	PHPini=/etc/php5/cgi/php.ini
	log "Lighttp Installation | Completed"
	debug_wait "lighttpd.installed"

##[ Cherokee ]##
elif [[ $http = 'cherokee' ]]; then
	notice "iNSTALLiNG CHEROKEE"
	#if [[ $NAME = 'lenny' ]]; then
	#	$INSTALL cherokee spawn-fcgi 2>> $LOG
	#else
		$INSTALL cherokee libcherokee-mod-libssl libcherokee-mod-rrd libcherokee-mod-admin spawn-fcgi 2>> $LOG
		E_=$? ; debug_error "Cherokee failed to install"
	#fi
	PHPini=/etc/php5/cgi/php.ini
	log "Cherokee Installation | Completed"
	debug_wait "cherokee.installed"

elif [[ $http != @(none|no|[Nn]) ]]; then  # Edit php config
	sed -i 's:memory_limit .*:memory_limit = 128M:'                                    $PHPini
	sed -i 's:error_reporting .*:error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE:' $PHPini
	sed -i 's:expose_php = On:expose_php = Off:'                                       $PHPini
	sed -i 's:display_errors = On:display_errors = Off:'                               $PHPini
	sed -i 's:log_errors = Off:log_errors = On:'                                       $PHPini
	sed -i 's:;error_log .*:error_log = /var/log/php-error.log:'                       $PHPini
fi

##[ vsFTP ]##
if [[ $ftpd = 'vsftp' ]]; then
	notice "iNSTALLiNG vsFTPd"
	$INSTALL vsftpd 2>> $LOG
		E_=$? ; debug_error "vsFTPd failed to install"
	sed -i 's:anonymous_enable.*:anonymous_enable=NO:'           /etc/vsftpd.conf
	sed -i 's:#local_enable.*:local_enable=YES:'                 /etc/vsftpd.conf
	sed -i 's:#write_enable.*:write_enable=YES:'                 /etc/vsftpd.conf
	sed -i 's:#local_umask.*:local_umask=022:'                   /etc/vsftpd.conf
	sed -i 's:#idle_session_timeout.*:idle_session_timeout=600:' /etc/vsftpd.conf
	sed -i 's:#nopriv_user.*:nopriv_user=ftp:'                   /etc/vsftpd.conf
	sed -i 's:#chroot_local_user.*:chroot_local_user=YES:'       /etc/vsftpd.conf

	cat /etc/vsftpd.conf | grep '# added by autoscript' >/dev/null
	if [[ $? = 1 ]]; then
		echo "# added by autoscript"                                       >> /etc/vsftpd.conf
		echo "rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem"          >> /etc/vsftpd.conf
		echo "rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key" >> /etc/vsftpd.conf
		echo "ssl_enable=YES" >> /etc/vsftpd.conf
		echo "ssl_tlsv1=YES"  >> /etc/vsftpd.conf
		echo "ssl_sslv2=NO"   >> /etc/vsftpd.conf
		echo "ssl_sslv3=YES"  >> /etc/vsftpd.conf

		read -p "Force SSL? [y/n]: " vsftpfssl
		if [[ $vsftpfssl = 'y' ]]; then
			echo "force_local_logins_ssl=YES" >> /etc/vsftpd.conf
			echo "force_local_data_ssl=YES"   >> /etc/vsftpd.conf
		fi
	else
		log "vsftpd config already edited, skipping"
	fi

	log "vsFTP Installation | Completed"
	debug_wait "vsftpd.installed"

##[ proFTP ]##
elif [[ $ftpd = 'proftp' ]]; then
	notice "iNSTALLiNG proFTPd"
	$INSTALL proftpd-basic 2>> $LOG
		E_=$? ; debug_error "ProFTPd failed to install"
	sed -i 's:#DefaultRoot .*:DefaultRoot ~:' /etc/proftpd/proftpd.conf

	log "ProFTP Installation | Completed"
	debug_wait "proftpd.installed"

##[ pureFTP ]##
elif [[ $ftpd = 'pureftp' ]]; then
	notice "iNSTALLiNG Pure-FTPd"
	$INSTALL pure-ftpd pure-ftpd-common 2>> $LOG
	E_=$? ; debug_error "PureFTP failed to install"

	debug_wait "Creating PureFTP SSL Key"
	echo 1 > /etc/pure-ftpd/conf/TLS  # Enable TLS+FTP (2 will allow TLS only, 0 disables it)
	if [[ ! -f /etc/ssl/private/pure-ftpd.pem ]]; then  # Create SSL Certificate
		mkdir -p /etc/ssl/private && make-ssl-cert $SSLCERT /etc/ssl/private/pure-ftpd.pem
		chmod 600 /etc/ssl/private/pure-ftpd.pem  # Read write permission for owner only
		log "PureFTP SSL Key created"
	fi
	sed -i 's:STANDALONE_OR_INETD=.*:STANDALONE_OR_INETD=standalone:' /etc/default/pure-ftpd-common
	/etc/init.d/pure-ftpd restart

	log "PureFTP Installation | Completed"
	debug_wait "pureftp.installed"
fi

##[ mySQL ]##
if [[ $sql = 'mysql' ]]; then
	notice "iNSTALLiNG MySQL"
	if [[ $DISTRO = 'Ubuntu' && $NAME != 'hardy' ]]; then
		$INSTALL mysql-server mysql-client libmysqlclient16-dev mysql-common mytop 2>> $LOG && E_=$?
	elif [[ $DISTRO = 'Debian' || $NAME = 'hardy' ]]; then
		$INSTALL mysql-server mysql-client libmysqlclient15-dev mysql-common mytop 2>> $LOG && E_=$?
	fi

	sed -ie 's:query_cache_limit .*:query_cache_limit = 2M\nquery_cache_type = 1:' /etc/mysql/my.cnf

	debug_error "MySQL failed to install"
	log "MySQL Installation | Completed"
	debug_wait "mysql.installed"

##[ SQLiTE ]##
elif [[ $sql = 'sqlite' ]]; then
	notice "iNSTALLiNG SQLite"
	$INSTALL sqlite3 php5-sqlite 2>> $LOG
	E_=$? ; debug_error "SQLite failed to install"
	log "SQLite Installation | Completed"
	debug_wait "sqlite.installed"

##[ PostGreSQL ]##
elif [[ $sql = 'postgre' ]]; then
	notice "iNSTALLiNG PostgreSQL"
	$INSTALL postgresql postgresql-client-common postgresql-common 2>> $LOG
	E_=$? ; debug_error "PostgreSQL failed to install"
	log "PostgreSQL Installation | Completed"
	debug_wait "postgresql.installed"
fi

##[ Bouncers ]##
cd $BASE
if [[ $bnc != @(none|no|[Nn]) ]]; then
	$INSTALL libc-ares-dev tcl tcl-dev 2>> $LOG
	E_=$? ; debug_error "Required packages failed to install"
fi

##[ ZNC ]##
if [[ $bnc = 'znc' ]]; then
	notice "iNSTALLiNG ZNC"
	cd tmp/
	download http://downloads.sourceforge.net/project/znc/znc/0.094/znc-0.094.tar.gz
		debug_error "ZNC Download Failed"
	extract znc-0.094.tar.gz && cd znc-0.094  # Unpack
		log "ZNC | Downloaded + Unpacked"
	notice "Be aware that compiling znc is a cpu intensive task and may take up to 10 min to complete"
	sleep 3
	sh configure --enable-extra
	compile
		debug_error "ZNC Build Failed"
		log "ZNC Compile | Completed in $compile_time seconds"
		debug_wait "znc.compiled"
	make install
		log "ZNC Installation | Completed"
	notice "Starting znc for first time ${rst}"
	cd $HOME
	sudo -u $USER znc --makeconf	

##[ sBNC ]##
elif [[ $bnc = 'sbnc' ]]; then
	cd tmp
	notice "iNSTALLiNG ShroudBNC"
	$INSTALL swig 2>> $LOG
	git clone -q http://github.com/gunnarbeutner/shroudbnc.git
	git clone -q http://github.com/gunnarbeutner/sBNC-Webinterface.git
	chown -R $USER:$USER shroudbnc sBNC-Webinterface
		log "ShroudBNC | Downloaded"
	cd shroudbnc
	sudo -u $USER sh autogen.sh
	sudo -u $USER sh configure
	sudo -u $USER make -j$CORES
		debug_error "ShroudBNC Build Failed"
		log "ShroudBNC Compile | Completed in $compile_time seconds"
	sudo -u $USER make install

	notice "Starting sbnc for first time... ${rst}"
	cd $HOME/sbnc
	sh sbnc
	log "ShroudBNC Installation | Completed"

##[ psyBNC ]##
elif [[ $bnc = 'psybnc' ]]; then
	cd $HOME
	notice "iNSTALLiNG PsyBNC"
	download http://psybnc.org.uk/psyBNC-2.3.2-10.tar.gz
		debug_error "PsyBNC Download Failed"
	extract psyBNC-2.3.2-10.tar.gz
	chown -R $USER:$USER psybnc
		log "PsyBNC | Downloaded + Unpacked"

	cd psybnc
	sudo -u $USER make menuconfig
	sudo -u $USER make -j$CORES
		debug_error "PsyBNC Build Failed"
		log "PsyBNC Compile | Completed in $compile_time seconds"
	log "PsyBNC Installation | Completed"
	notice "Installed to ~/psybnc"
fi

##[ WebMiN ]##
cd $BASE
if [[ $webmin = 'y' ]]; then
	notice "iNSTALLiNG WEBMiN"
	$INSTALL webmin libauthen-pam-perl libio-pty-perl libnet-ssleay-perl libpam-runtime 2>> $LOG
	E_=$? ; debug_error "Webmin failed to install"
		log "WebMin Installation | Completed"
		debug_wait "webmin.installed"
fi

##[ vnStat ]##
cd $BASE/tmp
if [[ $vnstat = 'y' ]]; then
	notice "iNSTALLiNG VNSTAT"
	$INSTALL libgd2-xpm libgd2-xpm-dev 2>> $LOG
	git clone -q git://github.com/bjd/vnstat-php-frontend.git vnstat-web  # Checkout VnStat-Web
	download http://humdi.net/vnstat/vnstat-1.10.tar.gz                   # Download VnStat

	extract vnstat-1.10.tar.gz && cd vnstat-1.10                          # Unpack
	compile
		debug_error "VnStat Build Failed"
		log "VnStat Compile | Completed in $compile_time seconds"
		debug_wait "vnstat.compiled"
	make install && cd ..                                                 # Install
		log "VnStat Installation | Completed"

	if [[ ! -f /etc/init.d/vnstat ]]; then
		cp vnstat-1.10/examples/init.d/debian/vnstat /etc/init.d/         # Copy init script if one doesnt exist
		chmod a+x /etc/init.d/vnstat && update-rc.d vnstat defaults       # Start at boot
		log "VnStat | Created Init Script"
	else log "VnStat | Previous Init Script Found, skipping..."
	fi

	sed -i "s:UnitMode 0:UnitMode 1:"               /etc/vnstat.conf  # Use MB not MiB
	sed -i "s:RateUnit 1:RateUnit 0:"               /etc/vnstat.conf  # Use bytes not bits
	sed -i "s:UpdateInterval 30:UpdateInterval 60:" /etc/vnstat.conf  # Increase daemon checks
	sed -i "s:PollInterval 5:PollInterval 10:"      /etc/vnstat.conf  # ^^^^^^^^ ^^^^^^ ^^^^^^
	sed -i "s:SaveInterval 5:SaveInterval 10:"      /etc/vnstat.conf  # Less saves to disk
	sed -i "s:UseLogging 2:UseLogging 1:"           /etc/vnstat.conf  # Log to file instead of syslog

	rm -rf vnstat-web/themes/espresso vnstat-web/themes/light vnstat-web/themes/red                # Remove extra themes
	rm -rf vnstat-web/COPYING vnstat-web/vera_copyright.txt vnstat-web/config.php vnstat-web/.git  # Remove extra files

	cp ../modules/vnstat/config.php vnstat-web
	sed -i "s|\$iface_list = .*|\$iface_list = array('$iFACE');|" vnstat-web/config.php  # Edit web config

	mv vnstat-web $WEB  # Copy VnStat-web to WebRoot
		 log "Frontend Installed | http://$iP/vnstat-web"

	if [[ ! $(pidof vnstatd) ]]; then
		vnstat -u -i $iFACE  # Make interface database
		vnstatd -d           # Start daemon
	fi
	debug_wait "vnstat-web.installed"
fi

##[ phpSysInfo ]##
cd $BASE/tmp
if [[ $phpsysinfo = 'y' ]]; then
	notice "iNSTALLiNG phpSysInfo"
	#checkout https://phpsysinfo.svn.sourceforge.net/svnroot/phpsysinfo/trunk phpsysinfo
	download http://downloads.sourceforge.net/project/phpsysinfo/phpsysinfo/3.0.7/phpsysinfo-3.0.7.tar.gz
	extract phpsysinfo-3.0.7.tar.gz
	cd phpsysinfo
	rm ChangeLog COPYING README README_PLUGIN 
	cp config.php.new config.php

	sed -i "s:define('PSI_PLUGINS'.*:define('PSI_PLUGINS', 'PS,PSStatus,Quotas,SMART');:"  config.php
	sed -i "s:define('PSI_TEMP_FORMAT'.*:define('PSI_TEMP_FORMAT', 'c-f');:"                        config.php
	sed -i "s:define('PSI_DEFAULT_TEMPLATE',.*);:define('PSI_DEFAULT_TEMPLATE', 'nextgen');:"       config.php

	cd ..
	mv phpsysinfo $WEB 
	log "phpSysInfo Installation | Completed"
fi

##[ SABnzbd ]##
cd $BASE/tmp
if [[ $sabnzbd = 'y' ]]; then
	notice "iNSTALLiNG SABnzbd"
	$INSTALL sabnzbdplus par2 python-cheetah python-dbus python-yenc sabnzbdplus-theme-classic sabnzbdplus-theme-plush sabnzbdplus-theme-smpl 2>> $LOG
	E_=$? ; debug_error "Sabnzbd failed to install"

	# Install par2cmdline 0.4 with Intel Threading Building Blocks
	if [[ $ARCH = 'x86_64' ]]; then download http://chuchusoft.com/par2_tbb/par2cmdline-0.4-tbb-20100203-lin64.tar.gz
	else download http://chuchusoft.com/par2_tbb/par2cmdline-0.4-tbb-20090203-lin32.tar.gz
	fi ; extract par2cmdline-0.4*.tar.gz && cd par2cmdline-0.4*
	mv libtbb.so libtbb.so.2 par2 /usr/bin ; cd ..

	#if [[ $NAME = 'lenny' ]]; then
	#	libjs-mochikit >= 1.4
	#fi

	#read -p "  User Name that will run SABnzbd: " SABuser
	sabnzbd_conf=/home/$USER/.sabnzbd/sabnzbd.ini
	sabnzbd_init=/etc/default/sabnzbdplus

	sed -i "s:USER.*:USER=$USER:"   $sabnzbd_init
	sed -i "s:HOST.*:HOST=0.0.0.0:" $sabnzbd_init
	sed -i "s:PORT.*:PORT=8080:"    $sabnzbd_init
	/etc/init.d/sabnzbdplus start && /etc/init.d/sabnzbdplus stop  # Create config in user's home

	sed -i "s:host .*:host = $iP:"  $sabnzbd_conf
	if [[ $CORES < 2 ]]; then
	sed -i "s:par2_multicore .*:par2_multicore = 0:" $sabnzbd_conf
	fi

	/etc/init.d/sabnzbdplus start  # Start 'er up

	log "SABnzbd Installation | Completed"
	log "SABnzbd Started and Running at http://$iP:8080"
	debug_wait "SABnzbd.installed"
fi

##[ iPLiST ]##
cd $BASE/tmp
if [[ $ipblock = 'y' ]]; then
	notice "iNSTALLiNG iPBLOCK"
	if [[ $NAME = 'lenny' ]]; then
		apt-get -t squeeze install libpcre3 libnfnetlink0 libnetfilter-queue1 2>> $LOG  # Install updated libraries for lenny support
	fi
	$INSTALL iplist 2>> $LOG
	E_=$? ; debug_error "iPBLOCK failed to install"

	PATH_iplist=/etc/ipblock.conf
	filters='level1.gz'
	sed -i "s:AUTOSTART=.*:AUTOSTART=\"Yes\":"        $PATH_iplist
	sed -i "s:BLOCK_LIST=.*:BLOCK_LIST=\"$filters\":" $PATH_iplist

	echo -en "${bldred} Updating block lists...${rst}"
	ipblock -u && echo -e "${bldylw} done ${rst}"
	/etc/init.d/ipblock start

	log "iPBLOCK Installation | Completed"
	debug_wait "ipblock.installed"
fi

if [[ $torrent = @(rtorrent|tranny|deluge) ]]; then
echo -e "\n*******************************"
echo -e   "**${bldred} TORRENT CLiENT iNSTALLiNG ${rst}**"
echo      "*******************************"
fi

cd $BASE/tmp
if [[ $buildtorrent = 'b' ]]; then
#-->##[ BuildTorrent ]##
	notice "iNSTALLiNG BuildTorrent"
	if [[ ! -d buildtorrent ]]; then  # Checkout latest BuildTorrent source
		git clone -q git://gitorious.org/buildtorrent/buildtorrent.git ; E_=$?
		debug_error "BuildTorrent Download Failed"
		log "BuildTorrent | Downloaded"
	fi

	cd buildtorrent
	aclocal
	autoconf
	autoheader
	automake -a -c
	sh configure
	make install ; E=$?

	debug_error "BuildTorrent Build Failed"
	log "BuildTorrent Installation | Completed"
	debug_wait "buildtorrent.installed"

elif [[ $buildtorrent != 'n' ]]; then
#-->##[ mkTorrent ]##
if [[ ! -f /usr/local/bin/mktorrent || $buildtorrent = 'm' ]]; then
	notice "iNSTALLiNG MkTorrent"
	if [[ ! -d mktorrent ]]; then  # Checkout latest mktorrent source
		git clone -q git://github.com/esmil/mktorrent.git
		E_=$? ; debug_error "MkTorrent Download Failed"
		log "MkTorrent | Downloaded"
	fi

	cd mktorrent
	make install ; E_=$?

	debug_error "MkTorrent Build Failed"
	log "MkTorrent Installation | Completed"
	debug_wait "mktorrent.installed"
fi
fi

cd $BASE
##[ rTorrent ]##
if [[ $torrent = 'rtorrent' ]]; then source modules/rtorrent/install.sh
##[ Transmission ]##
elif [[ $torrent = 'tranny' ]]; then source modules/transmission/install.sh
##[ Deluge ]##
elif [[ $torrent = 'deluge' ]]; then source modules/deluge/install.sh
fi
##[ ruTorrent ]##
if [[ $webui = 'y' ]]; then source modules/rutorrent/install.sh ;fi

##[TODO][ uTorrent alpha ]##
#if [[ ${utorrent} = 'y' ]]; then
#	source modules/utorrent/install.sh
#fi

source $BASE/includes/postprocess.sh
echo -e "\n*******************************"
echo -e   "******${bldred} SCRiPT COMPLETED! ${rst}******"
echo -e   "****${bldred} FiNiSHED iN ${bldylw}$SECONDS ${bldred}SECONDS ${rst}**"
echo -e   "*******************************\n"
log "*** SCRiPT COMPLETED | $(date) ***\n<---------------------------------> \n"
exit
