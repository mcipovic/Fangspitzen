##[ XCache ]##
if [[ ${cache} = 'xcache' ]]; then
	notice "iNSTALLiNG X-CACHE"
	${INSTALL} php5-xcache 2>> ${eLOG}
		E_=$? && debug_error "X-Cache failed to install"

	echo -e "\n${bldylw} Generate a User Name and Password for XCache-Admin"
	echo -e " You can use www.trilug.org/~jeremy/md5.php to generate the password ${rst}\n"
	read -p "   Login Name: " xUser  # Get UserName and Password
	read -p " MD5 Password: " xPass  # For XCache-Admin

	PATH_xcache="/etc/php5/conf.d/xcache.ini"
	sed -i "s:; xcache.admin.user .*:xcache.admin.user = ${xUser}:" ${PATH_xcache}
	sed -i "s:; xcache.admin.pass .*:xcache.admin.pass = ${xPass}:" ${PATH_xcache}
	sed -i 's:xcache.size  .*:xcache.size  = 48M:'                  ${PATH_xcache}  # Increase cache size
	sed -i "s:xcache.count .*:xcache.count = ${CORES}:" 	        ${PATH_xcache}  # Specify CPU Core count
	sed -i 's:xcache.var_size  .*:xcache.var_size  = 8M:'           ${PATH_xcache}
	sed -i 's:xcache.optimizer .*:xcache.optimizer = On:'           ${PATH_xcache}
	cp -a /usr/share/xcache/admin ${WEB}/xcache-admin/  # Copy Admin folder to webroot

	log "XCache Installation | Completed"
	debug_wait "xcache.installed"

##[ APC ]##
elif [[ ${cache} = 'apc' ]]; then
	notice "iNSTALLiNG APC"
	${INSTALL} php-apc 2>> ${eLOG}
	E_=$? && debug_error "PHP-APC failed to install"
	log "APC Installation | Completed"
	debug_wait "apc.installed"
fi
