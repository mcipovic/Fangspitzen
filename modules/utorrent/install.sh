cd ${HOME}
download http://download.utorrent.com/linux/utorrent-server-3.0-21886.tar.gz
	E_=$? && if_error "uTorrent Download Failed"
tar xzf utorrent-server-3.0-21886.tar.gz
cd bittorrent-server-v3_0
# echo 'some_settings'       > utserver.conf
# echo 'some_more_settings' >> utserver.conf
log "uTorrent Server Unpacked | ./utserver | http://your.ip:8080/gui | User: admin"
debug_wait "utorrent.installed"
