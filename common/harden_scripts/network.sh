#!/bin/bash

LOG_FILE='./REVIEW_ME.md'
SYSCTL_CNF="/etc/sysctl.conf"
GRUB_CFG="/etc/default/grub"
CIS_CONF='/etc/modprobe.d/CIS.conf'
HOSTS_ALLOW='/etc/hosts.allow'
HOSTS_DENY='/etc/hosts.deny'

function chk_sysctl_cnf {
	# Check the sysctl_conf file contains a particular flag, set to a particular value 
	local flag="$1"
	local value="$2"
	local sysctl_cnf="$3"

	cut -d\# -f1 ${sysctl_cnf} | grep "${flag}" | cut -d= -f2 | tr -d '[[:space:]]' | grep -q "${value}" || return
}

function chk_sysctl {
	# Check actual config for a particular flag, set to a particular value 
	local flag="$1"
	local value="$2"

	sysctl "${flag}" | cut -d= -f2 | tr -d '[[:space:]]' | grep -q "${value}" || return
}

function chk_net_cfg {
	# Check systctl and sysctl.conf
	chk_sysctl_cnf ${1} ${2} ${SYSCTL_CNF}
	if [[ "$?" -ne 0 ]] ; then
		cfg_sysctl_cnf ${1} ${2} ${SYSCTL_CNF}
	fi
	chk_sysctl ${1} ${2}
	if [[ "$?" -ne 0 ]] ; then
		cfg_sysctl ${1} ${2}
		if [[ `echo ${1} | grep ipv4` ]] ; then
			cfg_sysctl net.ipv4.route.flush 1
		else
			cfg_sysctl net.ipv6.route.flush 1
		fi
	fi
	echo "Checked network config ${1}" | tee -a ${LOG_FILE}
}

function flush4_sysctl {
	systcl -w net.ipv4.route.flush=1
}

function cfg_sysctl {
	sysctl -w ${1}=${2}
}

function cfg_sysctl_cnf {
	echo "${1} = ${2}" >> ${3}
}

function disable_ipv6 {
	# FIXME Doesn't check every line, only if one has correct option
	if grep -q "ipv6.disable=1" ${GRUB_CFG}
	then
		echo "Disabling ipv6" | tee -a ${LOG_FILE}
	else
		# CIS 3.3.1 If IPv6 enabled IPv6 Router Advertisements should be disabled
		chk_sysctl net.ipv6.conf.all.accept_ra 0
		chk_sysctl net.ipv6.conf.default.accept_ra 0

		# CIS 3.3.2 If IPv6 enabled IPv6 Redirect Acceptance should be disabled
		chk_sysctl net.ipv6.conf.all.accept_redirects 0
		chk_sysctl net.ipv6.conf.default.accept_redirects 0

		# CIS 3.3.3 IPv6 disabled
		sed -i '/GRUB_CMDLINE_LINUX/s/.$//' ${GRUB_CFG}
		sed -i '/GRUB_CMDLINE_LINE/s/$/ ipv6.disable=1\"/' ${GRUB_CFG}
		grub2-mkconfig > /boot/grub2/grub.cfg

		echo "Disabling ipv6" | tee -a ${LOG_FILE}
	fi
}

function ipv4_cfg {

# CIS 3.2.1 IP Forwarding should be disabled
	chk_net_cfg net.ipv4.ip_forward 0

# Send Packet Redirects should be disabled
	chk_net_cfg net.ipv4.conf.all.send_redirects 0
	chk_net_cfg net.ipv4.conf.default.send_redirects 0

# Source Routed Packet Acceptance should be disabled
	chk_net_cfg net.ipv4.conf.all.accept_source_route 0
	chk_net_cfg net.ipv4.conf.default.accept_source_route 0

# 3.2.2 ICMP Redirect Acceptance should be disabled
	chk_net_cfg net.ipv4.conf.all.accept_redirects 0
	chk_net_cfg net.ipv4.conf.default.accept_redirects 0

# CIS 3.2.3 Secure ICMP Redirect Acceptance should be disabled
	chk_net_cfg net.ipv4.conf.all.secure_redirects 0
	chk_net_cfg net.ipv4.conf.all.secure_redirects 0
	chk_net_cfg net.ipv4.conf.default.secure_redirects 0

# CIS 3.2.4 Log Suspicious Packets
	chk_net_cfg net.ipv4.conf.all.log_martians 1
	chk_net_cfg net.ipv4.conf.default.log_martians 1

# CIS 3.2.5 Ignore Broadcast Requests should be enabled
	chk_net_cfg net.ipv4.icmp_echo_ignore_broadcasts 1

# CIS 3.2.6 Bad Error Message Protection should be enabled
	chk_net_cfg net.ipv4.icmp_ignore_bogus_error_responses 1

# CIS 3.2.7 RFC-recommended Source Route Validation should be enabled
	chk_net_cfg net.ipv4.conf.all.rp_filter 1
	chk_net_cfg net.ipv4.conf.default.rp_filter 1

# CIS 3.2.8 TCP SYN Cookies should be enabled
	chk_net_cfg net.ipv4.tcp_syncookies 1

# TODO CIS 4.3.1 Check Wireless Interfaces are deactivated

# 3.3 IPv6
	disable_ipv6
}

function disable_np {
	echo "Disabling ${1}" | tee -a ${LOG_FILE}
	if ! grep -q "install ${1} /bin/true" ${CIS_CONF}
	then
		echo "install ${1} /bin/true" >> ${CIS_CONF}
	fi
}

function setup_fw {
	# FIXME Place this in another file for clarity
	# Flush Iptables rules
	iptables -F
	
	# Ensure default deny firewall policy
	iptables -P INPUT DROP
	iptables -P OUTPUT DROP
	iptables -P FORWARD DROP
	
	# Ensure loopback traffic is configured
	iptables -A INPUT -i lo -j ACCEPT
	iptables -A OUTPUT -o lo -j ACCEPT
	iptables -A INPUT -s 127.0.0.0/8 -j DROP
	
	# Ensure outbound and established connections are configured
	iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
	
	# Open inbound ssh(tcp port 22) connections
	iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
	echo "Set up firewall" | tee -a ${LOG_FILE}
}

function rpm_installed {
	# Test whether a rpm is installed
	local rpm="${1}"
	local rpm_out="$(rpm -q --queryformat "%{NAME}\n" ${rpm})"
	[[ "${rpm}" = "${rpm_out}" ]] || return
}

function rpm_not_installed {
	# Check that the supplied rpm $1 is not installed
	local rpm="${1}"
	rpm -q ${rpm} | grep -q "package ${rpm} is not installed" || return
}

function restrict_perm {
	echo "Restricting permissions (${2}) on ${1}" | tee -a ${LOG_FILE}
	chown root:root ${1}
	chmod ${2} ${1}
}

function chk_ipt {
	rpm_not_installed iptables
	if [[ "$?" -eq 0 ]] ; then
		yum install iptables
	fi
	echo "Checked iptables install" | tee -a ${LOG_FILE}
}

function chk_tcpwrappers {
	rpm_not_installed tcp_wrappers
	if [[ "$?" -eq 0 ]] ; then
		yum install tcp_wrappers
	fi
	rpm_not_installed tcp_wrappers-libs
	if [[ "$?" -eq 0 ]] ; then
		yum install tcp_wrappers-libs
	fi
	echo "Checked tcp_wrappers install" | tee -a ${LOG_FILE}
}

function cfg_hosts {
	echo "*********************" >> ${LOG_FILE}
	echo "Configuring hosts/allow/deny" | tee -a ${LOG_FILE}
	echo "Please add to /etc/hosts.allow IP your organization is using" | tee -a ${LOG_FILE}
	echo "ALL: <net>/<mask>, <net>/<mask>, ..." >> ${LOG_FILE}
	if ! grep -q "^ALL: ALL"  ${HOSTS_DENY}
	then
		echo "#ALL: ALL" >> ${HOSTS_DENY}
	fi	
	echo "Configuring hosts.deny is disabled to prevent from locking yourself out if you're connected via ssh" | tee -a ${LOG_FILE}
	echo "*********************" >> ${LOG_FILE}
}

function main {

	ipv4_cfg	
	chk_ipt
# CIS 3.4.1 Check that TCP Wrappers are installed
# FIXME Verify services supporting TCP Wrappers ?
	chk_tcpwrappers

# CIS 3.4.2/3.4.3
	cfg_hosts

# CIS 3.4.4 Perm on hosts
	restrict_perm ${HOSTS_ALLOW} 644
	restrict_perm ${HOSTS_DENY} 644

# CIS 3.5
	disable_np dccp
 	disable_np sctp
	disable_np rds
	disable_np tipc

# CIS 3.6 Firewall Cfg
	setup_fw

# TODO Check for wireless interfaces and disable them


}

main

