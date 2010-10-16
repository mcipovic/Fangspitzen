cd ${BASE}/tmp
notice "iNSTALLiNG TRANSMiSSiON"
${INSTALL} transmission-daemon transmission-common transmission-cli 2>> ${eLOG}
	E_=$? && debug_error "Transmission failed to install"

if [[ ! -f /etc/init.d/transmission-daemon ]]; then
	cp ../modules/transmission/transmission-daemon.init /etc/init.d/transmission-daemon    # Copy init script
	read -p " User Name: " tUser                                                           # Get UserName
	sed -i "s:USERNAME=.*:USERNAME=${tUser}:" /etc/init.d/transmission-daemon              # Put UserName in script
	chmod a+x /etc/init.d/transmission-daemon && update-rc.d transmission-daemon defaults  # Start at boot

	log -e "Transmission Installation | Completed \nTransmission Init Script | Created"
	debug_wait "transmission.init.copied"
else log -e "Previous Transmission Init Script Found, skipping..."
fi
