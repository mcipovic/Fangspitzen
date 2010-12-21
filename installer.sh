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
VERSION='0.9.9~git'                                              #
DATE='Dec 08 2010'                                               #
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
	else log "\n*** SCRiPT STARTiNG | $(date) ***"
	fi
fi  # end `if ! $LOG`

if [[ $DISTRO = 'Arch' ]]; then
	source arch.installer.sh
	exit
fi

if [[ $DISTRO = 'SUSE Linux' ]]; then
#	source suse.installer.sh
	exit
fi

if [[ ! -f $REPO_PATH/autoinstaller.list ]]; then
	source $BASE/includes/repositories.sh  # Add repositories if not already present
else log "Repositories Already Present, skipping"
fi

clear
source $BASE/includes/questionnaire.sh  # Load questionnaire

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
	packages install $PHP apache2 apache2-mpm-prefork libapache2-mod-php5 libapache2-mod-python libapache2-mod-scgi libapache2-mod-suphp suphp-common apachetop 2>> $LOG
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
	log "Apache Installation | Completed" ; debug_wait "apache.installed"

##[ LiGHTTPd ]##
elif [[ $http = 'lighttp' ]]; then
	notice "iNSTALLiNG LiGHTTP"
	packages install $PHP lighttpd apache2-utils 2>> $LOG
	E_=$? ; debug_error "Lighttpd failed to install"

	if [[ ! -f /etc/lighttpd/server.pem ]]; then  # Create SSL Certificate
		make-ssl-cert $SSLCERT /etc/lighttpd/server.pem
	fi

	cp modules/lighttp/scgi.conf /etc/lighttpd/conf-available/20-scgi.conf        # Add mountpoint and secure it with auth
	cat < modules/lighttp/auth.conf >> /etc/lighttpd/conf-available/05-auth.conf  # apend contents of our auth.conf into lighttp's auth.conf

	lighty-enable-mod scgi fastcgi fastcgi-php auth access accesslog compress ssl # Enable modules

	PHPini=/etc/php5/cgi/php.ini
	log "Lighttp Installation | Completed" ; debug_wait "lighttpd.installed"

##[ Cherokee ]##
elif [[ $http = 'cherokee' ]]; then
	notice "iNSTALLiNG CHEROKEE"
	#if [[ $NAME = 'lenny' ]]; then
	#	packages install cherokee spawn-fcgi 2>> $LOG
	#else
		packages install $PHP cherokee libcherokee-mod-libssl libcherokee-mod-rrd libcherokee-mod-admin spawn-fcgi 2>> $LOG
		E_=$? ; debug_error "Cherokee failed to install"
	#fi
	PHPini=/etc/php5/cgi/php.ini
	log "Cherokee Installation | Completed" ; debug_wait "cherokee.installed"

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
	packages install vsftpd 2>> $LOG
	E_=$? ; debug_error "vsFTPd failed to install"
	sed -i 's:anonymous_enable.*:anonymous_enable=NO:'           /etc/vsftpd.conf
	sed -i 's:#local_enable.*:local_enable=YES:'                 /etc/vsftpd.conf
	sed -i 's:#write_enable.*:write_enable=YES:'                 /etc/vsftpd.conf
	sed -i 's:#local_umask.*:local_umask=022:'                   /etc/vsftpd.conf
	sed -i 's:#idle_session_timeout.*:idle_session_timeout=600:' /etc/vsftpd.conf
	sed -i 's:#nopriv_user.*:nopriv_user=ftp:'                   /etc/vsftpd.conf
	sed -i 's:#chroot_local_user.*:chroot_local_user=YES:'       /etc/vsftpd.conf

	cat /etc/vsftpd.conf | grep '# added by autoscript' >/dev/null
	if [[ $? != 0 ]]; then  # Check if this has already been added or not
		echo "# added by autoscript"                                       >> /etc/vsftpd.conf
		echo "rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem"          >> /etc/vsftpd.conf
		echo "rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key" >> /etc/vsftpd.conf
		echo "force_local_logins_ssl=NO" >> /etc/vsftpd.conf
		echo "force_local_data_ssl=NO"   >> /etc/vsftpd.conf
		echo "ssl_enable=YES" >> /etc/vsftpd.conf
		echo "ssl_tlsv1=YES"  >> /etc/vsftpd.conf
		echo "ssl_sslv2=NO"   >> /etc/vsftpd.conf
		echo "ssl_sslv3=YES"  >> /etc/vsftpd.conf
	else
		log "vsftpd config already edited, skipping"
	fi

	echo -n "Force SSL? [y/n]: "
	if yes; then  # allow toggling of forcing ssl
		sed -i 's:force_local_logins_ssl.*:force_local_logins_ssl=YES:' /etc/vsftpd.conf
		sed -i 's:force_local_data_ssl.*:cforce_local_data_ssl=YES:'    /etc/vsftpd.conf
	else
		sed -i 's:force_local_logins_ssl.*:force_local_logins_ssl=NO:'  /etc/vsftpd.conf
		sed -i 's:force_local_data_ssl.*:cforce_local_data_ssl=NO:'     /etc/vsftpd.conf
	fi

	log "vsFTP Installation | Completed" ; debug_wait "vsftpd.installed"

##[ proFTP ]##
elif [[ $ftpd = 'proftp' ]]; then
	notice "iNSTALLiNG proFTPd"
	packages install proftpd-basic 2>> $LOG
		E_=$? ; debug_error "ProFTPd failed to install"
	sed -i 's:#DefaultRoot .*:DefaultRoot ~:' /etc/proftpd/proftpd.conf

	log "ProFTP Installation | Completed" ; debug_wait "proftpd.installed"

##[ pureFTP ]##
elif [[ $ftpd = 'pureftp' ]]; then
	notice "iNSTALLiNG Pure-FTPd"
	packages install pure-ftpd pure-ftpd-common 2>> $LOG
	E_=$? ; debug_error "PureFTP failed to install"

	echo -n "Force SSL? [y/n]: "
	if ! yes; then  # allow toggling of forcing ssl
		echo 1 > /etc/pure-ftpd/conf/TLS  # Allow TLS+FTP
	else
		echo 2 > /etc/pure-ftpd/conf/TLS  # Force TLS
	fi

	if [[ ! -f /etc/ssl/private/pure-ftpd.pem ]]; then  # Create SSL Certificate
		mkdir -p /etc/ssl/private && make-ssl-cert $SSLCERT /etc/ssl/private/pure-ftpd.pem
		chmod 600 /etc/ssl/private/pure-ftpd.pem  # Read write permission for owner only
		log "PureFTP SSL Key created"
	fi
	sed -i 's:STANDALONE_OR_INETD=.*:STANDALONE_OR_INETD=standalone:' /etc/default/pure-ftpd-common
	/etc/init.d/pure-ftpd restart

	log "PureFTP Installation | Completed" ; debug_wait "pureftp.installed"
fi

if [[ $buildtorrent = 'b' ]]; then
#-->##[ BuildTorrent ]##
cd $BASE/tmp
	notice "iNSTALLiNG BuildTorrent"
	if [[ ! -d buildtorrent ]]; then  # Checkout latest BuildTorrent source
		git clone -q git://gitorious.org/buildtorrent/buildtorrent.git ; E_=$?
		debug_error "BuildTorrent Download Failed" ; log "BuildTorrent | Downloaded"
	fi

	cd buildtorrent
	aclocal
	autoconf
	autoheader
	automake -a -c
	sh configure
	make install

	E=$? ; debug_error "BuildTorrent Build Failed"
	log "BuildTorrent Installation | Completed" ; debug_wait "buildtorrent.installed"

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
	make install

	E_=$? ; debug_error "MkTorrent Build Failed"
	log "MkTorrent Installation | Completed" ; debug_wait "mktorrent.installed"
fi
fi  # end `if $buildtorrent`

cd $BASE
##[ Torrent Clients ]##
if [[ $torrent = 'rtorrent' ]]; then source modules/rtorrent/install.sh
elif [[ $torrent = 'tranny' ]]; then source modules/transmission/install.sh
elif [[ $torrent = 'deluge' ]]; then source modules/deluge/install.sh
fi

##[ ruTorrent ]##
if [[ $webui = 'y' ]]; then source modules/rutorrent/install.sh
fi

##[ Extras ]##
if [[ $extras = true ]]; then
	source modules/extras.sh
fi

source $BASE/includes/postprocess.sh

echo -e "\n*******************************"
echo -e   "******${bldred} SCRiPT COMPLETED! ${rst}******"
echo -e   "****${bldred} FiNiSHED iN ${bldylw}$SECONDS ${bldred}SECONDS ${rst}**"
echo -e   "*******************************\n"
log "*** SCRiPT COMPLETED | $(date) ***\n<---------------------------------> \n"
exit
