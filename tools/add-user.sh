#!/usr/bin/env bash

# Assumptions:
#	Apache - mod_auth_digest
#	/etc/apache2/auth.passwd
#	/var/www/rutorrent/.htaccess
#
# You can, of course, change it below

init_variables()
{
	htaccess='/var/www/rutorrent/.htaccess'
	htpasswd='/etc/apache2/.htpasswd'
	rutorrent='/var/www/rutorrent'
	webserver='apache'  # apache or lighttp
	webuser='www-data'
	user_name=''
	shell_reply=''

	bldred='\e[1;31m'  # Red
	bldpur='\e[1;35m'  # Purple
	rst='\e[0m'        # Reset
}

assumption_check()
{
	err=0
	if [[ ! -f $htpasswd ]]; then
		echo -e " htpasswd....[${bldred} FAILED ${rst}]" ;err=1
		else echo -e " htpasswd....[${bldpur} OK ${rst}]" ;fi
	if [[ ! -f $htaccess ]]; then
		echo -e " htaccess....[${bldred} FAILED ${rst}]" ;err=1
		else echo -e " htaccess....[${bldpur} OK ${rst}]" ;fi
	if [[ ! -d $rutorrent ]]; then
		echo -e " ruTorrent...[${bldred} FAILED ${rst}]" ;err=1
		else echo -e " ruTorrent...[${bldpur} OK ${rst}] \n" ;fi
	if [[ $err = 1 ]]; then echo; exit 0 ;fi
}

get_info()
{
	read -p "User Name: " user_name
	read -p "Give shell access? y|n: " shell_reply
	if [[ $shell_reply = 'n' ]]; then
		user_shell='/usr/sbin/nologin'
	else user_shell='/bin/bash'
	fi
}

do_add()
{
	useradd --comment ${user_name}-Autoscript --create-home --shell $user_shell $user_name
	if [[ $? = 0 ]]; then
		echo -e "\n${bldred}-${rst} System User .........[${bldpur} CREATED ${rst}]"
	else
		echo -e "\n${bldred}-${rst} System User .........[${bldred} FAILED ${rst}]"
	fi;echo

	passwd $user_name
	if [[ $? = 0 ]]; then
		echo -e "\n${bldred}-${rst} User Password .......[${bldpur} CREATED ${rst}]"
	else
		echo -e "\n${bldred}-${rst} User Password .......[${bldred} FAILED ${rst}]"
	fi

	make_rtorrent_rc
	make_rtorrent_init

	htdigest $htpasswd "ruTorrent" $user_name
	if [[ $? = 0 ]]; then
		echo -e "\n${bldred}-${rst} ruTorrent Password ..[${bldpur} CREATED ${rst}]"
	else
		echo -e "\n${bldred}-${rst} ruTorrent Password ..[${bldred} FAILED ${rst}]"
	fi

	make_rutorrent_conf
	httpd_scgi
}

make_rtorrent_rc()
{
	cd /home/$user_name
	sudo -u $user_name mkdir downloads; mkdir .session
	sudo -u $user_name cat > .rtorrent.rc << "EOF"
max_peers = 50
max_peers_seed = 50
max_uploads = 250
download_rate = 12288
upload_rate = 12288
port_range = 45600-45600
port_random = no
check_hash = no
hash_read_ahead = 32
hash_interval = 10
hash_max_tries = 5
schedule = low_diskspace,5,60,close_low_diskspace=100M
use_udp_trackers = yes
dht = off
encoding_list = UTF-8
encryption = allow_incoming,try_outgoing,enable_retry
max_open_files = 256
max_memory_usage = 800M
#schedule = watch_directory,5,5,load_start=/absolute/path/to/watch/*.torrent
EOF
	echo "directory = /home/$user_name/downloads" >> .rtorrent.rc
	echo "session = /home/$user_name/.session"    >> .rtorrent.rc

	echo -e "${bldred}-${rst} rTorrent Config .....[${bldpur} CREATED ${rst}]\n"
}

make_rtorrent_init()
{
	if [[ -f /etc/init.d/rtorrent ]]; then
		sudo -u $user_name echo "user=$user_name"                              > .rtorrent.init.conf
		sudo -u $user_name echo "base=/home/$user_name"                       >> .rtorrent.init.conf
		sudo -u $user_name echo "config=(\"\$base/.rtorrent.rc\")"            >> .rtorrent.init.conf
		sudo -u $user_name echo "logfile=/home/$user_name/.rtorrent.init.log" >> .rtorrent.init.conf
		echo -e "${bldred}-${rst} rTorrent Init Script.[${bldpur} CREATED ${rst}]\n"
	else
		echo -e "${bldred}-${rst} rTorrent Init Script.[${bldpur} SKIPPED ${rst}]\n"
	fi
}

make_rutorrent_conf()
{
	cd $rutorrent/conf
	sudo -u $webuser mkdir users/$user_name
	sudo -u $webuser cp config.php users/$user_name/config.php
	sudo -u $webuser sed -i "s:\$scgi_port .*:\$scgi_port = $scgi_port;:"                  users/$user_name/config.php
	sudo -u $webuser sed -i "s:$XMLRPCMountPoint .*:$XMLRPCMountPoint = \"$scgi_mount\";:" users/$user_name/config.php

	sudo -u $webuser cat >> users/$user_name/access.ini << "EOF"
[settings]
showDownloadsPage = no
showConnectionPage = no
showBittorentPage = no
showAdvancedPage = no
[tabs]
showPluginsTab = no
[statusbar]
canChangeULRate = no
canChangeDLRate = no
[dialogs]
canChangeTorrentProperties = yes
EOF
	echo -e "${bldred}-${rst} ruTorrent Config ....[${bldpur} CREATED ${rst}]\n"
}

httpd_scgi()
{
	declare -i scgi_port=0
	scgi_mount="/rutorrent/$user_name"
	read -p "SCGi Port: " scgi_port

	while [[ $scgi_port -lt 1024 || $scgi_port -gt 65535 || $scgi_port -eq 5000 ]]; do
		echo -e "\n${bldred}- Invalid Port${rst}"
		read -p "SCGi Port: " scgi_port
	done

	if [[ $webserver = 'apache' ]]; then
		echo "SCGIMount $scgi_mount 127.0.0.1:$scgi_port" >> /etc/apache2/mods-available/scgi.conf
		sudo -u $user_name echo "scgi_port = localhost:$scgi_port" >> .rtorrent.rc
		echo -e "${bldred}-${rst} Apache SCGi Mount ...[${bldpur} CREATED ${rst}]\n"
#	elif [[ $webserver = 'lighttp' ]]; then
#		sudo -u $user_name echo 'schedule = chmod,0,0,"execute=chmod,777,/tmp/rpc.$user_name.socket"' >> /home/$user_name/.rtorrent.rc
#		sudo -u $user_name echo "scgi_local = /tmp/rpc.$user_name.socket"                             >> /home/$user_name/.rtorrent.rc
	fi
}

## Main ##
if [[ ${UID} != 0 ]]; then
	echo -e "${bldred}Run as root user ${rst}"
	exit
else
	init_variables
	assumption_check
	get_info
	do_add
fi
