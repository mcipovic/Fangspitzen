compile_rtorrent=false
while [[ $compile_rtorrent = false ]]; do
	if [[ ! -f /usr/bin/rtorrent ]]; then  # Compile rtorrent
		compile_rtorrent='true'
	else  # Ask to re-compile if rtorrent is already installed
		echo -en "rTorrent Found.... re-compile? [y/n]: "
		if  yes; then
			compile_rtorrent='true'
			break
		else
			compile_rtorrent='break_loop'
		fi
	fi
done

if [[ $compile_rtorrent = 'true' ]]; then
cd $BASE/tmp
	notice "DOWNLOADiNG SOURCES"
	checkout http://xmlrpc-c.svn.sourceforge.net/svnroot/xmlrpc-c/advanced xmlrpc  # Checkout xmlrpc ~advanced
	debug_error "XMLRPC Download Failed"
	log "XMLRPC | Downloaded" >> $LOG

	if [[ $rtorrent_svn = 'y' ]]; then
		checkout -r 1180 svn://rakshasa.no/libtorrent/trunk
		debug_error "LibTorrent Download Failed"
		mv trunk/libtorrent libtorrent && mv trunk/rtorrent rtorrent && rm -r trunk
		log "Lib|rTorrent | Downloaded" >> $LOG
	else
		download http://libtorrent.rakshasa.no/downloads/libtorrent-0.12.6.tar.gz  # Grab libtorrent
		download http://libtorrent.rakshasa.no/downloads/rtorrent-0.8.6.tar.gz     # Grab rtorrent
		log "Lib|rTorrent | Downloaded" >> $LOG
		tar xzf libtorrent-0.12.6.tar.gz && tar xzf rtorrent-0.8.6.tar.gz          # Unpack
		mv libtorrent-0.12.6 libtorrent && mv rtorrent-0.8.6 rtorrent
		log "Lib|rTorrent | Unpacked"
	fi

	notice "COMPiLiNG... XMLRPC"
#-->[ Compile xmlrpc ]
	cd xmlrpc
	sh configure --prefix=/usr
	compile
		debug_error "XMLRPC Build Failed"
		log "XMLRPC Compile | Completed in $compile_time seconds"
	make install
		log "XMLRPC Installation | Completed"
		debug_wait "xmlrpc.installed"

	notice "COMPiLiNG... LiBTORRENT"
#-->[ Compile libtorrent ]
	cd ../libtorrent
	if [[ $NAME = 'lenny' ]]; then
		rm -f scripts/{libtool,lt*}.m4
	fi
		sh autogen.sh
	if [[ $alloc = 'y' ]]; then
		 sh configure --prefix=/usr --with-posix-fallocate  # Use posix_fallocate
	else sh configure --prefix=/usr
	fi
	compile
		debug_error "LibTorrent Build Failed"
		log "LibTorrent Compile | Completed in $compile_time seconds"
	make install
		log "LibTorrent Installation | Completed"
		debug_wait "libtorrent.installed"

	notice "COMPiLiNG... rTORRENT"
#-->[ Compile rtorrent ]
	cd ../rtorrent
	if [[ $NAME = 'lenny' ]]; then
		rm -f scripts/{libtool,lt*}.m4
	fi
	sh autogen.sh
	sh configure --prefix=/usr --with-xmlrpc-c
	compile
		debug_error "rTorrent Build Failed"
		log "rTorrent Compile | Completed in $compile_time seconds"
	make install
		log "rTorrent Installation | Completed"
fi

if [[ -f .rtorrent.rc ]]; then
	log "Previous rTorrent.rc config found, creating backup..."
	mv .rtorrent.rc .rtorrent.rc.bak
	notice "BACKED UP PREVIOUS rTORRENT.RC"
fi

notice "CREATiNG .rtorrent.rc CONFiG"
cd $HOME
sudo -u $USER mkdir -p .session
sudo -u $USER mkdir -p downloads
#sudo -u $USER mkdir -p watch

cd $BASE
PATH_rt=$HOME/.rtorrent.rc
cp modules/rtorrent/rtorrent.rc $PATH_rt

NUMBER=$[($RANDOM % 65534) + 20000]  # Generate a random number from 20000-65534
echo "port_range = $NUMBER-$NUMBER"       >> $PATH_rt
echo "directory = /home/$USER/downloads"  >> $PATH_rt
echo "session = /home/$USER/.session"     >> $PATH_rt

if [[ ${rtorrent_svn} != 'y' ]]; then
	echo "max_open_files = 256"    >> $PATH_rt
	echo "max_memory_usage = 800M" >> $PATH_rt
	echo "preload_type = 1"        >> $PATH_rt
fi

if [[ ${alloc} = 'y' ]]; then
	echo "system.file_allocate.set = yes" >> $PATH_rt  # Enable file pre-allocation
fi

if [[ -d /etc/apache2 ]]; then
	echo 'scgi_port = localhost:5000'     >> $PATH_rt  # Create scgi port on localhost:5000
elif [[ -d /etc/lighttpd || -d /etc/cherokee ]]; then
	echo "scgi_local = /tmp/rpc.socket"                             >> $PATH_rt  # Create sgci socket
	echo 'schedule = chmod,0,0,"execute=chmod,777,/tmp/rpc.socket"' >> $PATH_rt  # Make socket readable
else
	debug_wait "No httpd found: Make sure to add sgci mounts to .rtorrent.rc"
fi
log "rTorrent Config | Created"
log "rTorrent listening on port: $NUMBER"

if [[ ! -f /etc/init.d/rtorrent ]]; then  # Copy init script
	cp modules/rtorrent/rtorrent-init /etc/init.d/rtorrent
	cp modules/rtorrent/rtorrent-init-conf $HOME/.rtorrent.init.conf

	# Write init configuration
	sed -i "s:user=:user=\"$USER\":"                      $HOME/.rtorrent.init.conf
	sed -i "s:base=:base=$HOME:"                          $HOME/.rtorrent.init.conf
	sed -i 's:config=:config=("$base/.rtorrent.rc"):'     $HOME/.rtorrent.init.conf
	sed -i "s:logfile=:logfile=$HOME/.rtorrent.init.log:" $HOME/.rtorrent.init.conf

	chmod a+x /etc/init.d/rtorrent && update-rc.d rtorrent defaults  # Start at boot
	log "rTorrent Config | Installed \nrTorrent Init Script | Created"
else
	log "Previous rTorrent Init Script Found, skipping..."
fi
debug_wait "rtorrent.installed"
