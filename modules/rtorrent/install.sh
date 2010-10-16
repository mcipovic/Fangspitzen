cd ${BASE}/tmp
notice "iNSTALLiNG rTorrent"
	checkout http://xmlrpc-c.svn.sourceforge.net/svnroot/xmlrpc-c/advanced xmlrpc # Checkout 'advanced' xmlrpc
		E_=$? && debug_error "XMLRPC Download Failed"
	download http://libtorrent.rakshasa.no/downloads/rtorrent-0.8.6.tar.gz        # Grab rtorrent
		E_=$? && debug_error "rTorrent Download Failed"
	download http://libtorrent.rakshasa.no/downloads/libtorrent-0.12.6.tar.gz     # Grab libtorrent
		E_=$? && debug_error "LibTorrent Download Failed"
	echo -e "XMLRPC | Downloaded \nLibTorrent | Downloaded \nrTorrent | Downloaded" >> ${LOG}

	tar xzf rtorrent-0.8.6.tar.gz && tar xzf libtorrent-0.12.6.tar.gz             # Unpack
	log -e "LibTorrent | Unpacked \nrTorrent | Unpacked"

	notice "COMPiLiNG... Go Grab a Coffee"
#-->[ Compile xmlrpc ]
	cd xmlrpc
	sh configure --prefix=/usr
	make && E_=$?
		debug_error "XMLRPC Build Failed"
		log "XMLRPC Compile | Completed"
	make install
		log "XMLRPC Installation | Completed"
		debug_wait "xmlrpc.installed"

	notice "STiLL COMPiLiNG! How About A Donut"
#-->[ Compile libtorrent ]
	cd ../libtorrent-0.12.6
	if [[ ${NAME} = 'lenny' ]]; then
		rm -f scripts/{libtool,lt*}.m4
	fi
		sh autogen.sh
	if [[ ${alloc} = 'y' ]]; then
		sh configure --prefix=/usr --with-posix-fallocate  # Compile with pre-allocate
	else
		sh configure --prefix=/usr
	fi
	compile && E_=$?
		debug_error "LibTorrent Build Failed"
		log "LibTorrent Compile | Completed"
	make install
		log "LibTorrent Installation | Completed"
		debug_wait "libtorrent.installed"

	notice "ALMOST DONE! I SWEAR!"
#-->[ Compile rtorrent ]
	cd ../rtorrent-0.8.6
	if [[ ${NAME} = 'lenny' ]]; then
		rm -f scripts/{libtool,lt*}.m4
	fi
	sh autogen.sh
	sh configure --prefix=/usr --with-xmlrpc-c
	compile && E_=$?
		debug_error "rTorrent Build Failed"
		log "rTorrent Compile | Completed"
	make install
		log "rTorrent Installation | Completed"

	notice "iNSTALLiNG rTorrent CONFiG FiLE"
	cd ${HOME}
	if [[ ! -d .session ]] ; then sudo -u $USER mkdir .session  ;fi
	if [[ ! -d downloads ]]; then sudo -u $USER mkdir downloads ;fi
	if [[ ! -d watch ]]    ; then sudo -u $USER mkdir watch     ;fi

	cd ${BASE}
	if [[ ! -f ${HOME}/.rtorrent.rc ]]; then
		PATH_rt=${HOME}/.rtorrent.rc
		cp modules/rtorrent/rtorrent.rc ${PATH_rt}

		if [[ ${alloc} = 'y' ]]; then
			echo "system.file_allocate.set=yes" >> ${PATH_rt}  # Enable file pre-allocation
		fi
		if [[ -d /etc/apache2 ]]; then
			echo 'scgi_port = localhost:5000'   >> ${PATH_rt}  # Create scgi port on localhost:5000
		elif [[ -d /etc/lighttpd || -d /etc/cherokee ]]; then
			echo "scgi_local = /tmp/rpc.socket"                             >> ${PATH_rt}  # Create sgci socket
			echo 'schedule = chmod,0,0,"execute=chmod,777,/tmp/rpc.socket"' >> ${PATH_rt}  # Make socket readable
		else
			debug_wait "No httpd found: Make sure to add sgci mounts to .rtorrent.rc"
		fi
		 log "rTorrent Config | Created"
	else log "Previous rTorrent.rc Config Found, skipping..."
	fi

	if [[ ! -f /etc/init.d/rtorrent ]]; then #TODO# This is broken
		cp modules/rtorrent/rtorrent-init /etc/init.d/rtorrent           # Copy init script
		sed -i "s:user=\"\":user=\"${USER}\":" /etc/init.d/rtorrent      # Put UserName in script
		chmod a+x /etc/init.d/rtorrent && update-rc.d rtorrent defaults  # Start at boot
		log "rTorrent Config | Installed \nrTorrent Init Script | Created"
	else
		log "Previous rTorrent Init Script Found, skipping..."
	fi
	debug_wait "rtorrent.installed"

	read -p "Start rtorrent now? [y|n]: " start_rt
	if [[ $start_rt = 'y' ]]; then
		sudo -u $USER screen -dmS rtorrent-$USER rtorrent
		echo "rTorrent has been started in screen. \n"
	fi
