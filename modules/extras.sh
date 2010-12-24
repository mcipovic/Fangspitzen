##[ XCache ]##
if [[ $cache = 'xcache' ]]; then
	notice "iNSTALLiNG X-CACHE"
	packages install php5-xcache
	if_error "X-Cache failed to install"

	echo -e "\n${bldylw} Generate a User Name and Password for XCache-Admin"
	echo -e " You can use www.trilug.org/~jeremy/md5.php to generate the password ${rst}\n"
	read -p "   Login Name: " xUser  # Get UserName and Password
	read -p " MD5 Password: " xPass  # For XCache-Admin

	PATH_xcache="/etc/php5/conf.d/xcache.ini"
	sed -i "s:; xcache.admin.user .*:xcache.admin.user = $xUser:" $PATH_xcache
	sed -i "s:; xcache.admin.pass .*:xcache.admin.pass = $xPass:" $PATH_xcache
	sed -i 's:xcache.size  .*:xcache.size  = 48M:'                $PATH_xcache  # Increase cache size
	sed -i "s:xcache.count .*:xcache.count = $CORES:" 	          $PATH_xcache  # Specify CPU Core count
	sed -i 's:xcache.var_size  .*:xcache.var_size  = 8M:'         $PATH_xcache
	sed -i 's:xcache.optimizer .*:xcache.optimizer = On:'         $PATH_xcache
	cp -a /usr/share/xcache/admin "$WEB"/xcache-admin/  # Copy Admin folder to webroot

	log "XCache Installation | Completed" ; debug_wait "xcache.installed"

##[ APC ]##
elif [[ $cache = 'apc' ]]; then
	notice "iNSTALLiNG APC"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install php-apc
	elif [[ $DISTRO = *@(SUSE|[Ss]use) ]]; then
		# packages install TODO
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		# packages install TODO
	fi
	if_error "PHP-APC failed to install"
	log "APC Installation | Completed" ; debug_wait "apc.installed"
fi

##[ mySQL ]##
if [[ $sql = 'mysql' ]]; then
	notice "iNSTALLiNG MySQL"
	if [[ $DISTRO = 'Ubuntu' && $NAME != 'hardy' ]]; then
		packages install libmysqlclient16-dev mysql-client mysql-server mytop
	elif [[ $DISTRO = [Dd]ebian || $NAME = 'hardy' ]]; then
		packages install libmysqlclient15-dev mysql-client mysql-server mytop
	elif [[ $DISTRO = *@(SUSE|[Ss]use); then
		packages install libmysqlclient-devel mysql-community-server mytop
		chkconfig --add mysql
		/etc/init.d/mysql start
		mysql_secure_installation
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		# packages install TODO
	fi
	if_error "MySQL failed to install"

	sed -ie 's:query_cache_limit .*:query_cache_limit = 2M\nquery_cache_type = 1:' /etc/mysql/my.cnf

	log "MySQL Installation | Completed" ; debug_wait "mysql.installed"

##[ SQLiTE ]##
elif [[ $sql = 'sqlite' ]]; then
	notice "iNSTALLiNG SQLite"
	packages install sqlite3 php5-sqlite
	if_error "SQLite failed to install"
	log "SQLite Installation | Completed" ; debug_wait "sqlite.installed"

##[ PostGreSQL ]##
elif [[ $sql = 'postgre' ]]; then
	notice "iNSTALLiNG PostgreSQL"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install postgresql
	elif [[ $DISTRO = *@(SUSE|[Ss]use) ]]; then
		packages install postgresql postgresql-server
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		# packages install TODO
	fi
	if_error "PostgreSQL failed to install"
	log "PostgreSQL Installation | Completed" ; debug_wait "postgresql.installed"
fi

##[ Bouncers ]##
cd $BASE
if [[ $bnc != @(none|no|[Nn]) ]]; then
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install libc-ares-dev tcl tcl-dev
	elif [[ $DISTRO = *@(SUSE|[Ss]use) ]]; then
		packages install libcares-devel tcl tcl-devel
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		# packages install TODO
	fi
	if_error "Required packages failed to install"
fi

##[ ZNC ]##
if [[ $bnc = 'znc' ]]; then
	notice "iNSTALLiNG ZNC"
	cd tmp/
	download http://downloads.sourceforge.net/project/znc/znc/0.094/znc-0.094.tar.gz
		if_error "ZNC Download Failed"
	extract znc-0.094.tar.gz && cd znc-0.094  # Unpack
		log "ZNC | Downloaded + Unpacked"
	notice "Be aware that compiling znc is a cpu intensive task and may take up to 10 min to complete"
	sleep 3
	sh configure --enable-extra
	compile
		if_error "ZNC Build Failed"
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
	packages install swig
	git clone -q http://github.com/gunnarbeutner/shroudbnc.git
	git clone -q http://github.com/gunnarbeutner/sBNC-Webinterface.git
	chown -R $USER:$USER shroudbnc sBNC-Webinterface
		log "ShroudBNC | Downloaded"
	cd shroudbnc
	sudo -u $USER sh autogen.sh
	sudo -u $USER sh configure
	sudo -u $USER make -j$CORES
		if_error "ShroudBNC Build Failed"
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
		if_error "PsyBNC Download Failed"
	extract psyBNC-2.3.2-10.tar.gz
	chown -R $USER:$USER psybnc
		log "PsyBNC | Downloaded + Unpacked"

	cd psybnc
	sudo -u $USER make menuconfig
	sudo -u $USER make -j$CORES
		if_error "PsyBNC Build Failed"
		log "PsyBNC Compile | Completed in $compile_time seconds"
	log "PsyBNC Installation | Completed"
	notice "Installed to ~/psybnc"
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

##[ WebMiN ]##
cd $BASE
if [[ $webmin = 'y' ]]; then
	notice "iNSTALLiNG WEBMiN"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install webmin libauthen-pam-perl libio-pty-perl libnet-ssleay-perl libpam-runtime
	elif [[ $DISTRO = *@(SUSE|[Ss]use) ]]; then
		packages install webmin perl-Net-SSLeay
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		# packages install TODO
	fi
	if_error "Webmin failed to install"
	log "WebMin Installation | Completed" ; debug_wait "webmin.installed"
fi

##[ vnStat ]##
cd $BASE/tmp
if [[ $vnstat = 'y' ]]; then
	notice "iNSTALLiNG VNSTAT"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install libgd2-xpm libgd2-xpm-dev
	elif [[ $DISTRO = *@(SUSE|[Ss]use) ]]; then
		# packages install TODO
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		# packages install TODO
	fi
	if_error "vnStat deps failed to install"
	
	download http://humdi.net/vnstat/vnstat-1.10.tar.gz                   # Download VnStat
	git clone -q git://github.com/bjd/vnstat-php-frontend.git vnstat-web  # Checkout VnStat-Web
	extract vnstat-1.10.tar.gz && cd vnstat-1.10                          # Unpack

	##[ Alternative - JSvnStat ]##
	# download http://www.rakudave.ch/userfiles/javascript/jsvnstat/jsvnstat.zip
	# mkdir -p jsvnstat && mv jsvnstat.zip jsvnstat && cd jsvnstat
	# unzip jsvnstat.zip
	# rm README
	# sed -i "s|\$interface =.*|\$interface = \"$iFACE\";|" settings.php
	# cd ..
	# mv jsvnstat $WEB

	compile
		if_error "VnStat Build Failed"
		log "VnStat Compile | Completed in $compile_time seconds" ; debug_wait "vnstat.compiled"
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

	[[ ! $(pgrep vnstatd) ]] &&
		vnstat -u -i $iFACE &&
		vnstatd -d  # Make database and start vnstatd

	debug_wait "vnstat-web.installed"
fi

##[ SABnzbd ]##
cd $BASE/tmp
if [[ $sabnzbd = 'y' ]]; then
	notice "iNSTALLiNG SABnzbd"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
			packages install sabnzbdplus par2 python-cheetah python-dbus python-yenc sabnzbdplus-theme-classic sabnzbdplus-theme-plush sabnzbdplus-theme-smpl
	elif [[ $DISTRO = *@(SUSE|[Ss]use) ]]; then
		# packages install TODO
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		# packages install TODO
	fi
	if_error "Sabnzbd failed to install"

	# Install par2cmdline 0.4 with Intel Threading Building Blocks
	[[ $ARCH = 'x86_64' ]] &&
		download http://chuchusoft.com/par2_tbb/par2cmdline-0.4-tbb-20100203-lin64.tar.gz ||
		download http://chuchusoft.com/par2_tbb/par2cmdline-0.4-tbb-20090203-lin32.tar.gz

	extract par2cmdline-0.4*.tar.gz && cd par2cmdline-0.4*
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
	[[ $CORES < 2 ]] && 
		sed -i "s:par2_multicore .*:par2_multicore = 0:" $sabnzbd_conf

	/etc/init.d/sabnzbdplus start  # Start 'er up

	log "SABnzbd Installation | Completed"
	log "SABnzbd Started and Running at http://$iP:8080" ; debug_wait "SABnzbd.installed"
fi

##[ iPLiST ]##
cd $BASE/tmp
if [[ $ipblock = 'y' ]]; then
	notice "iNSTALLiNG iPBLOCK"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		if [[ $NAME = 'lenny' ]]; then
			apt-get -t squeeze install libpcre3 libnfnetlink0 libnetfilter-queue1 2>> $LOG  # Install updated libraries for lenny support
		fi
		packages install iplist
	elif [[ $DISTRO = *@(SUSE|[Ss]use) ]]; then
		# packages install TODO
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		# packages install TODO
	fi
	if_error "iPBLOCK failed to install"

	PATH_iplist=/etc/ipblock.conf
	filters='level1.gz'
	sed -i "s:AUTOSTART=.*:AUTOSTART=\"Yes\":"        $PATH_iplist
	sed -i "s:BLOCK_LIST=.*:BLOCK_LIST=\"$filters\":" $PATH_iplist

	echo -en "${bldred} Updating block lists... ${rst}"
	ipblock -u && echo -e "${bldylw} done ${rst}"
	/etc/init.d/ipblock start

	log "iPBLOCK Installation | Completed" ; debug_wait "ipblock.installed"
fi
