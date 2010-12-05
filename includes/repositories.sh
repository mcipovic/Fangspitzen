##!=====================>> REPOSiTORiES <<=======================!##
echo -e "\n********************************"
echo -e   "*****${bldred} ADDiNG REPOSiTORiES  ${rst}*****"
echo -e   "********************************\n"

if [[ $DISTRO = 'Ubuntu' ]]; then
	echo "deb http://archive.ubuntu.com/ubuntu/ $NAME multiverse"                > $REPO_PATH/multiverse.list  # non-free
	echo "deb-src http://archive.ubuntu.com/ubuntu/ $NAME multiverse"           >> $REPO_PATH/multiverse.list  # non-free
	echo "deb http://archive.ubuntu.com/ubuntu/ $NAME-updates multiverse"       >> $REPO_PATH/multiverse.list  # non-free
	echo "deb-src http://archive.ubuntu.com/ubuntu/ $NAME-updates multiverse"   >> $REPO_PATH/multiverse.list  # non-free

	echo "deb http://ppa.launchpad.net/cherokee-webserver/ppa/ubuntu $NAME main" > $REPO_PATH/autoinstaller.list  # Cherokee
	echo "deb http://ppa.launchpad.net/stbuehler/ppa/ubuntu $NAME main"         >> $REPO_PATH/autoinstaller.list  # Lighttp
	echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu $NAME main"       >> $REPO_PATH/autoinstaller.list  # Deluge
	echo "deb http://ppa.launchpad.net/transmissionbt/ppa/ubuntu $NAME main"    >> $REPO_PATH/autoinstaller.list  # Transmission
	echo "deb http://ppa.launchpad.net/ssakar/ppa/ubuntu $NAME main"            >> $REPO_PATH/autoinstaller.list  # iPList
	echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu $NAME main"              >> $REPO_PATH/autoinstaller.list  # SABnzbd
	echo "deb http://download.virtualbox.org/virtualbox/debian $NAME non-free"  >> $REPO_PATH/autoinstaller.list  # VirtualBox
	echo "deb http://download.webmin.com/download/repository sarge contrib"     >> $REPO_PATH/autoinstaller.list  # Webmin
	log "Repositories ADD | Success"

elif [[ $DISTRO = 'Debian' || $DISTRO = 'LinuxMint' ]]; then
	if [[ $NAME = 'lenny' ]]; then  # Bascially updates to squeeze since packages are so old on lenny
#		touch /etc/apt/apt.conf
#		echo 'APT::Default-Release "stable";' >> /etc/apt/apt.conf  # Make lenny the default for package installation
#		echo "deb http://ftp.debian.org/debian/ lenny non-free contrib"              >> /etc/apt/sources.list
#		echo "deb http://security.debian.org/ lenny/updates non-free contrib"        >> /etc/apt/sources.list
		echo "deb http://ftp.debian.org/debian/ squeeze main non-free contrib"       >> /etc/apt/sources.list
		echo "deb http://security.debian.org/ squeeze/updates main non-free contrib" >> /etc/apt/sources.list
		echo "deb http://ppa.launchpad.net/stbuehler/ppa/ubuntu jaunty main"         >> $REPO_PATH/autoinstaller.list  # Lighttp
	#elif [[ $NAME = 'squeeze' || $NAME = 'debian' ]]; then  # 'debian' is used for mint debian releases
	else
		echo "deb http://ftp.debian.org/debian/ squeeze non-free contrib"            >> /etc/apt/sources.list
		echo "deb http://security.debian.org/ squeeze/updates non-free contrib"      >> /etc/apt/sources.list
	fi

	echo "deb http://ppa.launchpad.net/cherokee-webserver/ppa/ubuntu jaunty main"  > $REPO_PATH/autoinstaller.list  # Cherokee
	echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu karmic main"        >> $REPO_PATH/autoinstaller.list  # Deluge
	echo "deb http://ppa.launchpad.net/transmissionbt/ppa/ubuntu karmic main"     >> $REPO_PATH/autoinstaller.list  # Transmission
	echo "deb http://ppa.launchpad.net/ssakar/ppa/ubuntu karmic main"             >> $REPO_PATH/autoinstaller.list  # iPList
	echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu jaunty main"               >> $REPO_PATH/autoinstaller.list  # SABnzbd
	echo "deb http://download.virtualbox.org/virtualbox/debian $NAME non-free"    >> $REPO_PATH/autoinstaller.list  # VirtualBox
	echo "deb http://download.webmin.com/download/repository sarge contrib"       >> $REPO_PATH/autoinstaller.list  # Webmin
	log "Repositories ADD | Success"

elif [[ $DISTRO = 'Arch' ]]; then
	echo '[archlinuxfr]'                           >> $REPO_PATH
	echo 'Server = http://repo.archlinux.fr/$arch' >> $REPO_PATH
else
	debug_error "${txtred} Failed to add repositories to unknown distro ($DISTRO) ...exiting ${rst}"
fi

##!=====================>> PUBLiC KEYS <<========================!##
if [[ $DISTRO = 'Ubuntu' || $DISTRO = 'Debian' || $DISTRO = 'LinuxMint' ]]; then
	addkey='apt-key adv --keyserver keyserver.ubuntu.com --recv-keys'  # Add signing keys
	$addkey EBA7BD49
	$addkey 5A43ED73
	$addkey 249AD24C
	$addkey 365C5CA1
	$addkey 108B243F
	$addkey 4BB9F05F
	cd $BASE/tmp
	download http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -
	download http://www.webmin.com/jcameron-key.asc -O- | apt-key add -
fi

	$UPDATE
	log "Repositories Added and Updated"
	debug_wait "repos.added"
clear
