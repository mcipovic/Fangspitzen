##[ Check for iPBLOCK ]##
if [[ ${ipblock} = 'y' ]]; then
	v1=$(aptitude show iplist | grep Version)
	v2=$(aptitude show iplist | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ ${ipblock} = 'n' ]]; then
	echo -e "${bldylw} iPBLOCK NOT BEiNG iNSTALLED${rst}"
else echo -e "${bldred}---> ERROR iN iPBLOCK iNPUT!${rst}" ;ipblock='n'
fi

#TODO#[ iPBlock ]##
if [[ ${ipblock} = 'y' ]]; then
	notice "iNSTALLiNG iPBlock"
	if [[ $NAME = 'lenny' ]]; then
		apt-get -t squeeze install libpcre3 libnfnetlink0 libnetfilter-queue1 2>> ${LOG}  # Install updated libraries for lenny support
	fi
	${INSTALL} iplist 2>> ${LOG}
		E_=$? && debug_error "IPlist failed to install"

	PATH_iplist=/etc/ipblock.conf
	filters='index.html?list=bt_level1'
	sed -i "s:AUTOSTART=.*:AUTOSTART=\"Yes\":"           ${PATH_iplist}
	sed -i "s:BLOCK_LIST=.*:BLOCK_LIST=\"${filters} \":" ${PATH_iplist}
		log "iPLiST Installation | Completed"

	echo -en "${bldred} Updating Block Lists....${rst}"
	ipblock -u
		log "Block Lists Updated"
	echo -e "${bldylw} done ${rst}"
	echo -en "${bldred} Starting iPBlock....${rst}"
	ipblock -r  # Start ipblock
		debug_wait "iplist.installed.started"
fi
