#!/bin/bash

AUDITD_CNF='/etc/audit/auditd.conf'
GRUB_CFG='/etc/default/grub'
AUDIT_RULES='/etc/audit/rules.d/audit.rules'
AUDIT_STP='./rules'
LOG_FILE='./REVIEW_ME.md'

function check_svc_not_enabled {
	# Verify that the service $1 is not enabled
	local service="$1" 
	systemctl list-unit-files | grep -qv "${service}" && return 
	systemctl is-enabled "${service}" | grep -q 'enabled' || return
}

function check_auditd {
	check_svc_not_enabled auditd
	if [[ "$?" -ne 0 ]] ; then
		systemctl enable auditd
	fi	
	echo "Checked auditd" | tee -a ${LOG_FILE}

}

function audit_log_storage_size {
	# Check the max size of the audit log file is configured
	# FIXME Doesn't check value (must be greater than 6)
	cut -d\# -f1 ${AUDITD_CNF} | egrep -q "max_log_file[[:space:]]|max_log_file=" || return
	if [[ "$?" -ne 0 ]] ; then
		echo "max_log_file = 8"	>> ${AUDITD_CNF}
	fi	
 	echo "Checked auditd : max_log_file" | tee -a ${LOG_FILE}
}


function dis_on_audit_log_full {
  	# Check auditd.conf is configured to notify the admin and halt the system when audit logs are full
	sed -i '/space_left_action/d' ${AUDITD_CNF}
	sed -i '/action_mail_acct/d' ${AUDITD_CNF}
	sed -i '/admin_space_left_action/d' ${AUDITD_CNF}
	sed -i '/max_log_file_action/d' ${AUDITD_CNF}
	echo "space_left_action = email" >> ${AUDITD_CNF}
	echo "action_mail_acct = root" >> ${AUDITD_CNF}
	echo "admin_space_left_action = halt" >> ${AUDITD_CNF}
	echo "max_log_file_action = keep_logs" >> ${AUDITD_CNF}
	echo "Checked auditd : action on full logs" | tee -a ${LOG_FILE}
}

function audit_preboot {
	# FIXME Doesn't check every line, only if one has correct option
	if grep "audit=1" ${GRUB_CFG} > /dev/null
	then
		# FIXME
		echo "" > /dev/null
	else
		sed -i '/GRUB_CMDLINE_LINUX/s/.$//' ${GRUB_CFG}
		sed -i '/GRUB_CMDLINE_LINUX/s/$/ audit=1\"/' ${GRUB_CFG}
		grub2-mkconfig > /boot/grub2/grub.cfg
	fi
	echo "Checked auditd : preboot action" | tee -a ${LOG_FILE}
}

function set_audit_rules {
	# Add rules for auditd
	rm -f ${AUDIT_RULES}
	touch ${AUDIT_RULES}
	cat ${AUDIT_STP} >> ${AUDIT_RULES}

	# Collect use of privileged commands
	# Add each line output to audit.rules
	find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit -F path=" $1 " -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged" }' >> ${AUDIT_RULES}

	echo "#Ensure configuration is immutable" | tee -a ${LOG_FILE} ${AUDIT_RULES} 1>/dev/null
	echo "-e 2" >> ${AUDIT_RULES}
	echo "Checked auditd : audit rules"  | tee -a ${LOG_FILE}
	echo "System will need to be a reboot" | tee -a ${LOG_FILE}
	# Reload service
	# Might need a reboot to take fully effect
	systemctl reload auditd
}


function check_rsyslog {
	rpm_not_installed rsyslog
	if [[ "$?" -ne 0 ]] ; then
		yum install rsyslog
	fi
	check_svc_not_enabled rsyslog
	if [[ "$?" -ne 0 ]] ; then
		systemctl enable rsyslog
	fi	
	echo "Checked rsyslog" | tee -a ${LOG_FILE}
}

function rpm_not_installed {
  # Check that the supplied rpm $1 is not installed
  local rpm="${1}"
  rpm -q ${rpm} | grep -q "package ${rpm} is not installed" || return
}

function setup_rsyslog {
	# TODO
	echo "RSYSLOG : TODO" | tee -a ${LOG_FILE}
}

function main {

	check_auditd
	audit_log_storage_size
	dis_on_audit_log_full
	audit_preboot
	set_audit_rules
	check_rsyslog
	setup_rsyslog
}

main
