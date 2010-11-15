cd ${BASE}/tmp
	notice "iNSTALLiNG DELUGE"
	${INSTALL} deluge-common deluge-console deluge-web deluged 2>> ${LOG}
		E_=$? && debug_error "Deluge failed to install"

	deluged && sleep 1 ; killall deluged
	#deluge-web --fork && sleep 1 ; killall deluge-web

	cp ../modules/deluge/deluge-daemon.defaults /etc/default/deluge-daemon  # Copy init config
	cp ../modules/deluge/deluge-daemon.init     /etc/init.d/deluge-daemon   # Copy init script
	echo
	read -p " WEBUi User Name: "   dUser
	read -p " WEBUi  Password: "   dPass
	read -p " Port Range [from]: " dPort1
	read -p " Port Range [  to]: " dPort2

	echo "$dUser:$dPass:10" >> $HOME/.config/deluge/auth
	sed -i "s:DELUGED_USER=:DELUGED_USER=\"$USER\":" /etc/default/deluge-daemon  # Put UserName in script
	chmod a+x /etc/init.d/deluge-daemon && update-rc.d deluge-daemon defaults    # Start at boot

	log "Deluge Init Script Created"
	debug_wait "deluge.init.copied"

	deluge_conf="$HOME/.config/deluge/core.conf"
	sed -i "s,\"move_completed\": .*,\"move_completed\": \"true\","                             $deluge_conf
	sed -i "s,\"move_completed_path\": .*,\"move_completed_path\": \"$HOME/Finished\","         $deluge_conf
	sed -i "s,\"download_location\": .*,\"download_location\": \"$HOME/downloads\","            $deluge_conf
	sed -i "s,\"autoadd_location\": .*,\"autoadd_location\": \"$HOME/watch\","                  $deluge_conf
	sed -i "s,\"plugins_location\": .*,\"plugins_location\": \"$HOME/.config/deluge/plugins\"," $deluge_conf

	sed -i "s,\"max_active_limit\": .*,\"max_active_limit\": \"200\","             $deluge_conf
	sed -i "s,\"max_active_downloading\": .*,\"max_active_downloading\": \"200\"," $deluge_conf
	sed -i "s,\"max_active_seeding\": .*,\"max_active_seeding\": \"200\","         $deluge_conf

	sed -i "s,\"allow_remote\": .*,\"allow_remote\": \"true\"," $deluge_conf
	sed -i "s,\"dht\": .*,\"dht\": \"false\","                  $deluge_conf

	sed -i "s:6881,:$dPort1,:" $deluge_conf
	sed -i "s:6891,:$dPort2:"  $deluge_conf

	deluged && deluge-web

	log "Deluge Config | Created"
	log "Deluge WebUi listening on Port 8112"
	debug_wait "deluged.installed"
