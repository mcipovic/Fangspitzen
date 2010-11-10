##!===================>> Post Processing <<======================!##
echo -e "\n********************************"
echo -e   "****${bldred} PROCESSiNG AND CLEANUP ${rst}****"
echo -e   "********************************\n"

if [[ -f /etc/ssh/sshd_config ]]; then
	sed -i 's:PermitRootLogin yes:PermitRootLogin no:' /etc/ssh/sshd_config
	sed -i 's:LoginGraceTime 120:LoginGraceTime 30:'   /etc/ssh/sshd_config
	sed -i 's:StrictModes no:StrictModes yes:'         /etc/ssh/sshd_config
	sed -i 's:ServerKeyBits .*:ServerKeyBits 1024:'    /etc/ssh/sshd_config
	sed -i 's:X11Forwarding yes:X11Forwarding no:'     /etc/ssh/sshd_config
/etc/init.d/ssh restart
fi
if [[ $http = 'apache' ]]; then
	sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s:AllowOverride .*:AllowOverride All:' /etc/apache2/sites-available/default*
	sed -i 's:ServerSignature On:ServerSignature Off:' /etc/apache2/apache2.conf
	sed -i 's:Timeout 300:Timeout 30:'                 /etc/apache2/apache2.conf
	sed -i 's:KeepAliveTimeout 15:KeepAliveTimeout 5:' /etc/apache2/apache2.conf
	sed -i 's:ServerTokens Full:ServerTokens Prod:'    /etc/apache2/apache2.conf
	echo   "ServerName $HOSTNAME" >>                   /etc/apache2/apache2.conf
/etc/init.d/apache2 restart
fi
if [[ $sql = 'mysql' ]]; then
	sed -ie 's:query_cache_limit .*:query_cache_limit = 2M\nquery_cache_type = 1:' /etc/mysql/my.cnf
/etc/init.d/mysql restart
fi
if [[ $sql = 'postgre' ]]; then  # This needs to change per version
	post_ver=8.4
	if [[ $NAME = 'lenny' ]]; then
		post_ver=8.3
	fi
	post_conf=/etc/postgresql/${post_ver}/main/postgresql.conf
	sed -i "s:#autovacuum .*:autovacuum = on:"     $post_conf
	sed -i "s:#track_counts .*:track_counts = on:" $post_conf
/etc/init.d/postgresql-${post_ver} restart
fi

#[ Add Some Useful Command Alias' ]#
if [[ -f $HOME/.bashrc ]];then
	sed -i 's:force_color_prompt=no:force_color_prompt=yes:' $HOME/.bashrc
	echo "alias wget='axel'"                >> $HOME/.bashrc
	echo "alias apt-get='apt-fast'"         >> $HOME/.bashrc
	echo "alias update='apt-fast update'"   >> $HOME/.bashrc
	echo "alias install='apt-fast install'" >> $HOME/.bashrc
	echo "alias upgrade='apt-fast upgrade'" >> $HOME/.bashrc
	echo "alias remove='apt-fast remove'"   >> $HOME/.bashrc
	if [[ ${torrent} = 'rtorrent' ]];then
		echo "alias rtorrent-start='dtach -n .dtach/rtorrent rtorrent'" >> $HOME/.bashrc
		echo "alias rtorrent-resume='dtach -a .dtach/rtorrent'"         >> $HOME/.bashrc
	fi
fi

##[ Configure Fail2Ban ]##
if [[ -d /etc/fail2ban ]]; then
	f2b_jail=/etc/fail2ban/jail.conf
	sed -i 's:bantime .*:bantime = 86400:' $f2b_jail  # 24 hours
	sed -i '/[ssh]/,/port	= ssh/ s:enabled .*:enabled = true:' $f2b_jail
	if [[ $ftp = 'vsftp' ]]; then
		sed -i '/[vsftpd]/,/filter   = vsftpd/ s:enabled .*:enabled = true:' $f2b_jail
	elif [[ $ftp = 'proftp' ]]; then
		sed -i '/[proftpd]/,/filter   = proftpd/ s:enabled .*:enabled = true:' $f2b_jail
	elif [[ $ftp = 'pureftp' ]]; then
		sed -i 's:[wuftpd]:[pure-ftpd]:' $f2b_jail
		sed -i 's:filter   = wuftpd:filter   = pure-ftpd:' $f2b_jail
		sed -i '/[pure-ftpd]/,/filter   = pure-ftpd/ s:enabled .*:enabled = true:' $f2b_jail
		sed -i '/filter   = pure-ftpd/,/maxretry = 6/ s:logpath .*:logpath  = /var/log/pureftpd.log:' $f2b_jail
	fi
	if [[ $http = 'apache' ]]; then
		sed -i '/[apache]/,/port	= http,https/ s:enabled .*:enabled = true:'           $f2b_jail
		sed -i '/[apache-noscript]/,/port    = http,https/ s:enabled .*:enabled = true:'  $f2b_jail
		sed -i '/[apache-overflows]/,/port    = http,https/ s:enabled .*:enabled = true:' $f2b_jail
		cat >> $f2b_jail << "EOF"
[apache-badbots]
enabled = true
port    = http,https
filter  = apache-badbots
logpath = /var/log/apache*/*error.log
maxretry = 3
EOF
	fi
	if [[ $webmin = 'y' ]]; then
		cat >> $f2b_jail << "EOF"
[webmin-auth]
enabled = true
port	= 10000
filter	= webmin-auth
logpath = /var/log/auth.log
maxretry = 5
EOF
	fi
fi

if [[ $torrent = 'rtorrent' ]]; then
echo && read -p "Start rtorrent now? [y|n]: " start_rt
	if [[ $start_rt = 'y' ]]; then
		mkdir -p $HOME/.dtach && rm -rf $HOME/.dtach/rtorrent
		chmod -R 755 $HOME/.dtach
		chown -R $USER:$USER $HOME/.dtach
		sudo -u $USER dtach -n /home/$USER/.dtach/rtorrent rtorrent
		echo -e "${bldred}rTorrent has been started with dtach in ~/.dtach/rtorrent \n${rst}"
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
