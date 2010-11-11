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
cd ${BASE}/tmp
	notice "iNSTALLiNG ruTorrent"
	checkout http://rutorrent.googlecode.com/svn/trunk/rutorrent  # Checkout ruTorrent
	debug_error "ruTorrent Download Failed"
	log "ruTorrent | Downloaded"
	
	notice "iNSTALLiNG Plugins"
	cd rutorrent && rm -R plugins conf/plugins.ini favicon.ico
	checkout http://rutorrent.googlecode.com/svn/trunk/plugins  # Checkout plugins-svn
	debug_error "Plugins Download Failed"

	# Grab extra plugins
	cd plugins
	checkout http://rutorrent-pausewebui.googlecode.com/svn/trunk/pausewebui
	tar xzf ../../../modules/rutorrent/plugin-nfo.tar.gz
	cd ../..
		log "ruTorrent plugins | Downloaded"

	cp ../modules/rutorrent/plugins.ini rutorrent/conf/plugins.ini
	cp ../modules/rutorrent/favicon.ico rutorrent/favicon.ico
	sed -i "s:\$saveUploadedTorrents .*:\$saveUploadedTorrents = false;:"       rutorrent/conf/config.php
	sed -i "s:\$topDirectory .*:\$topDirectory = '/home';:"                     rutorrent/conf/config.php
	sed -i "s:\$XMLRPCMountPoint .*:\$XMLRPCMountPoint = \"/rutorrent/RPC2\";:" rutorrent/conf/config.php

	echo
	if [[ $(pidof apache2) ]]; then  # Apache
		htdigest -c /etc/apache2/.htpasswd "ruTorrent" $USER  # Create user authentication
		cp ../modules/apache/htaccess rutorrent/.htaccess
	elif [[ $(pidof lighttpd) ]]; then  # Lighttp
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

	cp -R rutorrent $WEB  # Move rutorrent to webroot
	chmod -R 755 $WEB
	chown -R www-data:www-data $WEB
	log "ruTorrent Installation | Completed"
	debug_wait "rutorrent.installed"
fi
