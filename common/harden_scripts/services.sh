#!/bin/bash

LOG_FILE='./REVIEW_ME.md'
NTP_CNF='/etc/ntp.conf'

function disable_svc {
	systemctl disable ${1}
}

function install_rpm {
	rpm_installed ${1}
	if [[ "$?" -ne 0 ]] ; then
		yum install ${1}
	fi
	echo "Checked ${1} install" | tee -a ${LOG_FILE}
}

function remove_rpm {
	rpm_not_installed ${1}
	if [[ "$?" -ne 0 ]] ; then
		yum remove ${1}
	fi
	echo "Checked ${1} install" | tee -a ${LOG_FILE}
}

function disable_inetd_svc {
	SVC='chargen-dgram chargen-stream daytime-dgram daytime-stream
		discard-dgram discard-stream echo-dgram echo-stream
		time-dgram time-stream tftp xinetd'
	
	for serv in ${SVC}
	do
		check_svc_not_enabled ${serv}
		if [[ "$?" -ne 0 ]] ; then	
			disable_svc ${serv}
		fi
		echo "Disabling ${serv}" | tee -a ${LOG_FILE}
	done	
}


function disable_daemons {
	DMN='avahi-daemon cups dhcpd slapd nfs nfs-server rpcbind named
			vsftpd httpd dovecot smb squid snmpd ypserv rsh.socket rlogin.socket
			rexec.socket telnet.socket tftp.socket rsyncd ntalk'
	for dmn in ${DMN}
	do
		check_svc_not_enabled ${dmn}
		if [[ "$?" -ne 0 ]] ; then	
			disable_svc ${dmn}
		fi
		echo "Disabling ${dmn}" | tee -a ${LOG_FILE}
	done
}

function check_svc_not_enabled {
  	# Verify that the service $1 is not enabled
  	local service="$1" 
  	if [[ `systemctl list-unit-files | grep "${service}"` ]] ; then 
  		if [[ `systemctl is-enabled "${service}" | grep 'enabled'` ]] ; then
			return 1
		fi
	fi
	return 0
}

function rpm_installed {
	# Test whether an rpm is installed
	local rpm="${1}"
	local rpm_out
	rpm_out="$(rpm -q --queryformat "%{NAME}\n" ${rpm})"
	[[ "${rpm}" = "${rpm_out}" ]] || return
}

function rpm_not_installed {
	# Check that the supplied rpm $1 is not installed
	local rpm="${1}"
	rpm -q ${rpm} | grep -q "package ${rpm} is not installed" || return
}

function config_ntp {
	restrict_4="restrict -4 default kod nomodify notrap nopeer noquery"
	restrict_6="restrict -6 default kod nomodify notrap nopeer noquery"
	if ! grep -q "${restrict_4}" ${NTP_CNF}
	then
		echo ${restrict_4} >> ${NTP_CNF}
	fi
	if ! grep -q "${restrict_6}" ${NTP_CNF}
	then
		echo ${restrict_6} >> ${NTP_CNF}
	fi
	if ! egrep -q "^(server|pool)" ${NTP_CNF}
	then
		echo "server 0.centos.pool.ntp.org iburst" >> ${NTP_CNF} 
		echo "server 1.centos.pool.ntp.org iburst" >> ${NTP_CNF} 
		echo "server 2.centos.pool.ntp.org iburst" >> ${NTP_CNF} 
		echo "server 3.centos.pool.ntp.org iburst" >> ${NTP_CNF} 
	fi
	if grep -qv "^OPTIONS" ${NTP_CNF} | grep "-u ntp:ntp" ${NTP_CNF}
	then
		sed -i '/OPTIONS/s/.$//' ${GRUB_CFG}
		sed -i '/OPTIONS/s/$/ -u ntp:ntp\"/' ${GRUB_CFG}
	fi
	echo "Congigured ntp" | tee -a ${LOG_FILE}
}


function main {

	disable_inetd_svc

	install_rpm ntp

	config_ntp

	remove_rpm xorg-x11*	

	disable_daemons	

	remove_rpm ypbind
	remove_rpm rsh
	remove_rpm talk
	remove_rpm telnet
	remove_rpm openldap-clients
}

main
