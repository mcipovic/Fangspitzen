##[ Check for SABnzbd ]##
if [[ ${sabnzbd} = 'y' ]]; then
	v1=$(aptitude show sabnzbdplus | grep Version)
	v2=$(aptitude show sabnzbdplus | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ ${sabnzbd} = 'n' ]]; then
	echo -e "${bldylw} SABnzbd NOT BEiNG iNSTALLED${rst}"
else echo -e "${bldred}---> ERROR iN SABnzbd iNPUT!${rst}" ; sabnzbd='n'
fi

#TODO#[ SABnzbd ]##
if [[ ${sabnzbd} = 'y' ]]; then
	notice "iNSTALLiNG SABnzbd"
	${INSTALL} sabnzbdplus par2 python-cheetah python-dbus python-yenc sabnzbdplus-theme-classic sabnzbdplus-theme-plush sabnzbdplus-theme-smpl 2>> ${LOG}
		E_=$? && debug_error "Sabnzbd failed to install"

	#if [[ $NAME = 'lenny' ]]; then
	#	libjs-mochikit >= 1.4
	#fi

	read -p "  User Name that will run SABnzbd: " sUser
	sabnzbd_conf=/home/${sUser}/.sabnzbd/sabnzbd.ini
	sabnzbd_init=/etc/default/sabnzbdplus

	sed -i "s:USER .*:USER=${sUser}:" ${sabnzbd_init}
	sed -i "s:HOST .*:HOST=${iP}:"    ${sabnzbd_init}
	sed -i "s:PORT .*:PORT=8080:"     ${sabnzbd_init}
	/etc/init.d/sabnzbdplus start && /etc/init.d/sabnzbdplus stop  # Create config in user's home

	sed -i "s:host .*:host = ${iP}:"  ${sabnzbd_conf}
	if [[ ${CORES} < 2 ]]; then
	sed -i "s:par2_multicore .*:par2_multicore = 0:" ${sabnzbd_conf}
	fi

	/etc/init.d/sabnzbdplus start  # Start 'er up
	
	log "SABnzbd Installation | Completed"
	log "SABnzbd Started and Running at http://${iP}:8080"
	debug_wait "SABnzbd.installed"
fi
