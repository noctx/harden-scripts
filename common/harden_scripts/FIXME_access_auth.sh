#!/bin/bash

CRON_TAB='/etc/crontab'
CRON_HR='/etc/cron.hourly'
CRON_DL='/etc/cron.daily'
CRON_WK='/etc/cron.weekly'
CRON_MT='/etc/cron.monthly'
CRON_D='/etc/cron.d'
SSHD_CFG='/etc/ssh/sshd_config_tmp'
SYSTEM_AUTH='/etc/pam.d/system-auth'
PWQUAL_CNF='/etc/security/pwquality.conf'
PASS_AUTH='/etc/pam.d/password-auth'
PAM_SU='/etc/pam.d/su'
GROUP='/etc/group'
BASHRC='/etc/bashrc'
PFL='/etc/profile'
LOGIN_DEFS='/etc/login.defs'
LOG_FILE='./REVIEW_ME.md'

CRON_FL=(${CRON_HR} ${CRON_DL} ${CRON_WK} ${CRON_MT} ${CRON_D})

function check_svc_not_enabled {
	# Verify that the service $1 is not enabled
	local service="$1" 
	systemctl list-unit-files | grep -qv "${service}" && return 
	systemctl is-enabled "${service}" | grep -q 'enabled' || return
}


function check_crond {
	check_svc_not_enabled crond
	if [[ "$?" -ne 0 ]] ; then
		systemctl enable crond
	fi	
	echo "Checked crond" | tee -a ${LOG_FILE}

}

function set_perm_crond {
	for cron_files in ${CRON_FL[*]} ; do
		chown root:root ${cron_files}
		chmod og-rwx ${cron_files}
		echo "Set up permission on ${cron_files}" tee -a ${LOG_FILE}
	done
}

function check_sshd {
	rpm_not_installed openssh-server 
	if [[ "$?" -ne 0 ]] ; then
		yum install openssh-server
	fi
	check_svc_not_enabled sshd
	if [[ "$?" -ne 0 ]] ; then
		systemctl enable sshd
	fi	
	echo "Checked sshd" | tee -a ${LOG_FILE}
}

function setup_sshd {
  	# Check sshd_config file
	echo "sshd : checking config file" tee -a ${LOG_FILE}
	chown root:root ${SSHD_CFG}
	
	grep -q "^Protocol 2" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "Protocol" 2 ${SSHD_CFG}
	fi
	grep -q "^LogLevel INFO" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "LogLevel" "INFO"  ${SSHD_CFG}
	fi
	grep -q "^X11Forwarding no" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "X11Forwarding" "no" ${SSHD_CFG}
	fi
	grep -q "^MaxAuthTries 4" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "MaxAuthTries" 4 ${SSHD_CFG}
	fi
	grep -q "^IgnoreRhosts yes" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "IgnoreRhosts" "yes"  ${SSHD_CFG}
	fi
	grep -q "^HostbasedAuthentication no" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "HostbasedAuthentication" "no"  ${SSHD_CFG}
	fi
	grep -q "^PermitRootLogin no" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "PermitRootLogin" "no" ${SSHD_CFG}
	fi
	grep -q "^PermitEmptyPasswords no" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "PermitEmptyPasswords" "no" ${SSHD_CFG}
	fi
	grep -q "PermitUserEnvironment no" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "PermitUserEnvironment" "no" ${SSHD_CFG}
	fi
	grep -q "^ClientAliveInterval" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "ClientAliveInterval" 300  ${SSHD_CFG}
	fi
	grep -q "^ClientAliveCountMax" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg "ClientAliveCountMax" 0 ${SSHD_CFG}
	fi
	# FIXME Why doesn't it work ?!
	#grep -q "^LoginGraceTime" ${SSHD_CFG} || return
	#if [[ "$?" -ne 0 ]] ; then
	#	correct_cfg "LoginGraceTime" 60 ${SSHD_CFG}
	#fi
	grep -q "^Banner" ${SSHD_CFG} || return
	if [[ "$?" -ne 0 ]] ; then
		echo "Banner /etc/issue.net" >> ${SSHD_CFG}
	fi
	# FIXME MAC encryption !

	# TODO AllowUsers
	echo "Checked sshd" | tee -a ${LOG_FILE}
}

function rpm_not_installed {
  	# Check that the supplied rpm $1 is not installed
  	local rpm="${1}"
  	rpm -q ${rpm} | grep -q "package ${rpm} is not installed" || return
}

function pass_req_params {
  	# Check the pam_pwquality.so params in /etc/pam.d/system-auth
	grep pam_pwquality.so ${SYSTEM_AUTH} | grep 'password' | grep 'requisite' | grep 'try_first_pass' | grep 'local_users_only' | grep 'retry=3' | grep -q 'authtok_type=' || return
  	grep -q '^minlen = 14' ${PWQUAL_CNF} || return
	if [[ "$?" -ne 0 ]] ; then
		echo "minlen = 14" >> ${PWQUAL_CNF}
	fi
  	grep -q '^dcredit = -1' ${PWQUAL_CNF} || return
	if [[ "$?" -ne 0 ]] ; then
		echo "dcredit = -1" >> ${PWQUAL_CNF}
	fi
  	grep -q '^ucredit = -1' ${PWQUAL_CNF} || return
	if [[ "$?" -ne 0 ]] ; then
		echo "ucredit = -1" >> ${PWQUAL_CNF}
	fi
 	grep -q '^ocredit = -1' ${PWQUAL_CNF} || return
	if [[ "$?" -ne 0 ]] ; then
		echo "ocredit = -1" >> ${PWQUAL_CNF}
	fi
  	grep -q '^lcredit = -1' ${PWQUAL_CNF} || return
	if [[ "$?" -ne 0 ]] ; then
		echo "lcredit = -1" >> ${PWQUAL_CNF}
	fi
  	echo "Checked pam_pwquality.so parameters" | tee -a ${LOG_FILE}
}

###########################
# FIXME 
function failed_pass_lock {
 	egrep "auth[[:space:]]+required" ${PASS_AUTH} | grep -q 'pam_deny.so' || return
 	egrep "auth[[:space:]]+required" ${PASS_AUTH} | grep 'pam_faillock.so' | grep 'preauth' | grep 'audit' | grep 'silent' | grep 'deny=5' | grep -q 'unlock_time=900' || return
 	grep 'auth' ${PASS_AUTH} | grep 'pam_unix.so' | egrep -q "\[success=1[[:space:]]+default=bad\]" || return
 	grep 'auth' ${PASS_AUTH} | grep 'pam_faillock.so' | grep 'authfail' | grep 'audit' | grep 'deny=5' | grep 'unlock_time=900' | egrep -q "\[default=die\]" || return
 	egrep "auth[[:space:]]+sufficient" ${PASS_AUTH} | grep 'pam_faillock.so' | grep 'authsucc' | grep 'audit' | grep 'deny=5' | grep -q 'unlock_time=900' || return
 	egrep "auth[[:space:]]+required" ${PASS_AUTH} | grep -q 'pam_deny.so' || return

 	egrep "auth[[:space:]]+required" ${SYSTEM_AUTH} | grep -q 'pam_env.so' || return
 	egrep "auth[[:space:]]+required" ${SYSTEM_AUTH} | grep 'pam_faillock.so' | grep 'preauth' | grep 'audit' | grep 'silent' | grep 'deny=5' | grep -q 'unlock_time=900' || return
 	grep 'auth' ${SYSTEM_AUTH} | grep 'pam_unix.so' | egrep -q "\[success=1[[:space:]]+default=bad\]" || return
 	grep 'auth' ${SYSTEM_AUTH} | grep 'pam_faillock.so' | grep 'authfail' | grep 'audit' | grep 'deny=5' | grep 'unlock_time=900' | egrep -q "\[default=die\]" || return
 	egrep "auth[[:space:]]+sufficient" ${SYSTEM_AUTH} | grep 'pam_faillock.so' | grep 'authsucc' | grep 'audit' | grep 'deny=5' | grep -q 'unlock_time=900' || return
 	egrep "auth[[:space:]]+required" ${SYSTEM_AUTH} | grep -q 'pam_deny.so' || return
}

function lim_passwd_reuse {
 	egrep "auth[[:space:]]+sufficient" ${SYSTEM_AUTH} | grep 'pam_unix.so' | grep -q 'remember=5' || return
}

function su_access {
  	egrep "auth[[:space:]]+required" "${PAM_SU}" | grep 'pam_wheel.so' | grep -q 'use_uid' || return
  	grep 'wheel' "${GROUP}" | cut -d: -f4 | grep -q 'root' || return
}
#
###########################

function check_shdw_param {

	# CIS 7.1.1 Password expiration days
	chk_param "${LOGIN_DEFS}" PASS_MAX_DAYS 90 
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg PASS_MAX_DAYS 90 ${LOGIN_DEFS}
	fi
  	# CIS 7.1.2 Password change minimum number of days
  	chk_param "${LOGIN_DEFS}" PASS_MIN_DAYS 7
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg PASS_MIN_DAYS 7 ${LOGIN_DEFS}
	fi
  	# CIS 7.1.3 Password expiring warning days
  	chk_param "${LOGIN_DEFS}" PASS_WARN_AGE 7
	if [[ "$?" -ne 0 ]] ; then
		correct_cfg PASS_WARN_AGE 7 ${LOGIN_DEFS}
	fi

	# Inactive password lock after 30 days
	useradd -D -f 30	

	# Passwd change date is present
	USR=`cat /etc/shadow | cut -d: -f1`
	for i in ${USR} ; do
		echo ${i} | tee -a ${LOG_FILE}
		chage --list ${i} | grep 'Last password change' | tee -a ${LOG_FILE}
	done
	echo "*******************" >> ${LOG_FILE}
	echo "Users should have a password change DATE in the past" >> ${LOG_FILE}
	echo "If there is a password change in the future, please investigate immediatly" >> ${LOG_FILE}
	echo "*******************" >> ${LOG_FILE}

	# Ensure system accounts are non-login
	echo "*********************" >> ${LOG_FILE}
	echo 'Ensure following system accounts are non-login' | tee -a ${LOG_FILE}
	egrep -v "^\+" /etc/passwd | awk -F: '($1!="root" && $1!="sync" && $1!="shutdown" && $1!="halt" && $3<1000 && $7!="/sbin/nologin" && $7!="/bin/false") {print}'
	# Correct :
	for user in `awk -F: '($3 < 1000) {print $1 }' /etc/passwd` ; do
		echo $user
		if [ $user != "root" ]; then
			usermod -L $user >> ${LOG_FILE}
			if [ $user != "sync" ] && [ $user != "shutdown" ] && [ $user != "halt" ]; then
				usermod -s /sbin/nologin $user >> ${LOG_FILE}
			fi
		fi
	done
	echo "*********************" >> ${LOG_FILE}

	echo "Ensuring default group for root is GID 0" | tee -a ${LOG_FILE}
	
	usermod -g 0 root

	# Set default umask at 027
	correct_cfg umask 027 /etc/bashrc
	correct_cfg umask 027 /etc/profile
	correct_cfg umask 027 /etc/profile.d/*.*sh

	# FIXME Function to clarify code	
	
	grep -q "^TMOUT=600" /etc/bashrc || return
	if [[ "$?" -ne 0 ]] ; then
		echo "TMOUT=600" >> /etc/bashrc
	fi
	grep -q "^TMOUT=600" /etc/profile || return
	if [[ "$?" -ne 0 ]] ; then
		echo "TMOUT=600" >> /etc/profile
	fi
	echo "Checked shadow suite parameters" | tee -a ${LOG_FILE}
}

function root_login_restricted {
	echo "*******************" >> ${LOG_FILE}
	echo "Checking if root login are restricted" | tee -a ${LOG_FILE}
	echo "cat /etc/securetty :" | tee -a ${LOG_FILE}
	cat /etc/securetty | tee -a ${LOG_FILE}
	echo "Please remove entries for any consoles not in a physically secure location" >> ${LOG_FILE}
	echo "*******************" >> ${LOG_FILE}
}

function correct_cfg {
	echo "Correcting configuration ${1}" | tee -a ${LOG_FILE}
	sed -i '/${1}/d' ${3}
	echo "${1} ${2}" >> ${3}
}

function chk_param {
	local file="${1}" 
	local parameter="${2}" 
	local value="${3}" 
	cut -d\# -f1 ${file} | egrep -q "^${parameter}[[:space:]]+${value}" || return
}

function main {
	check_crond
	set_perm_crond
	check_sshd
	setup_sshd
	#pass_req_params
	#failed_pass_lock
	#lim_passwd_reuse
	#su_access

	check_shdw_param
	
	root_login_restricted

}

main
