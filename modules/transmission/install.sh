cd ${BASE}/tmp
notice "iNSTALLiNG TRANSMiSSiON"
${INSTALL} transmission-daemon transmission-common transmission-cli 2>> ${LOG}
	E_=$? && debug_error "Transmission failed to install"

if [[ ! -f /etc/init.d/transmission-daemon ]]; then  # Transmission-Daemon provides this!
	cp ../modules/transmission/transmission-daemon.init /etc/init.d/transmission-daemon    # Copy init script
	read -p " User Name: " tUser                                                           # Get UserName
	sed -i "s:USERNAME=.*:USERNAME=${tUser}:" /etc/init.d/transmission-daemon              # Put UserName in script
	chmod a+x /etc/init.d/transmission-daemon && update-rc.d transmission-daemon defaults  # Start at boot
	log "Transmission Init Script | Created"
else
	log "Previous Transmission Init Script Found, skipping..."
fi
/etc/init.d/transmission-daemon stop

sudo -u $USER transmission-daemon && killall transmission-daemon  # Create our users config folder below

PATH_tr=${HOME}/.config/transmission-daemon/settings.json

sed -i "s:\"blocklist-enabled.*:\"blocklist-enabled\"\: true,:"                  $PATH_tr
sed -i "s:\"cache-size-mb.*:\"cache-size-mb\"\: 8,:"                             $PATH_tr
sed -i "s:\"rpc-authentication-required.*:rpc-authentication-required\"\: true," $PATH_tr
sed -i "s:\"rpc-password.*:\"rpc-password\"\: \"$tPASS\",:"                      $PATH_tr
sed -i "s:\"rpc-username.*:\"rpc-username\"\: \"$tUSER\","                       $PATH_tr
sed -i "s:\"rpc-whitelist.*:\"rpc-whitelist\"\: \"*.*.*.*\","                    $PATH_tr

sudo -u $USER transmission-daemon
log "Transmission Installation | Completed \nWebUI is active on http://$HOSTNAME:9091"




