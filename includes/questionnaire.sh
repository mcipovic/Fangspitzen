##!=======================>> QUESTiONS <<========================!##
while [[ ${skip} = false ]]; do
clear
echo -e "\n ${txtred}-------------->>${bldred} CONFiGURATiON ${txtred}<<---------------${rst}"

read -p "[ HTTP SERVER ]     [apache|lighttp|cherokee|none]: " http
read -p "[ SQL SERVER  ]        [mysql|sqlite|postgre|none]: " sql
read -p "[ FTP SERVER  ]        [vsftp|proftp|pureftp|none]: " ftpd
read -p "[ Torrent App ]      [rtorrent|tranny|deluge|none]: " torrent

if [[ $torrent = 'rtorrent' ]]; then
read -p "[      compile from svn ? ]                  [y|n]: " rtorrent_svn
read -p "[ compile with falloc() ? ]                  [y|n]: " alloc ;fi

read -p "[ ruTorrent WebUi ]                          [y|n]: " webui

if [[ ! -f /usr/local/bin/mktorrent && ! -f /usr/local/bin/buildtorrent ]]; then
read -p "[ MkTorrent or BuildTorrent ]                [m|b]: " buildtorrent
else buildtorrent='n' ;fi

echo -e "\n       **** [ Extra Options ] ****"
read -p " [iRC Bouncer]              [znc|psybnc|sbnc|none]: " bnc
if [[ ! -d /usr/share/webmin ]]; then
read -p " [WebMiN]                                    [y|n]: " webmin
else webmin='i';fi
read -p " [VnStat WebUi]                              [y|n]: " vnstat


#!=====================>> CONFIRMATION <<=======================!#
if [[ $http = 'lighttpd' ]]; then $http='lighttp' ;fi 
echo -e "\n*******************************"
echo -e   "**********${bldred} CONFiRM ${rst}************"
echo -e   "*******************************\n"

##[ Check for HTTP ]##
if [[ $http = 'apache' ]]; then
	v1=$(aptitude show apache2 | grep Version)  # Returns Version number
	v2=$(aptitude show apache2 | grep Package)  # Returns Package name
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $http = 'lighttp' ]]; then
	v1=$(aptitude show lighttpd | grep Version)
	v2=$(aptitude show lighttpd | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $http = 'cherokee' ]]; then
	v1=$(aptitude show cherokee | grep Version)
	v2=$(aptitude show cherokee | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $http = @(none|no|[Nn]) ]]; then
	echo -e "${bldylw} WEB SERVER NOT BEiNG iNSTALLED ${rst}"
else echo -e "${bldred}--> ERROR iN HTTP iNPUT! ${rst}"; http='none'
fi

##[ Check for SQL ]##
if [[ $sql = 'mysql' ]]; then
	v1=$(aptitude show mysql-server | grep Version)
	v2=$(aptitude show mysql-server | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $sql = 'sqlite' ]]; then
	v1=$(aptitude show sqlite3 | grep Version)
	v2=$(aptitude show sqlite3 | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $sql = 'postgre' ]]; then
	v1=$(aptitude show postgresql | grep Version)
	v2=$(aptitude show postgresql | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $sql = @(none|no|[Nn]) ]]; then
	echo -e "${bldylw} SQL SERVER NOT BEiNG iNSTALLED ${rst}"
else echo -e "${bldred}--> ERROR iN SQL iNPUT! ${rst}"; sql='none'
fi

##[ Check for FTP ]##
if [[ $ftpd = 'vsftp' ]]; then
	v1=$(aptitude show vsftpd | grep Version)
	v2=$(aptitude show vsftpd | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}";
elif [[ $ftpd = 'proftp' ]]; then
	v1=$(aptitude show proftpd-basic | grep Version)
	v2=$(aptitude show proftpd-basic | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $ftpd = 'pureftp' ]]; then
	v1=$(aptitude show pure-ftpd | grep Version)
	v2=$(aptitude show pure-ftpd | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $ftpd = @(none|no|[Nn]) ]]; then
	echo -e "${bldylw} FTP SERVER NOT BEiNG iNSTALLED ${rst}"
else echo -e "${bldred}--> ERROR iN FTP iNPUT! ${rst}"; ftpd='none'
fi

##[ Check for Torent Client ]##
if [[ $torrent = 'rtorrent' ]]; then
	if [[ $rtorrent_svn = 'y' ]]; then
		echo -e "${bldblu} Package: rtorrent : Version: 0.8.7~svn r1180 ${rst}"
	else
		echo -e "${bldblu} Package: rtorrent : Version: 0.8.6 ${rst}"
	fi
	if [[ ${alloc} = 'y' ]]; then
		echo -e "${bldpur} Compiling --with-posix-fallocate! ${rst}"
		echo -e "${bldpur} See http://libtorrent.rakshasa.no/ticket/460 for more info and potential dangers. Do not use on ext3 ${rst}\n"
	fi
elif [[ $torrent = 'tranny' ]]; then
	if [[ ${NAME} = 'lenny' ]]; then
		echo -e "${bldred} TODO! ${rst}"
		torrent='none'
	else
		v1=$(aptitude show transmission-daemon | grep Version)
		v2=$(aptitude show transmission-daemon | grep Package)
		echo -e "${bldblu} ${v2} : ${v1} ${rst}"
	fi
elif [[ $torrent = 'deluge' ]]; then
	if [[ ${NAME} = 'lenny' ]]; then
		echo -e "${bldred} TODO! ${rst}"
		torrent='none'
	else
		v1=$(aptitude show deluge | grep Version)
		v2=$(aptitude show deluge | grep Package)
		echo -e "${bldblu} ${v2} : ${v1} ${rst}"
	fi
elif [[ $torrent = @(none|no|[Nn]) ]]; then
	echo -e "${bldylw} TORRENT CLiENT NOT BEiNG iNSTALLED ${rst}"
else echo -e "${bldred}--> ERROR iN TORRENT CLiENT iNPUT! ${rst}"; torrent='none'
fi

if [[ $torrent != @(none|no|[Nn]) ]]; then
	if [[ ${buildtorrent} = 'b' ]]; then
		echo -e "${bldblu} Package: buildtorrent : Version: 0.9~git ${rst}"
	elif [[ ${buildtorrent} = 'm' ]]; then
		echo -e "${bldblu} Package: mktorrent : Version: 1.0~git ${rst}"
	fi
fi

##[ Check for ruTorrent ]##
if [[ $webui = 'y' ]]; then
	echo -e "${bldblu} Package: ruTorrent : Version: 3.1~svn ${rst}"
elif [[ $webui = @(none|no|[Nn]) ]]; then
	echo -e "${bldylw} WEBUi NOT BEiNG iNSTALLED ${rst}"
else echo -e "${bldred}--> ERROR iN WEBUi iNPUT! ${rst}"; webui='n'
fi

##[ Check for BNC ]##
if [[ $bnc = 'znc' ]]; then
	echo -e "${bldblu} Package: ZNC : Version: 0.094 ${rst}"
elif [[ $bnc = 'psybnc' ]]; then
	echo -e "${bldblu} Package: psyBNC : Version: 2.3.2-9 ${rst}"
elif [[ $bnc = 'sbnc' ]]; then
	echo -e "${bldblu} Package: ShroudBNC : Version: 1.3~git ${rst}"
elif [[ $bnc = @(none|no|[Nn]) ]]; then
	echo -e "${bldylw} BOUNCER NOT BEiNG iNSTALLED ${rst}"
else echo -e "${bldred}--> ERROR iN iRC BOUNCER iNPUT! ${rst}"; bnc='none'
fi

##[ Check for WEBMiN ]##
if [[ $webmin = 'y' ]]; then
	v1=$(aptitude show webmin | grep Version)
	v2=$(aptitude show webmin | grep Package)
	echo -e "${bldblu} ${v2} : ${v1} ${rst}"
elif [[ $webmin = 'i' ]]; then
	echo -e "${bldylw} WEBMiN iS ALREADY iNSTALLED ${rst}"
elif [[ $webmin = @(none|no|[Nn]) ]]; then
	echo -e "${bldylw} WEBMiN NOT BEiNG iNSTALLED ${rst}"
else echo -e "${bldred}--> ERROR iN WEBMiN iNPUT! ${rst}"; webmin='n'
fi

##[ Check for VnStat ]##
if [[ $vnstat = 'y' ]]; then
	echo -e "${bldblu} Package: VnStat : Version: 1.10 ${rst}"
elif [[ $vnstat = @(none|no|[Nn]) ]]; then
	echo -e "${bldylw} VNSTAT NOT BEiNG iNSTALLED ${rst}"
else echo -e "${bldred}--> ERROR iN VNSTAT iNPUT! ${rst}"; vnstat='n'
fi

##[ CONFiRMATiON ]##
echo -en "\n Is this correct? [y/n]: "
	if yes; then
		skip=true
		break
	fi
done  # Answer was no, so we loop back and do it again
log "Questionaire | Completed"
