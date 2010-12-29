##!=======================>> FUNCTiONS <<=======================!##
base_install() {  # install dependencies
COMMON="apache2-utils autoconf automake binutils bzip2 ca-certificates cpp curl fail2ban file gamin gcc git-core gzip htop iptables libexpat1 libtool libxml2 m4 make openssl patch perl pkg-config python python-gamin python-openssl python-setuptools screen subversion sudo unrar unzip zip"
DYNAMIC="libcurl3 libcurl3-gnutls libcurl4-openssl-dev libncurses5 libncurses5-dev libsigc++-2.0-dev"

DEBIAN="$COMMON $DYNAMIC apt-show-versions autotools-dev build-essential cfv comerr-dev dtach g++ libcppunit-dev libperl-dev libssl-dev libterm-readline-gnu-perl libtorrent-rasterbar-dev ncurses-base ncurses-bin ncurses-term perl-modules ssl-cert"
SUSE="$COMMON libcppunit-devel libcurl4 libopenssl-devel libtorrent-rasterbar-devel ncurses-devel libncurses6 libsigc++2-devel"
ARCHLINUX="base-devel yaourt"  # TODO

PHP_COMMON="php5 php5-curl php5-gd php5-mcrypt php5-mysql php5-suhosin php5-xmlrpc"

PHP_DEBIAN="$PHP_COMMON php5-cgi php5-cli php5-common php5-dev php5-mhash"
PHP_SUSE="$PHP_COMMON php5-devel"
PHP_ARCHLINUX="php php-cgi"  # TODO

	echo -en "${bldred} iNSTALLiNG BASE PACKAGES, this may take a while...${rst}"

	case "$DISTRO" in
		Ubuntu|[Dd]ebian|*Mint) packages install $DEBIAN    ;;
		ARCH*|[Aa]rch*        ) packages install $ARCHLINUX ;;
		SUSE*|[Ss]use*        ) packages install $SUSE      ;;
	esac

	if_error "Required system packages failed to install"
	log "Base Installation | Completed"
	echo -e "${bldylw} done${rst}"
}

checkout() {  # increase verbosity
	if [[ $DEBUG = 1 ]]; then svn co $@ ; E_=$?
	else svn co -q $@ ; E_=$?
	fi	
}

checkroot() {  # check if user is root
	[[ $UID = 0 ]] &&
		echo -e ">>> RooT USeR ChecK...[${bldylw} done ${rst}]" ||
		error "PLEASE RUN WITH SUDO"
}

cleanup() {  # remove tmp folder and restore permissions
	cd $BASE && rm --recursive --force tmp
	chown -R $USER $BASE
	log "Removed tmp/ folder"
}

clear_logfile() {  # clear the logfile
	[[ -f $LOG ]] && rm --force $LOG
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
	echo -e " Error:${bldred} $1 ${rst} \n" ;exit 1
}

extract() {  # find type of compression and extract accordingly
	case "$1" in
		*.tar.bz2) tar xjf    $1 ;;
		*.tbz2   ) tar xjf    $1 ;;
		*.tar.gz ) tar xzf    $1 ;;
		*.tgz    ) tar xzf    $1 ;;
		*.tar    ) tar xf     $1 ;;
		*.gz     ) gunzip -q  $1 ;;
		*.bz2    ) bunzip2 -q $1 ;;
		*.rar    ) unrar x    $1 ;;
		*.zip    ) unzip      $1 ;;
		*.Z      ) uncompress $1 ;;
		*.7z     ) 7z x       $1 ;;
	esac
}

if_error() {  # call this to catch a bad return code and log the error
	if [[ $E_ != 0 ]]; then
		echo -e " Error:${bldred} $1 ${rst} ($E_)"
		log "Error: $1 ($E_)"
		cleanup ;exit 1
	fi
}

log() {  # send to the logfile
	echo -e "$1" >> $LOG
}

mkpass() {  # generate a random password of user defined length
	newPass=$(tr -cd '[:alnum:]' < /dev/urandom | head -c ${1:-${passwdlength}})
	notice "$newPass" ;exit 0
}

mksslcert() {  # use 2048 bit certs, use sha256, and regenerate
	if [[ $1 = 'generate-default-snakeoil' ]]; then  # called once after questionaire exits
		sed -i 's:default_bits .*:default_bits = 2048:' /etc/ssl/openssl.cnf
		sed -i 's:default_md .*:default_md = sha256:'   /etc/ssl/openssl.cnf
		if which make-ssl-cert >/dev/null; then
			echo -en "${bldred} Generating SSL Certificate...${rst}"
			sed -i 's:default_bits .*:default_bits = 2048:' $SSLCERT
			make-ssl-cert $1 --force-overwrite
			echo -e "${bldylw} done${rst}"
		fi
	else
		openssl genrsa -des3 -out $1 1024  # generate single key file
		[[ $2 ]] && openssl rsa -in $1 -out $2 || openssl rsa -in $1 -out $1  # 2nd arg creates separate .pem and .key files
		[[ $3 ]] && openssl req -new -key $2 -days 3650 -out $3 -x509 -subj '/C=AN/ST=ON/L=YM/O=OU/CN=S/emailAddress=dev@slash.null'  # a 3rd arg creates a .crt file
		chmod 400 $@  # Read write permission for owner only
	fi
}

notice() {  # echo status or general info to stdout
	echo -en "\n${bldred} $1... ${rst}\n"
}

packages() {  # use appropriate package manager depending on distro
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
	   [[ $DEBUG != 1 ]] && quiet='-qq'
		case "$1" in
			addkey )
					apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $2 ;;
			clean  )
					apt-get -qq autoclean
					alias_autoclean="apt-get autoremove && apt-get autoclean"   ;;
			install) shift  # forget $1
					apt-get install --yes $quiet $@ 2>> $LOG; E_=$?
					alias_install="apt-get install"    ;;
			remove ) shift
					apt-get autoremove --yes $quiet $@ 2>> $LOG; E_=$?
					alias_remove="apt-get autoremove"  ;;
			update )
					apt-get update $quiet
					alias_update="apt-get update"      ;;
			upgrade) 
					apt-get upgrade --yes $quiet
					alias_upgrade="apt-get upgrade"    ;;
			version)
					dpkg-query -p $2 | grep Version:   ;;
			setvars)
					REPO_PATH=/etc/apt/sources.list.d  ;;
		esac
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		 [[ $DEBUG != 1 ]] && quiet='--noconfirm'
		case "$1" in
			clean  )
					pacman --sync --clean -c $quiet
					alias_autoclean="pacman -Scc" ;;
			install) shift
					pacman --sync $quiet $@ 2>> $LOG; E_=$?
					alias_install="pacman -S"     ;;
			remove ) shift
					pacman --remove $@ 2>> $LOG; E_=$?
					alias_remove="pacman -R"      ;;
			update )
					pacman --sync --refresh $quiet
					alias_update="pacman -Sy"     ;;
			upgrade)
					pacman --sync --refresh --sysupgrade $quiet
					alias_upgrade="pacman -Syu"   ;;
			version)
					pacman -Qi $2 | grep Version: ;;
			setvars)
					REPO_PATH=/etc/pacman.conf    ;;
		esac
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		 [[ $DEBUG != 1 ]] && quiet='--quiet'
		case "$1" in
			addrepo) shift
					zypper --no-gpg-checks --gpg-auto-import-keys addrepo --refresh $@ 2>> $LOG ;;
			clean  )
					zypper $quiet clean
					alias_autoclean="zypper clean" ;;
			install) shift
					zypper $quiet --non-interactive install $@ 2>> $LOG; E_=$?
					alias_install="zypper install" ;;
			remove ) shift
					zypper $quiet remove $@ 2>> $LOG; E_=$?
					alias_remove="zypper remove"   ;;
			update )
					zypper $quiet refresh
					alias_update="zypper refresh"  ;;
			upgrade)
					zypper $quiet --non-interactive update --auto-agree-with-licenses
					alias_upgrade="zypper update"  ;;
			version)
					zypper info $2 | grep Version: ;;
			setvars)
					REPO_PATH=/etc/zypp/repos.d    ;;			
		esac

	elif [[ $DISTRO = "Fedora" ]]; then
		 [[ $DEBUG != 1 ]] && quiet=''
		case "$1" in
			clean  )
					yum clean all -y
					alias_autoclean="yum clean all" ;;
			install) shift
					yum install -y $@ 2>> $LOG; E_=$?
					alias_install="yum install"     ;;
			remove ) shift
					yum remove -y $@ 2>> $LOG; E_=$?
					alias_remove="yum remove"       ;;
			update )
					yum check-update -y
					alias_update="yum check-update" ;;
			upgrade)
					yum upgrade -y
					alias_upgrade="yum upgrade"     ;;
			version)
					yum info $2 | grep Version:     ;;
			setvars)
					REPO_PATH=/etc/yum/repos.d/     ;;
		esac

	elif [[ $DISTRO = "Gentoo" ]]; then
		 [[ $DEBUG != 1 ]] && quiet='--quiet'
		case "$1" in
			clean  )
					emerge --clean  # --depclean
					alias_autoclean="emerge --clean" ;;
			install) shift
					emerge $quiet --jobs=$CORES $@ 2>> $LOG; E_=$?
					alias_install="emerge"           ;;
			remove ) shift
					emerge --unmerge $quiet $@ 2>> $LOG; E=$?
					alias_remove="emerge -C"         ;;
			update )
					emerge --sync
					alias_update="emerge --sync"     ;;
			upgrade)
					emerge --update world $quiet  # --deep
					alias_upgrade="emerge -u world"  ;;
			version)
					emerge -S or emerge -pv          ;;
			setvars) ;;  # TODO
		esac
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
	case "$line" in
		y|Y|Yes|YES|yes) return 0 ;;
		n|N|No|NO|no) return 1 ;;
		*) echo -en " Please enter ${undrln}y${rst} or ${undrln}y${rst}: " ;;
	esac;done
}

init() {
	clear ; echo -n ">>> iNiTiALiZiNG......"
	OS=$(uname -s)

	##[ Determine OS ]##
if [[ $OS = "Linux" ]] ; then
	[[ -f /etc/fedora-release ]] && error "TODO - Fedora"
	[[ -f /etc/gentoo-release ]] && error "TODO - Gentoo"

	if [[ -f /etc/SuSE-release ]]; then
		if ! which lsb_release >/dev/null; then  # install lsb_release (distros dont like to keep things simple)
			packages install lsb_release ;fi
	else
		if ! which lsb-release >/dev/null; then  # install lsb-release (debian stable doesnt package it)
			packages install lsb-release lsb_release ;fi
	fi

	# Distributor -i > Ubuntu  > Debian  > Debian   > LinuxMint     > Arch  > SUSE LINUX  (DISTRO)
	# Release     -r > 10.04   > 5.0.6   > testing  > 1|10          > n/a   > 11.3        (RELASE)
	# Codename    -c > lucid   > lenny   > squeeze  > debian|julia  > n/a   > n/a         (NAME)
	readonly DISTRO=$(lsb_release -is) RELEASE=$(lsb_release -rs) NAME=$(lsb_release -cs) ARCH=$(uname -m) KERNEL=$(uname -r)

	##[ Create folders if not already created ]##
	mkdir --parents tmp/
	mkdir --parents logs/

	iP=$(wget --quiet --timeout=30 www.whatismyip.com/automation/n09230945.asp -O - 2)
	[[ $iP != *.*.* ]] && error "Unable to find ip from outside"

	readonly iP USER CORES BASE WEB HOME=/home/$USER LOG=$BASE/$LOG # make sure these variables aren't overwritten
	packages setvars  # just sets REPO_PATH= at the moment
	else error "Unsupported OS"
fi
	echo -e "[${bldylw} done ${rst}]" ;sleep 1
}

##[ VARiABLE iNiT ]##
CORES=$(grep -c ^processor /proc/cpuinfo)
SSLCERT=/usr/share/ssl-cert/ssleay.cnf
LOG=logs/installer.log
iFACE=eth0
WEB=/var/www

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
