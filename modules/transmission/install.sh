cd ${BASE}/tmp
	notice "iNSTALLiNG TRANSMiSSiON"
	packages install transmission-daemon transmission-common transmission-cli 2>> ${LOG}
		E_=$? && debug_error "Transmission failed to install"

	/etc/init.d/transmission-daemon stop

	sudo -u $USER transmission-daemon && sleep 2  # Create our users config folder below
	kill -15 $(pidof transmission-daemon) && sleep 2
	echo
	read -p " WEBUi User Name: " tUser
	read -p " WEBUi Password : " tPass

	PATH_tr=$HOME/.config/transmission-daemon/settings.json
	sed -i "s|\"blocklist-enabled.*|\"blocklist-enabled\": true,|"                     $PATH_tr
	sed -i "s|\"blocklist-url.*|\"blocklist-url\": \"http://www.bluetack.co.uk/config/level1.gz\",|" $PATH_tr
	sed -i "s|\"cache-size-mb.*|\"cache-size-mb\": 8,|"                                $PATH_tr
	sed -i "s|\"open-file-limit.*|\"open-file-limit\": 64,|"                           $PATH_tr
	sed -i "s|\"rpc-authentication-required.*|\"rpc-authentication-required\": true,|" $PATH_tr
	sed -i "s|\"rpc-password.*|\"rpc-password\": \"$tPass\",|"                         $PATH_tr
	sed -i "s|\"rpc-username.*|\"rpc-username\": \"$tUser\",|"                         $PATH_tr
	sed -i "s|\"rpc-whitelist.*|\"rpc-whitelist\": \"*.*.*.*\",|"                      $PATH_tr

	sudo -u $USER transmission-daemon  # Start transmission
	log "Transmission Installation | Completed"
	log "WebUI is active on http://$IP:9091"
	debug_wait "transmission.installed"
