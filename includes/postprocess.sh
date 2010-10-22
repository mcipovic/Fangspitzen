##!===================>> Post Processing <<======================!##
echo -e "\n********************************"
echo -e   "****${bldred} PROCESSiNG AND CLEANUP ${rst}****"
echo -e   "********************************\n"

if [[ -f /etc/ssh/sshd_config ]]; then
	sed -i 's:PermitRootLogin yes:PermitRootLogin no:' /etc/ssh/sshd_config
	sed -i 's:LoginGraceTime 120:LoginGraceTime 30:'   /etc/ssh/sshd_config
	sed -i 's:X11Forwarding yes:X11Forwarding no:'     /etc/ssh/sshd_config
/etc/init.d/ssh force-reload
debug_wait "sshd"
fi
if [[ ${http} = 'apache' ]]; then
	sed -i 's:AllowOverride None:AllowOverride All:'   /etc/apache2/sites-available/default
	sed -i 's:ServerSignature On:ServerSignature Off:' /etc/apache2/apache2.conf
	sed -i 's:Timeout 300:Timeout 30:'                 /etc/apache2/apache2.conf
	sed -i 's:KeepAliveTimeout 15:KeepAliveTimeout 5:' /etc/apache2/apache2.conf
	sed -i 's:ServerTokens Full:ServerTokens Prod:'    /etc/apache2/apache2.conf
	echo   "ServerName ${HOSTNAME}" >>                 /etc/apache2/apache2.conf
/etc/init.d/apache2 force-reload
debug_wait "apache.reloaded"
fi
if [[ ${sql} = 'mysql' ]]; then
	sed -ie 's:query_cache_limit .*:query_cache_limit = 2M\nquery_cache_type = 1:' /etc/mysql/my.cnf
/etc/init.d/mysql force-reload
debug_wait "mysqld.reloaded"
fi
if [[ ${sql} = 'postgre' ]]; then  # This needs to change per version
	post_ver=8.4
	if [[ ${NAME} = 'lenny' ]]; then
		post_ver=8.3
	fi
	post_conf=/etc/postgresql/${post_ver}/main/postgresql.conf
	sed -i "s:#autovacuum .*:autovacuum = on:"     ${post_conf}
	sed -i "s:#track_counts .*:track_counts = on:" ${post_conf}
/etc/init.d/postgresql-${post_ver} restart
debug_wait "postgresql.restarted"
fi

#[ Add Some Useful Command Alias' ]#
if [[ -f ${HOME}/.bashrc ]];then
	sed -i 's:force_color_prompt=no:force_color_prompt=yes:' ${HOME}/.bashrc
	echo "alias wget='axel'"                          >>     ${HOME}/.bashrc
#	echo "alias apt-get='apt-fast'"                   >>     ${HOME}/.bashrc
#	echo "alias update='sudo aptitude update'"        >>     ${HOME}/.bashrc
#	echo "alias install='sudo aptitude install'"      >>     ${HOME}/.bashrc
#	echo "alias upgrade='sudo aptitude safe-upgrade'" >>     ${HOME}/.bashrc
#	echo "alias remove='sudo aptitude remove'"        >>     ${HOME}/.bashrc
fi

ldconfig
	log "Linking Shared Libaries | Completed"
	debug_wait "linked.shared.libs"

if [[ ${DEBUG} = 0 ]]; then update; fi
apt-get -qq autoremove
apt-get -qq autoclean

echo -en "${bldred} Cleaning up...${rst}"
cleanup
echo -e "${bldylw} done${rst}"

sudo -K  # forget our password
echo -e "\n*******************************"
echo -e   "******${bldred} SCRiPT COMPLETED! ${rst}******"
echo -e   "****${bldred} FiNiSHED iN ${bldylw}$SECONDS ${bldred}SECONDS ${rst}**"
echo -e   "*******************************\n"
log "SCRiPT | COMPLETED"
