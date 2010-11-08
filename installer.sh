#!/usr/bin/env bash
trap ctrl_c SIGINT

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
DATE='Oct 22 2010'                                               #
##################################################################
source includes/functions.sh  # Source in our functions

##[ Check command line switches ]##
while [ $# -gt 0 ]; do
  	case $1 in
		-p|--pass)  # Generate strong random 'user defined length' passwords
			if [[ $2 ]]; then opt=$2
			else error "Specify Length --pass x "
			fi
			mkpass ;;
		-v|--version)  # Output version and date
			echo -e "\n v$VERSION  $DATE \n"
			exit 0 ;;
		*)  # Output usage information
			echo " Invalid Option"
			usage ;;
	esac
done

##[ Find Config and Load it ]##
if [[ -f config.ini ]]; then  # Die if no config..
	source config.ini
	E_=$?
	if [[ ${E_} != 0 ]]; then
		error "config.ini found but not readable!"
	elif [[ ${iDiDNTEDiTMYCONFiG} ]]; then  # ..or if it hasnt been edited
		error "PLEASE EDiT THE CONFiG"
	elif [[ ${PWD} != ${BASE} ]]; then  # Check if the user declared BASE correctly in the config
		echo -e "--> ${bldred}Fatal Error: Wrong Directory Detected.${rst}"
		echo -e "--> ${bldred}Does not match ${BASE}${rst}"
		exit 1
	fi ;clear
	checkroot
	readonly USER CORES BASE WEB HOME=/home/${USER} LOG=$BASE/$LOG  # Make sure these aren't overwritten
	init  # If user is root lets begin
else
	error "config.ini not found!"
fi

#[TODO] Reserved for future ##
#
# if ! which dialog >/dev/null; then
# 	 echo -n ">>> Installing Dialog Module..."
# 	 $INSTALL dialog 2>> ${LOG}
#	 echo -e "[${bldylw} done ${rst}]"
# elif which dialog >/dev/null; then
#	 echo -e "[${bldylw} done ${rst}]"
# fi
#

#!=======================>> DiSCLAiMER <<=======================!#
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
  installed supported Operating System, but upgrades from systems that 
  have already had these programs installed and/or removed will likely
  run into problems (not so much the case anymore).

  You can update your system along with installing those "must have"
  programs by running this script with no options selected.

  The systems currently supported are:
     Ubuntu >> 9 Jaunty,Karmic >> 10 Lucid,Maverick
     Debian >> 5 Lenny >> 6 Squeeze

  If your OS is not listed, this script will most likey explode.
EOF

get_varinfo

echo -en "\n Continue? [y/n]: "
if ! yesno; then  # Cleanup and die if no
	cleanup && clear
	exit 0 
fi

readonly REPO_PATH=/etc/apt/sources.list.d/
if [[ ! -f ${REPO_PATH}/autoinstaller.list ]]; then
	source includes/repositories.sh  # Add repositories if not already present
else log "Repositories Already Present, skipping"
fi

##[ Load Questionnaire ]##
source includes/questionnaire.sh

#!=====================>> iNSTALLATiON <<=======================!#
echo -e "\n********************************"
echo -e   "****${bldred} BEGiNiNG iNSTALLATiON ${rst}*****"
echo -e   "********************************\n"

notice "iNSTALLiNG BASE PACKAGES... this may take a while"
base_install
	echo -e "${bldylw} done ${rst}"
	debug_wait "base.packages.installed"

sed -i 's:default_bits .*:default_bits = 2048:' $SSLEAYCNF  # Bump 1024=>2048 bit certs

cd $BASE
##[ APACHE ]##
if [[ ${http} = 'apache' ]]; then
	notice "iNSTALLiNG APACHE"
	$INSTALL apache2 libapache2-mod-python libapache2-mod-scgi libapache2-mod-suphp suphp-common apachetop 2>> ${LOG}
	E_=$? && debug_error "Apache2 failed to install"

	if [[ ! -f /etc/apache2/ssl/private.key ]]; then  # Create SSL Certificate
		mkdir -p /etc/apache2/ssl && make-ssl-cert $SSLEAYCNF /etc/apache2/ssl/private.key
		chmod 600 /etc/apache2/ssl/private.key  # Read write permission for owner only
	fi
	if [[ ! -f /etc/apache2/mods-available/scgi.conf ]]; then  # Add RPC Mountpoint
		cp modules/apache/scgi.conf /etc/apache2/mods-available/scgi.conf
	fi
	a2enmod auth_digest ssl php5 scgi expires deflate cache mem_cache && a2dismod cgi  # Enable Modules

	PHPini=/etc/php5/apache/php.ini
	log "Apache Installation | Completed"
	debug_wait "apache.installed"

##[ LiGHTTPd ]##
elif [[ ${http} = 'lighttp' ]]; then
	notice "iNSTALLiNG LiGHTTP"
	$INSTALL lighttpd apache2-utils 2>> ${LOG}
	E_=$? && debug_error "Lighttpd failed to install"

	lighty-enable-mod fastcgi ssl auth access accesslog compress # Enable Modules
	if [[ ! -f /etc/lighttpd/ssl/server.pem ]]; then  # Create SSL Certificate
		mkdir -p /etc/apache2/ssl && make-ssl-cert $SSLEAYCNF /etc/lighttpd/ssl/server.pem
		chmod 600 /etc/lighttpd/ssl/server.pem  # Read write permission for owner only
	fi
	if [[ ! -f /etc/lighttpd/conf-available/99-scgi.conf ]]; then  # Add RPC Mountpoint
		cp modules/lighttp/99-scgi.conf /etc/lighttpd/conf-available/99-scgi.conf
	fi
	PHPini=/etc/php5/cgi/php.ini
	log "Lighttp Installation | Completed"
	debug_wait "lighttpd.installed"

##[ Cherokee ]##
elif [[ ${http} = 'cherokee' ]]; then
	notice "iNSTALLiNG CHEROKEE"
	#if [[ $NAME = 'lenny' ]]; then
	#	$INSTALL cherokee spawn-fcgi 2>> ${LOG} && E_=$?
	#else
		$INSTALL cherokee libcherokee-mod-libssl libcherokee-mod-mysql libcherokee-mod-rrd libcherokee-mod-admin spawn-fcgi 2>> ${LOG}
		E_=$? && debug_error "Cherokee failed to install"
	#fi
	PHPini=/etc/php5/cgi/php.ini
	log "Cherokee Installation | Completed"
	debug_wait "cherokee.installed"

elif [[ ${http} != @(none|no|[Nn]) ]]; then  # Edit php config
	sed -i 's:memory_limit .*:memory_limit = 128M:'                                    $PHPini
	sed -i 's:error_reporting .*:error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE:' $PHPini
	sed -i 's:expose_php = On:expose_php = Off:'                                       $PHPini
	sed -i 's:display_errors = On:display_errors = Off:'                               $PHPini
	sed -i 's:log_errors = Off:log_errors = On:'                                       $PHPini
	sed -i 's:;error_log .*:error_log = /var/log/php-error.log:'               $PHPini
fi

##[ vsFTP ]##
if [[ ${ftpd} = 'vsftp' ]]; then
	notice "iNSTALLiNG vsFTPd"
	$INSTALL vsftpd 2>> ${LOG}
		E_=$? && debug_error "vsFTPd failed to install"
	sed -i 's:anonymous_enable=YES:anonymous_enable=NO:' /etc/vsftpd.conf
	sed -i 's:#local_enable .*:local_enable=YES:'        /etc/vsftpd.conf
	sed -i 's:#write_enable .*:write_enable=YES:'        /etc/vsftpd.conf
	sed -i 's:#local_umask .*:local_umask=022:'          /etc/vsftpd.conf
	sed -i 's:#idle_session_timeout .*:idle_session_timeout=600:' /etc/vsftpd.conf
	sed -i 's:#nopriv_user .*:nopriv_user=ftp:'                   /etc/vsftpd.conf
	sed -i 's:#chroot_local_user .*:chroot_local_user=YES:'       /etc/vsftpd.conf

	log "vsFTP Installation | Completed"
	debug_wait "vsftpd.installed"

##[ proFTP ]##
elif [[ ${ftpd} = 'proftp' ]]; then
	notice "iNSTALLiNG proFTPd"
	$INSTALL proftpd-basic 2>> ${LOG}
	E_=$? && debug_error "ProFTPd failed to install"

	log "ProFTP Installation | Completed"
	debug_wait "proftpd.installed"

##[ pureFTP ]##
elif [[ ${ftpd} = 'pureftp' ]]; then
	notice "iNSTALLiNG Pure-FTPd"
	$INSTALL pure-ftpd pure-ftpd-common 2>> ${LOG}
	E_=$? && debug_error "PureFTP failed to install"

	debug_wait "Creating PureFTP SSL Key"
	echo 1 > /etc/pure-ftpd/conf/TLS  # Enable TLS+FTP (2 will allow TLS only, 0 disables it)
	if [[ ! -f /etc/ssl/private/pure-ftpd.pem ]]; then  # Create SSL Certificate
		mkdir -p /etc/ssl/private && make-ssl-cert $SSLEAYCNF /etc/ssl/private/pure-ftpd.pem
		chmod 600 /etc/ssl/private/pure-ftpd.pem  # Read write permission for owner only
		log "PureFTP SSL Key created"
	fi
	sed -i 's:STANDALONE_OR_INETD=.*:STANDALONE_OR_INETD=standalone:' /etc/default/pure-ftpd-common
	/etc/init.d/pure-ftpd restart

	log "PureFTP Installation | Completed"
	debug_wait "pureftp.installed"
fi

##[ mySQL ]##
if [[ ${sql} = 'mysql' ]]; then
	notice "iNSTALLiNG MySQL"
	if [[ ${DISTRO} = 'Ubuntu' ]]; then
		$INSTALL mysql-server mysql-client libmysqlclient16-dev mysql-common mytop 2>> ${LOG} && E_=$?
	elif [[ ${DISTRO} = 'Debian' ]]; then
		$INSTALL mysql-server mysql-client libmysqlclient15-dev mysql-common mytop 2>> ${LOG} && E_=$?
	fi
	debug_error "MySQL failed to install"
	log "MySQL Installation | Completed"
	debug_wait "mysql.installed"

##[ SQLiTE ]##
elif [[ ${sql} = 'sqlite' ]]; then
	notice "iNSTALLiNG SQLite"
	$INSTALL sqlite3 php5-sqlite 2>> ${LOG}
	E_=$? && debug_error "SQLite failed to install"
	log "SQLite Installation | Completed"
	debug_wait "sqlite.installed"

##[ PostGreSQL ]##
elif [[ ${sql} = 'postgre' ]]; then
	notice "iNSTALLiNG PostgreSQL"
	$INSTALL postgresql postgresql-client-common postgresql-common 2>> ${LOG}
	E_=$? && debug_error "PostgreSQL failed to install"
	log "PostgreSQL Installation | Completed"
	debug_wait "postgresql.installed"
fi

##[ Bouncers ]##
cd $BASE
if [[ ${bnc} = 'znc' || ${bnc} = 'sbnc' || ${bnc} = 'psybnc' ]]; then
	$INSTALL libc-ares-dev tcl tcl-dev 2>> ${LOG}
		E_=$? && debug_error "Required packages failed to install"
fi

##[ ZNC ]##
if [[ ${bnc} = 'znc' ]]; then
	notice "iNSTALLiNG ZNC"
	cd tmp/
	download http://downloads.sourceforge.net/project/znc/znc/0.094/znc-0.094.tar.gz
		E_=$? && debug_error "ZNC Download Failed"
	tar -xzf znc-0.094.tar.gz && cd znc-0.094  # Unpack
		log "ZNC | Downloaded + Unpacked"
	notice "Be aware that compiling znc is a cpu intensive task and may take up to 10 min to complete"
	sleep 3
	sh configure
	compile
		debug_error "ZNC Build Failed"
		log "ZNC Compile | Completed in $compile_time seconds"
	make install
		log "ZNC Installation | Completed"
	debug_wait "znc.compiled"

#[TODO]#[ sBNC ]##
elif [[ ${bnc} = 'sbnc' ]]; then
	cd ${HOME}
	notice "iNSTALLiNG Shroud BNC"
	git clone -q http://github.com/gunnarbeutner/shroudbnc.git
	git clone -q http://github.com/gunnarbeutner/sBNC-Webinterface.git
#	git clone -q http://github.com/Kunsi/sBNC-Webinterface.git
	log "ShroudBNC | Downloaded"
	notice "ShroudBNC Downloaded to ${HOME}, you still need to compile it"

#	cd shroudbnc
#	sh configure
#	compile
#		debug_error "ShroudBNC Build Failed" && debug_wait
#		log "ShroudBNC Compile | Completed in $compile_time seconds"
#	make install
#		log "ShroudBNC Installation | Completed"

#echo -e "${bldred} \a\nStarting sbnc...Please answer a few questions ${rst}\n"
#debug_wait
#sbnc  # Run to create config
#echo -e "${bldred} EDiT ~/sbnc/sbnc.conf ${rst}\n"
#	log "--- EDiT ~/sbnc/sbnc.conf"

#TODO#[ psyBNC ]##
elif [[ ${bnc} = 'psybnc' ]]; then
	cd ${HOME}
	notice "iNSTALLiNG PsyBNC"
	download http://psybnc.org.uk/psyBNC-2.3.2-10.tar.gz
		E_=$? && debug_error "PsyBNC Download Failed"
	tar -xzf psyBNC-2.3.2-10.tar.gz && cd psybnc  # Unpack
		log "PsyBNC | Downloaded + Unpacked"
	make menuconfig
	compile
		debug_error "PsyBNC Build Failed"
		log "PsyBNC Compile | Completed in $compile_time seconds"
		debug_wait "psybnc.compiled"


	PSY_CONF=psybnc.conf
	PSY_OLD=psybnc.conf.old
	if [[ -e $PSY_CONF ]]; then
		mv $PSY_CONF $PSY_OLD  # Backup old conf
		touch $PSY_CONF        # Create new empty conf
	fi

	# Set psybnc port
	read -p "Please enter a unique port number for psybnc: " PSY_PORT  
	echo "PSYBNC.SYSTEM.PORT1=${PSY_PORT}" >> $PSY_CONF  # Write to conf
	echo "PSYBNC.SYSTEM.HOST1=*"           >> $PSY_CONF
	echo "PSYBNC.HOSTALLOWS.ENTRY0=*;*"    >> $PSY_CONF

	./psybnc ${PSY_CONF}  # Run
	log "PsyBNC Installation | Completed"
fi

##[ WebMiN ]##
cd $BASE
if [[ ${webmin} = 'y' ]]; then
	notice "iNSTALLiNG WEBMiN"
	$INSTALL webmin libauthen-pam-perl libio-pty-perl libnet-ssleay-perl libpam-runtime 2>> ${LOG}
	E_=$? && debug_error "Webmin failed to install" && sleep 3
		log "WebMin Installation | Completed"
		debug_wait "webmin.installed"
fi

##[ vnStat ]##
cd $BASE/tmp
if [[ ${vnstat} = 'y' ]]; then
	notice "iNSTALLiNG VNSTAT"
	$INSTALL libgd2-xpm libgd2-xpm-dev 2>> ${LOG}
	git clone -q git://github.com/bjd/vnstat-php-frontend.git vnstat-web  # Checkout VnStat-Web
	download http://humdi.net/vnstat/vnstat-1.10.tar.gz                   # Download VnStat
	tar xzf vnstat-1.10.tar.gz && cd vnstat-1.10                          # Unpack
	compile
		debug_error "VnStat Build Failed"
		log "VnStat Compile | Completed in $compile_time seconds"
		debug_wait "vnstat.compiled"
	make install                                                          # Install
		log "VnStat Installation | Completed"
	cd ..


	if [[ ! -f /etc/init.d/vnstat ]]; then
		cp ../modules/vnstat/vnstat-debian.init /etc/init.d/vnstat        # Copy init script if one doesnt exist
		chmod a+x /etc/init.d/vnstat && update-rc.d vnstat defaults       # Start at boot
		log "VnStat | Created Init Script"
		debug_wait "vnstat.init.copied"
	else log "VnStat | Previous Init Script Found, skipping..."
	fi

	sed -i "s:UnitMode 0:UnitMode 1:"               /etc/vnstat.conf  # Use MB not MiB
	sed -i "s:RateUnit 1:RateUnit 0:"               /etc/vnstat.conf  # Use bytes not bits
	sed -i "s:UpdateInterval 30:UpdateInterval 60:" /etc/vnstat.conf  # Increase daemon checks
	sed -i "s:PollInterval 5:PollInterval 10:"      /etc/vnstat.conf  # ^^^^^^^^ ^^^^^^ ^^^^^^
	sed -i "s:SaveInterval 5:SaveInterval 10:"      /etc/vnstat.conf  # Less saves to disk
	sed -i "s:UseLogging 2:UseLogging 1:"           /etc/vnstat.conf  # Log to file instead of syslog

	rm vnstat-web/config.php  # Remove and replace
	cp ../modules/vnstat/config.php vnstat-web

	sed -i "s:$iface_list = .*:$iface_list = array('${iFACE}');:" vnstat-web/config.php  # Edit web config

	rm -rf vnstat-web/themes/espresso vnstat-web/themes/light vnstat-web/themes/red      # Remove extra themes
	rm -rf vnstat-web/COPYING vnstat-web/vera_copyright.txt vnstat-web/config.php        # Remove extra files

	if [[ ! -d ${WEB}/vnstat-web ]]; then
		mv vnstat-web ${WEB}  # Copy VnStat-web to WebRoot
		 log "Frontend Installed | http://${iP}/vnstat-web"
	else log "VnStat | Previous vnstat-web Found, skipping..."
	fi
	if [[ ! $(pidof vnstatd) ]]; then
		vnstat -u -i ${iFACE}  # Make interface database
		vnstatd -d             # Start daemon
	fi
	debug_wait "vnstat-web.installed"
fi

cd $BASE/tmp
echo -e "\n*******************************"
echo -e   "**${bldred} TORRENT CLiENT iNSTALLiNG ${rst}**"
echo      "*******************************"

if [[ ${buildtorrent} = 'b' ]]; then
#-->##[ BuildTorrent ]##
if [[ ! -f /usr/local/bin/buildtorrent ]]; then
	notice "iNSTALLiNG BuildTorrent"
	if [[ ! -d buildtorrent ]]; then  # Checkout latest BuildTorrent source
		git clone -q git://gitorious.org/buildtorrent/buildtorrent.git
		E_=$? && debug_error "BuildTorrent Download Failed"
		log "BuildTorrent | Downloaded"
	fi

	cd buildtorrent
	aclocal
	autoconf
	autoheader
	automake -a -c
	sh configure
	make install && E=$?

	debug_error "BuildTorrent Build Failed"
	log "BuildTorrent Installation | Completed"
	debug_wait "buildtorrent.installed"
fi
else
#-->##[ mkTorrent ]##
if [[ ! -f /usr/local/bin/mktorrent ]]; then
	notice "iNSTALLiNG MkTorrent"
	if [[ ! -d mktorrent ]]; then  # Checkout latest mktorrent source
		git clone -q git://github.com/esmil/mktorrent.git
		E_=$? && debug_error "MkTorrent Download Failed"
		log "MkTorrent | Downloaded"
	fi

	cd mktorrent
	make install && E_=$?

	debug_error "MkTorrent Build Failed"
	log "MkTorrent Installation | Completed"
	debug_wait "mktorrent.installed"
fi
fi

cd $BASE
##[ rTorrent ]##
if [[ ${torrent} = 'rtorrent' ]]; then source modules/rtorrent/install.sh

##[ Transmission ]##
elif [[ ${torrent} = 'tranny' ]]; then source modules/transmission/install.sh

##[ Deluge ]##
elif [[ ${torrent} = 'deluge' ]]; then source modules/deluge/install.sh
fi

##[ ruTorrent ]##
if [[ ${webui} = 'y' ]]; then source modules/rutorrent/install.sh
fi

##[TODO][ uTorrent alpha ]##
#if [[ ${utorrent} = 'y' ]]; then
#	source modules/utorrent/install.sh
#fi

if [[ $mod_extra = 1 ]]; then source modules/extra/_main.sh
fi

source ${BASE}/includes/postprocess.sh
exit 0  # Completed
