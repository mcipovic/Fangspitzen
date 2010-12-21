##!=======================>> FUNCTiONS <<=======================!##
base_install() {  # install dependencies

STABLE="apt-show-versions autoconf automake autotools-dev binutils build-essential bzip2 ca-certificates cfv comerr-dev cpp curl dtach fail2ban file g++ gamin gcc git-core gzip htop iptables libcppunit-dev libperl-dev libssl-dev libterm-readline-gnu-perl libtool m4 make ncurses-base ncurses-bin ncurses-term openssl patch perl perl-modules pkg-config python python-gamin python-openssl python-setuptools ssl-cert subversion sudo unrar unzip zip"
DYNAMIC="libcurl3 libcurl3-gnutls libcurl4-openssl-dev libexpat1 libncurses5 libncurses5-dev libsigc++-2.0-dev libxml2"
if [[ $http != 'none' ]]; then
PHP="php5 php5-cgi php5-cli php5-common php5-curl php5-gd php5-dev php5-mcrypt php5-mhash php5-mysql php5-suhosin php5-xmlrpc"
fi
	echo -en "${bldred} iNSTALLiNG BASE PACKAGES, this may take a while...${rst}"
	if [[ $DISTRO = 'Ubuntu' ]]; then
		if [[ $NAME = @(karmic|lucid) ]]; then
			packages install $STABLE $DYNAMIC libtorrent-rasterbar5 2>> $LOG ; E_=$?
		elif [[ $NAME = 'jaunty' ]]; then
			packages install $STABLE $DYNAMIC libtorrent-rasterbar2 2>> $LOG ; E_=$?
		elif [[ $NAME = 'maverick' ]]; then
			packages install $STABLE $DYNAMIC libtorrent-rasterbar6 2>> $LOG ; E_=$?
		fi

	elif [[ $DISTRO = @(Debian|LinuxMint) ]]; then
		if [[ $NAME = @(squeeze|debian) ]]; then
			packages install $STABLE $DYNAMIC libtorrent-rasterbar5 2>> $LOG ; E_=$?
		elif [[ $NAME = 'lenny' ]]; then
			packages install $STABLE $DYNAMIC libtorrent-rasterbar0 2>> $LOG ; E_=$?
		fi
	elif [[ $DISTRO = 'Arch' ]]; then
			packages install base-devel fakeroot yaourt php 2>> $LOG ; E_=$?
	fi

	debug_error "Required system packages failed to install"
	log "Base Installation | Completed"
	echo -e "${bldylw} done${rst}"
}

checkout() {  # increase verbosity
	if [[ $DEBUG = 1 ]]; then svn co $@ ; E_=$?
	else svn co -q $@ ; E_=$?
	fi	
}

checkroot() {  # check if user is root
	if [[ $UID = 0 ]]; then echo -e ">>> RooT USeR ChecK...[${bldylw} done ${rst}]"
	if [[ $DEBUG = 1 ]]; then echo -e ">>> Debug Mode ON.....[${bldylw} done ${rst}]"
	fi
	else error "PLEASE RUN WITH SUDO"
	fi
}

cleanup() {  # remove tmp folder and restore permissions
	cd $BASE && rm --recursive --force tmp
	chown -R $USER:$USER $BASE
	log "Removed tmp/ folder"
}

clear_logfile() {  # clear the logfile
	if [[ -f $LOG ]]; then rm --force $LOG ;fi
}

compile() {  # compile with num of threads as cpu cores and time it
	compile_time=$SECONDS
	make -j$CORES $@ ; E_=$?
	let compile_time=$SECONDS-$compile_time
}

ctrl_c() {  # interrupt trap
	log "CTRL-C : abnormal exit detected..."
	echo -en "\n Cleaning up and exiting..."
	cleanup
	echo -e " done \n"
	exit 0
}

debug_error() {  # call this to catch a bad return code and log the error
	if [[ $E_ != 0 ]]; then
		echo -e " Error:${bldred} $1 ${rst} ($E_)"
		log "Error: $1 ($E_)"
		cleanup
		exit 1
	fi
}

debug_wait() {  # prints a message and wait for user before continuing
	if [[ $DEBUG = '1' ]]; then
		echo -e "${bldpur} DEBUG: $1"
		echo -en "${bldpur} Press Enter...${rst}"
		read ENTER
	fi
}

download() {  # show progress bars if debug is on
	if [[ $DEBUG = 1 ]]; then
		 wget --no-verbose $1 ; E_=$?
	else wget --quiet $1      ; E_=$?
	fi
}

error() {  # call this when you know there will be an error
	echo -e " Error:${bldred} $1 ${rst} \n"
	exit
}

extract() {  # find type of compression and extract accordingly
	case $1 in
		*.tar.bz2) tar xjf $1    ;;
		*.tbz2)    tar xjf $1    ;;
		*.tar.gz)  tar xzf $1    ;;
		*.tgz)     tar xzf $1    ;;
		*.tar)     tar xf $1     ;;
		*.gz)      gunzip -q $1  ;;
		*.bz2)     bunzip2 -q $1 ;;
		*.rar)     unrar x $1    ;;
		*.zip)     unzip $1      ;;
		*.Z)       uncompress $1 ;;
		*.7z)      7z x $1       ;;
	esac
}

log() {  # send to the logfile
	echo -e "$1" >> $LOG
}

mkpass() {  # generate a random password of user defined length
	newPass=$(cat /dev/urandom | tr --complement --delete '[:alnum:]' | head -c ${1:-${opt}})
	notice "$newPass"
	exit 0
}

mksslcert() {  # use 2048 bit certs, use sha256, and regenerate
	echo -en "${bldred} Generating SSL Certificate...${rst}"
	sed -i 's:default_bits .*:default_bits = 2048:' /usr/share/ssl-cert/ssleay.cnf
	sed -i 's:default_bits .*:default_bits = 2048:' /etc/ssl/openssl.cnf
	sed -i 's:default_md .*:default_md = sha256:'   /etc/ssl/openssl.cnf
	make-ssl-cert generate-default-snakeoil --force-overwrite
	echo -e "${bldylw} done${rst}"
}

notice() {  # echo status or general info to stdout
	echo -en "\n${bldred} $1... ${rst}\n"
}

packages() {
	if [ $DISTRO = @(Ubuntu|Debian|LinuxMint) ]; then
		case $1 in
			update ) apt-get update -qq              ;;
			upgrade) apt-get upgrade --yes -qq       ;;
			install) apt-get install --yes -qq       ;;
			version) dpkg-query -p $2 | grep Version ;;
			clean  ) apt-get -qq autoclean           ;;
		esac
	elif [ $DISTRO = 'Arch' ]; then
		case $1 in
			update ) pacman --sync --refresh --noconfirm              ;;
			upgrade) pacman --sync --refresh --sysupgrade --noconfirm ;;
			install) pacman --sync --noconfirm                        ;;
			version) pacman -Qi $2 | grep Version                     ;;
			clean  ) pacman --sync --clean -c --noconfirm             ;;
		esac
	elif [ $DISTRO = 'SUSE LINUX' ]; then
		case $1 in
			update ) zypper --quiet refresh                   ;;
			upgrade) zypper --quiet --non-interactive upgrade ;;
			install) zypper --quiet --non-interactive install ;;
			version) zypper info                              ;;
		esac

	#elif [ $DISTRO = "Fedora" ]; then
	#	case $1 in
	#		update ) yum check-update ;;
	#		upgrade) yum update       ;;
	#		install) yum install      ;;
	#		version) yum info         ;;
	#		clean  ) yum clean        ;;
	#	esac
	
	#elif [ $DISTRO = "Gentoo" ]; then
	#	case $1 in
	#		update ) layman -f               ;;
	#		upgrade) emerge -u world         ;;
	#		install) emerge                  ;;
	#		version) emerge -S or emerge -pv ;;
	#		clean  ) emerge --depclean       ;;
	#	esac
	fi
}

usage() {  # help screen
	echo -e "\n${bldpur} Usage:${bldred} $0 ${bldpur}[${bldred}option${bldpur}]"
	echo -e " Options:"
	echo -e " ${bldred}  -p,  --pass ${bldpur}[${bldred}length${bldpur}] ${bldylw}   Generate a strong password"
	echo -e " ${bldred}  -v,  --version ${bldylw}         Show version number\n ${rst}"
	exit 1
}

yes() {  # user input for yes or no
	while read line; do
	case $line in
		y|Y|Yes|YES|yes|yES|yEs|YeS|yeS) return 0
		;;
		n|N|No|NO|no|nO) return 1
		;;
		*) echo -en " Please enter ${undrln}y${rst} or ${undrln}y${rst}: "
		;;
	esac
	done
}

init() {
	clear
	echo -n ">>> iNiTiALiZiNG......"
	OS=$(uname -s)

##[ Determine OS ]##
if [ $OS = "Linux" ] ; then
#[ TODO ]#
	if [ -f /etc/redhat-release ]; then  # check this first, some non rpm distro's include it
		error "TODO - REDHAT"
	elif [ -f /etc/arch-release ]; then
		REPO_PATH=/etc/pacman.conf
	elif [ -f /etc/etc/fedora-release ]; then
		error "TODO - Fedora"
	elif [ -f /etc/gentoo-release ]; then
		error "TODO - Gentoo"
	elif [ -f /etc/slackware-version ]; then
		error "TODO - Slackware"
	elif [ -f /etc/SuSE-release ]; then
		REPO_PATH=/etc/zypp/repos.d/

	else  # we are going to assume a deb based system
		REPO_PATH=/etc/apt/sources.list.d/
	fi
	
	if ! which lsb-release >/dev/null; then  # install lsb-release (debian stable doesnt package it)
		packages install lsb-release
	fi
	# Distributor -i > Ubuntu  > Debian  > Debian   > LinuxMint     > Arch  > SUSE LINUX  (DISTRO)
	# Release     -r > 10.04   > 5.0.6   > testing  > 1|10          > n/a   > 11.4        (RELASE)
	# Codename    -c > lucid   > lenny   > squeeze  > debian|julia  > n/a   > Celadon     (NAME)
	readonly DISTRO=$(lsb_release -is) RELEASE=$(lsb_release -rs) NAME=$(lsb_release -cs) ARCH=$(uname -m) KERNEL=$(uname -r)

	##[ Create folders if not already created ]##
	mkdir --parents tmp/
	mkdir --parents logs/

	iFACE=$(ip route ls | awk '{print $3}' | sed -e '2d')
	iP=$(wget --quiet --timeout=30 www.whatismyip.com/automation/n09230945.asp -O - 2)
	if ! [[ $iP = *.*.* ]]; then
		error "Unable to find ip from outside"
	fi
	readonly iFACE iP USER CORES BASE WEB HOME=/home/${USER} LOG=$BASE/$LOG # make sure these variables aren't overwritten

else error "Unsupported OS"
fi
	packages update  # refresh our package list
	echo -e "[${bldylw} done ${rst}]" ; sleep 1
}

##[ VARiABLE iNiT ]##
CORES=$(grep -c ^processor /proc/cpuinfo)
SSLCERT=/usr/share/ssl-cert/ssleay.cnf
LOG='logs/installer.log'
WEB='/var/www'

#!=====================>> COLOR CONTROL <<=====================!#
##[ echo -e "${txtblu}test ${rst}" ]##
txtblk='\e[0;30m'  # Black ---Regular
txtred='\e[0;31m'  # Red
txtgrn='\e[0;32m'  # Green
txtylw='\e[0;33m'  # Yellow
txtblu='\e[0;34m'  # Blue
txtpur='\e[0;35m'  # Purple
txtcyn='\e[0;36m'  # Cyan
txtwht='\e[0;37m'  # White
bldblk='\e[1;30m'  # Black ---Bold
bldred='\e[1;31m'  # Red
bldgrn='\e[1;32m'  # Green
bldylw='\e[1;33m'  # Yellow
bldblu='\e[1;34m'  # Blue
bldpur='\e[1;35m'  # Purple
bldcyn='\e[1;36m'  # Cyan
bldwht='\e[1;37m'  # White
unkblk='\e[4;30m'  # Black ---Underline
undred='\e[4;31m'  # Red
undgrn='\e[4;32m'  # Green
undylw='\e[4;33m'  # Yellow
undblu='\e[4;34m'  # Blue
undpur='\e[4;35m'  # Purple
undcyn='\e[4;36m'  # Cyan
undwht='\e[4;37m'  # White
bakblk='\e[40m'    # Black ---Background
bakred='\e[41m'    # Red
badgrn='\e[42m'    # Green
bakylw='\e[43m'    # Yellow
bakblu='\e[44m'    # Blue
bakpur='\e[45m'    # Purple
bakcyn='\e[46m'    # Cyan
bakwht='\e[47m'    # White
undrln='\e[4m'     # Underline
rst='\e[0m'        # --------Reset
