cd ${BASE}/tmp
	notice "iNSTALLiNG ruTorrent"
	checkout http://rutorrent.googlecode.com/svn/trunk trunk  # Checkout ruTorrent-svn
	E_=$? && debug_error "ruTorrent Download Failed"
	log "ruTorrent | Downloaded"

plugins_dir='rutorrent/plugins/'
	cd trunk/  # Install Plugins
	cp -r plugins/_getdir     ${plugins_dir}
	cp -r plugins/autotools   ${plugins_dir}
	cp -r plugins/cookies     ${plugins_dir}
	cp -r plugins/cpuload     ${plugins_dir}
	cp -r plugins/create      ${plugins_dir}
	cp -r plugins/data        ${plugins_dir}
	cp -r plugins/datadir     ${plugins_dir}
	cp -r plugins/edit        ${plugins_dir}
	cp -r plugins/diskspace   ${plugins_dir}
	cp -r plugins/erasedata   ${plugins_dir}
	cp -r plugins/ratio       ${plugins_dir}
	cp -r plugins/rss         ${plugins_dir}
	cp -r plugins/show_peers* ${plugins_dir}
	cp -r plugins/theme       ${plugins_dir}
	cp -r plugins/throttle    ${plugins_dir}
	cp -r plugins/tracklabels ${plugins_dir}
	cp -r plugins/trafic      ${plugins_dir}
	cp -r plugins/unpack      ${plugins_dir}
	log "ruTorrent Plugins | Installed"
	cd ..

	if [[ -d /etc/apache2 ]]; then  # Apache
		rm -f trunk/rutorrent/conf/config.php
		cp ../modules/rutorrent/config.php.apache trunk/rutorrent/conf/config.php
		htdigest -c /etc/apache2/.htpasswd "ruTorrent" ${USER}  # Create user authenitication
		cp ../modules/apache/htaccess trunk/rutorrent/.htaccess
	elif [[ -d /etc/lighttpd ]]; then  # Lighttp
		rm -f trunk/rutorrent/conf/config.php
		cp ../modules/rutorrent/config.php.lighttp trunk/rutorrent/conf/config.php
		htdigest -c /etc/lighttpd/.htpasswd "ruTorrent" ${USER}  # Create user authenitication
		if [[ ! -f /etc/lighttpd/conf-available/99-auth.conf ]]; then
			cp ../modules/lighttpd/99-auth.conf /etc/lighttpd/conf-available/99-auth.conf
		fi
	fi
	if [[ ${buildtorrent} = 'b' ]];then
		 sed -i "s:\$useExternal = .*;:\$useExternal = buildtorrent;:" trunk/rutorrent/plugins/create/conf.php
	else sed -i "s:\$useExternal = .*;:\$useExternal = mktorrent;:"    trunk/rutorrent/plugins/create/conf.php
	fi
	log "ruTorrent Config | Created"

	rm trunk/rutorrent/favicon.ico && cp ../modules/rutorrent/favicon.ico trunk/rutorrent
	cp -R trunk/rutorrent ${WEB}  # Move rutorrent to webroot

	chown -R www-data:www-data ${WEB}
	chmod -R 755 ${WEB}
	log "ruTorrent Installation | Completed"
	debug_wait "rutorrent.installed"
