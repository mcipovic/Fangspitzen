#!=====================>> REPOSiTORiES <<=======================!#
echo -e "\n********************************"
echo -e   "*****${bldred} ADDiNG REPOSiTORiES  ${rst}*****"
echo -e   "********************************\n"

if [[ ${DISTRO} = 'Ubuntu' ]]; then
	echo "deb http://archive.ubuntu.com/ubuntu/ ${NAME} multiverse"              > ${REPO_PATH}/multiverse.list  # non-free
	echo "deb-src http://archive.ubuntu.com/ubuntu/ ${NAME} multiverse"         >> ${REPO_PATH}/multiverse.list  # non-free
	echo "deb http://archive.ubuntu.com/ubuntu/ ${NAME}-updates multiverse"     >> ${REPO_PATH}/multiverse.list  # non-free
	echo "deb-src http://archive.ubuntu.com/ubuntu/ ${NAME}-updates multiverse" >> ${REPO_PATH}/multiverse.list  # non-free

	echo "deb http://ppa.launchpad.net/cherokee-webserver/ppa/ubuntu ${NAME} main"  > ${REPO_PATH}/autoinstaller.list  # Cherokee
	echo "deb http://ppa.launchpad.net/stbuehler/ppa/ubuntu ${NAME} main"          >> ${REPO_PATH}/autoinstaller.list  # Lighttp
	echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu ${NAME} main"        >> ${REPO_PATH}/autoinstaller.list  # Deluge
	echo "deb http://ppa.launchpad.net/transmissionbt/ppa/ubuntu ${NAME} main"     >> ${REPO_PATH}/autoinstaller.list  # Transmission
#	echo "deb http://ppa.launchpad.net/ssakar/ppa/ubuntu ${NAME} main"             >> ${REPO_PATH}/autoinstaller.list  # iPList
#	echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu ${NAME} main"               >> ${REPO_PATH}/autoinstaller.list  # SABnzbd
	echo "deb http://download.webmin.com/download/repository sarge contrib"        >> ${REPO_PATH}/autoinstaller.list  # Webmin
	log "Repositories ADD | Success"

elif [[ $DISTRO = 'Debian' || $DISTRO = 'LinuxMint' ]]; then
	if [[ ${NAME} = 'lenny' ]]; then
		touch /etc/apt/apt.conf
		echo 'APT::Default-Release "stable";' >> /etc/apt/apt.conf  # Make lenny the default for package installation
#		echo "deb http://ftp.debian.org/debian/ lenny non-free contrib"              >> /etc/apt/sources.list
#		echo "deb http://security.debian.org/ lenny/updates non-free contrib"        >> /etc/apt/sources.list
		echo "deb http://ftp.debian.org/debian/ squeeze main non-free contrib"       >> /etc/apt/sources.list
		echo "deb http://security.debian.org/ squeeze/updates main non-free contrib" >> /etc/apt/sources.list
	elif [[ ${NAME} = 'squeeze' || ${NAME} = 'debian' ]]; then
		echo "deb http://ftp.debian.org/debian/ squeeze non-free contrib"            >> /etc/apt/sources.list
		echo "deb http://security.debian.org/ squeeze/updates non-free contrib"      >> /etc/apt/sources.list
	fi

#	echo "deb http://ppa.launchpad.net/cherokee-webserver/ppa/ubuntu jaunty main"  > ${REPO_PATH}/autoinstaller.list  # Cherokee
	echo "deb http://ppa.launchpad.net/stbuehler/ppa/ubuntu jaunty main"          >> ${REPO_PATH}/autoinstaller.list  # Lighttp
	echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu jaunty main"        >> ${REPO_PATH}/autoinstaller.list  # Deluge
#	echo "deb http://ppa.launchpad.net/transmissionbt/ppa/ubuntu jaunty main"     >> ${REPO_PATH}/autoinstaller.list  # Transmission
#	echo "deb http://ppa.launchpad.net/ssakar/ppa/ubuntu jaunty main"             >> ${REPO_PATH}/autoinstaller.list  # iPList
#	echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu jaunty main"               >> ${REPO_PATH}/autoinstaller.list  # SABnzbd
	echo "deb http://download.webmin.com/download/repository sarge contrib"       >> ${REPO_PATH}/autoinstaller.list  # Webmin
	log "Repositories ADD | Success"

else
	debug_error "${txtred}Failed to add repositories to unknown distro... exiting${rst}"
fi
	# Add signing keys
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EBA7BD49
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5A43ED73
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 249AD24C
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 365C5CA1
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 108B243F
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4BB9F05F
	download http://www.webmin.com/jcameron-key.asc && apt-key add jcameron-key.asc && rm jcameron-key.asc
	log "Repositories Keys ADD | Success"

debug_wait "repos.added"
clear
debug_wait "update.and.upgrade"
update
