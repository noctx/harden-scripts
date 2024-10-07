#!/bin/sh

LOG_FILE='./REVIEW_ME.md'
FSTAB='/etc/fstab'
CIS_CONF='/etc/modprobe.d/CIS.conf'
SYSCTL_CNF="/etc/sysctl.conf"
MOTD='/etc/motd'
OPT=('nodev' 'nosuid' 'noexec')

# FIXME First replacement doesn't work
function modify_part_opt {
	sed -i "/${1}/ s/\(defaults,\)/\1${2},/" ${FSTAB}
}

function chk_tmp {
	for opt in ${OPT[*]} ; do
		if grep -q " /tmp" ${FSTAB}; then
			if ! grep -q ${opt} ${FSTAB}
			then
				modify_part_opt ' \/tmp' ${opt}
			fi
		fi
	done
	echo "Checked partition options : ${OPT[*]} for /tmp"
}

function chk_var_tmp {
	for opt in ${OPT[*]} ; do
		if grep -q " /var/tmp" ${FSTAB}; then
			if ! grep -q ${opt} ${FSTAB}
			then
				modify_part_opt ' \/var\/tmp' ${opt}
			fi
		fi
	done
	echo "Checked partition options : ${OPT[*]} for /var/tmp"
}

function chk_home {
	if grep -q " /home" ${FSTAB}; then
		if ! grep -q 'nodev' ${FSTAB}
		then
				modify_part_opt ' \/home' ${opt}
		fi
	fi
	echo "Checked partition option nodev for /home"
}

function chk_dev_shm {
	for opt in ${OPT[*]} ; do
		if grep -q " /dev/shm" ${FSTAB}; then
			if ! grep -q ${opt} ${FSTAB}
			then
				modify_part_opt ' \/dev\/shm' ${opt}
			fi
		fi
	done
	echo "Checked partition options : ${OPT[*]} for /dev/shm"
}

function disable_fs {
	echo "Disabling ${1}" | tee -a ${LOG_FILE}
	if ! grep -q "install ${1} /bin/true" ${CIS_CONF}
	then
		echo "install ${1} /bin/true" >> ${CIS_CONF}
	fi
	# FIXME Should we use modprobe with -r option instead ?
	if lsmod | grep -q ${1}
	then
		rmmod ${1} >> ${LOG_FILE}
	fi
}

function set_sticky_bit {
	echo "Ensure sticky bit is on set on all world-writable directories" | tee -a ${LOG_FILE}
	df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t
}

function disable_svc {
	echo "Disabling ${1}" | tee -a ${LOG_FILE}
	if systemctl list-unit-files | grep -q "autofs"
	then
		systemctl -q disable ${1}
	fi
}

function install_rpm {
	yum install ${1}
}

function remove_rpm {
	echo "Removing ${1}" | tee -a ${LOG_FILE}
	yum remove ${1}
}

function rpm_not_installed {
	# Check that the supplied rpm $1 is not installed
	local rpm="${1}"
	rpm -q ${rpm} | grep -q "package ${rpm} is not installed" || return
}

function aide_init {
	rpm_not_installed aide 
	if [[ "$?" -eq 0 ]] ; then
		install_rpm aide
		aide --init
		mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
	fi
	echo "Checked aide install" | tee -a ${LOG_FILE}
}

function filesystem_integrity {
	echo "Checking filesystem integrity" | tee -a ${LOG_FILE}
	echo "|-- TODO !" | tee -a ${LOG_FILE}
}

function grub_perm {
	chown root:root /boot/grub2/grub.cfg
	chmod og-rwx /boot/grub2/grub.cfg
	chown root:root /boot/grub2/user.cfg
	chmod og-rwx /boot/grub2/user.cfg
}

function grub_pass {
	echo "Enter GRUB password (20 min char.)"
	echo "WARNING : keyboard might not be correct when booting"
	grub2-setpassword
}

function single_user_mode {
	echo "Ensure authentication is required for single user mode" | tee -a ${LOG_FILE}
	echo 'ExecStart=-/bin/sh -c "/sbin/sulogin; /usr/bin/systemtl --fail --no-block default"' >> /sbin/sulogin /usr/lib/systemd/system/rescue.service
	echo 'ExecStart=-/bin/sh -c "/sbin/sulogin; /usr/bin/systemtl --fail --no-block default"' >> /sbin/sulogin /usr/lib/systemd/system/emergency.service
}

function restrict_core_dump {
	echo "Restricting core dumps" | tee -a ${LOG_FILE}
	echo "* hard core 0" >> /etc/security/limits.conf
	echo "fs.suid_dumpable=0" >> /etc/sysctl.conf
	sysctl -w fs.suid_dumpable=0 > /dev/null
}

function enable_aslr {
	if grep -v "kernel.randomize_va_space = 2" /etc/sysctl.conf > /dev/null
	then
		echo "Enabling address space layout randomization" | tee -a ${LOG_FILE}
		sed -i '/kernel.randomize_va_space/d' ${SYSCTL_CNF}
		echo "kernel.randomize_va_space = 2" >> ${SYSCTL_CNF}
	fi
	sysctl -w kernel.randomize_va_space=2 > /dev/null
}

function restrict_perm {
	echo "Restricting permissions (${2}) on ${1}" | tee -a ${LOG_FILE}
	chown root:root ${1}
	chmod ${2} ${1}
}

function confine_daemons {
	echo "*********************" >> ${LOG_FILE}
	echo "Checking for unconfined daemons" |tee -a ${LOG_FILE}
	echo "Please review these files as the "other" category has write access to it, which is not advisable." >> ${LOG_FILE}
	ps -eZ | egrep "initrc" | egrep -vw "tr|ps|egrep|bash|awk" | tr ':' ' ' | awk '{ print $NF }'
	echo "*********************" >> ${LOG_FILE}
}

function config_motd {
	echo "Configuring motd" | tee -a ${LOG_FILE}
	rm -f ${MOTD}
	echo '' > ${MOTD}
	echo 'Welcome back' >> ${MOTD}
	echo '' >> ${MOTD}
	restrict_perm ${MOTD} 644
}

function banner {
	echo "Configuring banners" | tee -a ${LOG_FILE}
	rm -f /etc/issue /etc/issue.net
	touch /etc/issue /etc/issue.net
	echo 'Thales Service' | tee -a /etc/issue /etc/issue.net 1>/dev/null
	echo 'Authorized uses only. All activity will be monitored and reported.' | tee -a /etc/issue /etc/issue.net 1>/dev/null
	echo 'Violators will be prosecuted.' | tee -a /etc/issue /etc/issue.net 1>/dev/null
	restrict_perm /etc/issue 644
	restrict_perm /etc/issue.net 644
}

function main {

 FIXME Verify if CIS_CONF exists ?
	touch ${CIS_CONF}

# Unused filesystems
	disable_fs cramfs
	disable_fs freevxfs
	disable_fs jffs2
	disable_fs hfs
	disable_fs hfsplus
	disable_fs squashfs
	disable_fs udf
	disable_fs vfat

# 1.12 to 1.1.20
# FIXME Check removable media for nodev option (not scored)
	chk_tmp
	chk_var_tmp
	chk_home
	chk_dev_shm

	set_sticky_bit
	disable_svc autofs

# TODO Verify repolist 
# TODO Verify gpgcheck

	aide_init

## FIXME :
	filesystem_integrity

	single_user_mode

	restrict_core_dump
	
	enable_aslr

	remove_rpm prelink
	remove_rpm mcstrans

	confine_daemons

	config_motd
	banner
}

main

