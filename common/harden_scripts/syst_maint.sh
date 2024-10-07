#!/bin/bash

LOG_FILE='./REVIEW_ME.md'

function sys_file_perm {
	echo "*********************" >> ${LOG_FILE}
	echo "Auditing system file permissions" | tee -a ${LOG_FILE}
	echo "Please review all following installed package" >> ${LOG_FILE}
	rpm -Va --nomtime --nosize --nomd5 --nolinkto | tee -a ${LOG_FILE}
	echo "*********************" >> ${LOG_FILE}
}

function restrict_perm {
	echo "Restricting permissions (${2}) on ${1}" | tee -a ${LOG_FILE}
	chown root:root ${1}
	chmod ${2} ${1}
}

function main {

	sys_file_perm
	
	restrict_perm /etc/passwd 644
	restrict_perm /etc/shadow 000
	restrict_perm /etc/group 644
	restrict_perm /etc/gshadow 000
	restrict_perm /etc/passwd- 644
	restrict_perm /etc/shadow- 000
	restrict_perm /etc/group- 644
	restrict_perm /etc/gshadow- 000

}

main
