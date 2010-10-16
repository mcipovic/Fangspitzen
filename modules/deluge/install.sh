cd ${BASE}/tmp
	notice "iNSTALLiNG DELUGE"
	${INSTALL} deluge-common deluge-console deluge-daemon deluge-web 2>> ${eLOG}
		E_=$? && debug_error "Deluge failed to install"

	deluged && killall deluged
	deluge-web --fork && killall deluge-web

	if [[ ! -f /etc/init.d/deluge-daemon ]]; then
		cp ../modules/deluge/deluge-daemon.defaults /etc/default/deluge-daemon            # Copy init config
		cp ../modules/deluge/deluge-daemon.init /etc/init.d/deluge-daemon                 # Copy init script
		sed -i "s:DELUGED_USER=.*:DELUGED_USER=\"${dUser}\":" /etc/default/deluge-daemon  # Put UserName in script
		chmod a+x /etc/init.d/deluge-daemon && update-rc.d deluge-daemon defaults         # Start at boot

		read -p " WEBUi User Name: " dUser
		read -p " WEBUi  Password: " dPass
		read -p " Port Range [from]: " Dport1
		read -p " Port Range [  to]: " Dport2
		echo "${dUser}:${dPass}:10" >> ${HOME}/.config/deluge/auth

		log "Deluge Init Script Created"
		debug_wait "deluge.init.copied"
	else notice "Previous Deluge Init Script Found, skipping"
	fi

	PATH_deluge='${HOME}/.config/deluge/core.conf'
	sed -i "s,  \"move_completed\": .*,  \"move_completed\": \"true\","                               ${PATH_deluge}
	sed -i "s,  \"move_completed_path\": .*,  \"move_completed_path\": \"${HOME}/Finished\","         ${PATH_deluge}
	sed -i "s,  \"download_location\": .*,  \"download_location\": \"${HOME}/downloads\","            ${PATH_deluge}
	sed -i "s,  \"autoadd_location\": .*,  \"autoadd_location\": \"${HOME}/watch\","                  ${PATH_deluge}
	sed -i "s,  \"plugins_location\": .*,  \"plugins_location\": \"${HOME}/.config/deluge/plugins\"," ${PATH_deluge}

	sed -i "s,  \"max_active_limit\": .*,  \"max_active_limit\": \"200\","             ${PATH_deluge}
	sed -i "s,  \"max_active_downloading\": .*,  \"max_active_downloading\": \"200\"," ${PATH_deluge}
	sed -i "s,  \"max_active_seeding\": .*,  \"max_active_seeding\": \"200\","         ${PATH_deluge}

	sed -i "s,  \"allow_remote\": .*,  \"allow_remote\": \"true\"," ${PATH_deluge}
	sed -i "s,  \"dht\": .*,  \"dht\": \"false\","                  ${PATH_deluge}

	sed -i "s,    6881, ,    ${Dport1}, ," ${PATH_deluge}
	sed -i "s,    6891,    ${Dport2},"     ${PATH_deluge}

	log "Deluge Config | Created"
	log "Deluge WebUi listening on Port 8112"
	debug_wait "deluged.installed"
