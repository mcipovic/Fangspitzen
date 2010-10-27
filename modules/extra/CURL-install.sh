notice "iNSTALLiNG libCURL~git"

cd $BASE/tmp
git clone http://github.com/bagder/curl.git && log "LibCurl - downloaded"
cd curl
sh buildconf
sh configure --prefix=/usr
compile && log "LibCurl - compiled"
install && log "LibCurl - compiled"

notice -n " Compile rTorrent now? [y|n]: "
if yesno
	then source $BASE/modules/rtorrent/install.sh
fi

