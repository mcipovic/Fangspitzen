##!===================>> Post Processing <<======================!##
echo -e "\n********************************"
echo -e   "****${bldred} PROCESSiNG AND CLEANUP ${rst}****"
echo -e   "********************************\n"

if [[ -f /etc/ssh/sshd_config ]]; then
	sed -i 's:PermitRootLogin yes:PermitRootLogin no:' /etc/ssh/sshd_config
	sed -i 's:LoginGraceTime 120:LoginGraceTime 30:'   /etc/ssh/sshd_config
	sed -i 's:X11Forwarding yes:X11Forwarding no:'     /etc/ssh/sshd_config
/etc/init.d/ssh force-reload
fi
if [[ ${http} = 'apache' ]]; then
	sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s:AllowOverride .*:AllowOverride All:' /etc/apache2/sites-available/default*
	sed -i 's:ServerSignature On:ServerSignature Off:' /etc/apache2/apache2.conf
	sed -i 's:Timeout 300:Timeout 30:'                 /etc/apache2/apache2.conf
	sed -i 's:KeepAliveTimeout 15:KeepAliveTimeout 5:' /etc/apache2/apache2.conf
	sed -i 's:ServerTokens Full:ServerTokens Prod:'    /etc/apache2/apache2.conf
	echo   "ServerName $HOSTNAME" >>                   /etc/apache2/apache2.conf
/etc/init.d/apache2 force-reload
fi
if [[ ${sql} = 'mysql' ]]; then
	sed -ie 's:query_cache_limit .*:query_cache_limit = 2M\nquery_cache_type = 1:' /etc/mysql/my.cnf
/etc/init.d/mysql force-reload
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
fi

#[ Add Some Useful Command Alias' ]#
if [[ -f ${HOME}/.bashrc ]];then
	sed -i 's:force_color_prompt=no:force_color_prompt=yes:' ${HOME}/.bashrc
	echo "alias wget='axel'"                          >>     ${HOME}/.bashrc
	echo "alias apt-get='apt-fast'"                   >>     ${HOME}/.bashrc
#	echo "alias update='sudo aptitude update'"        >>     ${HOME}/.bashrc
#	echo "alias install='sudo aptitude install'"      >>     ${HOME}/.bashrc
#	echo "alias upgrade='sudo aptitude safe-upgrade'" >>     ${HOME}/.bashrc
#	echo "alias remove='sudo aptitude remove'"        >>     ${HOME}/.bashrc
	if [[ ${torrent} = 'rtorrent' ]];then
		echo "alias rtorrent-start='dtach -n .dtach/rtorrent rtorrent'" >> ${HOME}/.bashrc
		echo "alias rtorrent-resume='dtach -a .dtach/rtorrent'"         >> ${HOME}/.bashrc
	fi
fi

if [[ ${torrent} = 'rtorrent' ]]; then
echo && read -p "Start rtorrent now? [y|n]: " start_rt
	if [[ $start_rt = 'y' ]]; then
		mkdir -p $HOME/.dtach && rm -rf $HOME/.dtach/rtorrent
		chmod -R 755 $HOME/.dtach
		chown -R $USER:$USER $HOME/.dtach
		sudo -u $USER dtach -n /home/$USER/.dtach/rtorrent rtorrent
		echo "rTorrent has been started with dtach in ~/.dtach/rtorrent"
	fi
fi

ldconfig
log "Linking Shared Libaries | Completed"

echo -en "${bldred} Cleaning up...${rst}"
apt-get -qq autoremove # remove uneeded and 
apt-get -qq autoclean  #+cached deb packages
cleanup
echo -e "${bldylw} done${rst}"

sudo -K  # forget our password
echo -e "\n*******************************"
echo -e   "******${bldred} SCRiPT COMPLETED! ${rst}******"
echo -e   "****${bldred} FiNiSHED iN ${bldylw}$SECONDS ${bldred}SECONDS ${rst}**"
echo -e   "*******************************\n"
log "SCRiPT | COMPLETED @ $(date) \n<---------------------------------> \n"
