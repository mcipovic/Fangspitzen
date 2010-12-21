install_rutorrent=false
while [[ $install_rutorrent = false ]]; do
	if [[ ! -d $WEB/rutorrent ]]; then  # Compile rtorrent
		install_rutorrent='true'
	else  # Ask to re-compile if rtorrent is already installed
		echo -en "ruTorrent Found => Updating...  " ; sleep 1
		cd $WEB/rutorrent && svn up
		break
	fi
done

if [[ $install_rutorrent = 'true' ]]; then
cd $BASE/tmp
	notice "iNSTALLiNG ruTorrent"
	checkout http://rutorrent.googlecode.com/svn/trunk/rutorrent  # Checkout ruTorrent
	if_error "ruTorrent Download Failed"
	log "ruTorrent | Downloaded"

cd rutorrent
	rm -R plugins conf/plugins.ini favicon.ico
	cp "$BASE"/modules/rutorrent/plugins.ini conf/plugins.ini
	cp "$BASE"/modules/rutorrent/favicon.ico favicon.ico

	notice "iNSTALLiNG Plugins"
	checkout http://rutorrent.googlecode.com/svn/trunk/plugins  # Checkout plugins-svn
	if_error "ruTorrent Plugins Download Failed"

	# Install extra plugins
cd plugins
	checkout http://rutorrent-pausewebui.googlecode.com/svn/trunk pausewebui
	checkout http://rutorrent-logoff.googlecode.com/svn/trunk/ logoff
	checkout http://rutorrent-instantsearch.googlecode.com/svn/trunk instantsearch
	if_error "ruTorrent Extra Plugins Download Failed"
	extract $BASE/modules/rutorrent/plugin-nfo.tar.gz
	log "ruTorrent plugins | Downloaded"

cd $BASE/tmp
	sed -i "s:\$saveUploadedTorrents .*:\$saveUploadedTorrents = false;:"         rutorrent/conf/config.php
	sed -i "s:\$topDirectory .*:\$topDirectory = '/home';:"                       rutorrent/conf/config.php
	sed -i "s:\$XMLRPCMountPoint .*:\$XMLRPCMountPoint = \"/rutorrent/master\";:" rutorrent/conf/config.php
	sed -i "s:\$defaultTheme .*:\$defaultTheme = \"Oblivion\";:"                  rutorrent/plugins/theme/conf.php

	echo
	if [[ $(pgrep apache2) ]]; then  # Apache
		htdigest -c /etc/apache2/.htpasswd "ruTorrent" $USER  # Create user authentication
		cp ../modules/apache/htaccess rutorrent/.htaccess
	elif [[ $(pgrep lighttpd) ]]; then  # Lighttp
		htdigest -c /etc/lighttpd/.htpasswd "ruTorrent" $USER  # Create user authentication
	fi

	if [[ -f /usr/local/bin/buildtorrent ]]; then
		sed -i "s:	\$useExternal .*;:	\$useExternal = \"buildtorrent\";:"                              rutorrent/plugins/create/conf.php
		sed -i "s:	\$pathToCreatetorrent .*;:	\$pathToCreatetorrent = '/usr/local/bin/buildtorrent';:" rutorrent/plugins/create/conf.php
	elif [[ -f /usr/local/bin/mktorrent ]]; then
		sed -i "s:	\$useExternal .*;:	\$useExternal = \"mktorrent\";:"                                 rutorrent/plugins/create/conf.php
		sed -i "s:	\$pathToCreatetorrent .*;:	\$pathToCreatetorrent = '/usr/local/bin/mktorrent';:"    rutorrent/plugins/create/conf.php
	fi
	log "ruTorrent Config | Created"

	cp -R rutorrent "$WEB"  # Move rutorrent to webroot
	chmod -R 755 $WEB
	chown -R www-data:www-data $WEB
	log "ruTorrent Installation | Completed" ; debug_wait "rutorrent.installed"
fi
