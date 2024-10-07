#!/bin/bash

function main {
	for scpt in `ls *.sh` ; do
		if [[ ${scpt} != "main.sh" ]] ; then
			/bin/bash ${scpt}
		fi
	done
}

main

