##!===================>> Post Processing <<======================!##
echo -e "\n*******************************"
echo -e   "******${bldred} POST PROCESSiNG ${rst}********"
echo -e   "*******************************\n"

if [[ -f /etc/ssh/sshd_config ]]; then
	sed -i 's:PermitRootLogin yes:PermitRootLogin no:' /etc/ssh/sshd_config
	sed -i 's:LoginGraceTime 120:LoginGraceTime 30:'   /etc/ssh/sshd_config
	sed -i 's:StrictModes no:StrictModes yes:'         /etc/ssh/sshd_config
	sed -i 's:ServerKeyBits .*:ServerKeyBits 1024:'    /etc/ssh/sshd_config
	sed -i 's:X11Forwarding yes:X11Forwarding no:'     /etc/ssh/sshd_config
	/etc/init.d/ssh restart
fi

if [[ $http = 'apache' ]]; then
	/etc/init.d/apache2 restart
elif [[ $http = 'lighttp' ]]; then
	mv $WEB/index.lighttpd.html $WEB/index.html
	/etc/init.d/lighttpd restart
elif [[ $http = 'cherokee' ]]; then
	notice "Run sudo cherokee-admin -b to configure Cherokee."
fi

if [[ $sql = 'mysql' ]]; then
	/etc/init.d/mysql restart
fi

if [[ $sql = 'postgre' ]]; then  # This needs to change per version
	post_ver=8.4
	if [[ $NAME = 'lenny' ]]; then
		post_ver=8.3
	fi
	post_conf=/etc/postgresql/$post_ver/main/postgresql.conf
	sed -i "s:#autovacuum .*:autovacuum = on:"     $post_conf
	sed -i "s:#track_counts .*:track_counts = on:" $post_conf
	/etc/init.d/postgresql-$post_ver restart
fi

#[ Add Some Useful Command Alias' ]#
if [[ -f $HOME/.bashrc ]];then
	cat $HOME/.bashrc | grep '# added by autoscript' >/dev/null
if [[ $? != 0 ]]; then  # Check if this has already been added or not
	sed -i 's:force_color_prompt=no:force_color_prompt=yes:' $HOME/.bashrc
	echo "# added by autoscript">> $HOME/.bashrc
	echo "alias install='$alias_install'"     >> $HOME/.bashrc
	echo "alias remove='$alias_remove'"       >> $HOME/.bashrc
	echo "alias update='$alias_update'"       >> $HOME/.bashrc
	echo "alias upgrade='$alias_upgrade'"     >> $HOME/.bashrc
	echo "alias autoclean='$alias_autoclean'" >> $HOME/.bashrc
	
	if [[ $torrent = 'rtorrent' ]];then
		echo "alias rtorrent-start='dtach -n .dtach/rtorrent rtorrent'" >> $HOME/.bashrc
		echo "alias rtorrent-resume='dtach -a .dtach/rtorrent'"         >> $HOME/.bashrc
	fi
fi  # end `if $?`
fi

##[ Configure Fail2Ban ]##
f2b_jail=/etc/fail2ban/jail.conf
cat $f2b_jail | grep '# added by autoscript' >/dev/null
if [[ $? != 0 ]]; then  # Check if this has already been added or not
	sed -i 's:bantime .*:bantime = 86400:' $f2b_jail  # 24 hours
	sed -i '/[ssh]/,/port	= ssh/ s:enabled .*:enabled = true:' $f2b_jail
	if [[ $ftp = 'vsftp' ]]; then
		sed -i '/[vsftpd]/,/filter   = vsftpd/ s:enabled .*:enabled = true:' $f2b_jail
	elif [[ $ftp = 'proftp' ]]; then
		sed -i '/[proftpd]/,/filter   = proftpd/ s:enabled .*:enabled = true:' $f2b_jail
	elif [[ $ftp = 'pureftp' ]]; then
		sed -i 's:[wuftpd]:[pure-ftpd]:' $f2b_jail
		sed -i 's:filter   = wuftpd:filter   = pure-ftpd:'                                            $f2b_jail
		sed -i '/[pure-ftpd]/,/filter   = pure-ftpd/ s:enabled .*:enabled = true:'                    $f2b_jail
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
	echo "# added by autoscript" >> $f2b_jail

	echo -n "Restarting fail2ban..."
	killall -q -15 fail2ban-server ; sleep 2
	if [[ -e /var/run/fail2ban/fail2ban.sock ]]; then
		rm /var/run/fail2ban/fail2ban.sock
	fi
	/etc/init.d/fail2ban start && echo " done"
fi  # end `if $?`

if [[ $torrent = 'rtorrent' ]]; then
echo ; read -p "Start rtorrent now? [y/n]: " start_rt
	if [[ $start_rt = 'y' ]]; then
		mkdir -p $HOME/.dtach ; rm -f $HOME/.dtach/rtorrent
		chmod -R 755 $HOME/.dtach
		chown -R $USER:$USER $HOME/.dtach
		sudo -u $USER dtach -n /home/$USER/.dtach/rtorrent rtorrent

		TESTrt=$(pgrep -u $USER rtorrent)
		if [[ $? = 0 ]]; then
			echo "rTorrent has been started with dtach in ~/.dtach/rtorrent"
		else echo "rtorrent FAILED to start!"
		fi
	fi
fi

ldconfig
log "Linking Shared Libaries | Completed"

echo -en "\n${bldred} Cleaning up...${rst}"
packages clean  # remove uneeded and cached packages
cleanup
echo -e "${bldylw} done${rst}"
