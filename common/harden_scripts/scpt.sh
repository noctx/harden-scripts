#!/bin/bash

LOG_FILE='./REVIEW_ME.md'

echo "Ensure no world writable files exist" | tee -a ${LOG_FILE}
echo "Please review these files as the "other" category has write access to it, which is not advisable." | tee -a ${LOG_FILE}
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type f -perm -0002 | tee -a ${LOG_FILE}

echo "Ensure no unowned files or directories exist" | tee -a ${LOG_FILE}
echo "Locate and reset onwership of any output file" | tee -a ${LOG_FILE}
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nouser | tee -a ${LOG_FILE}

echo "Ensure no ungrouped files or directories exist" | tee -a ${LOG_FILE}
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nogroup | tee -a ${LOG_FILE}

echo "Audit SUID executables" | tee -a ${LOG_FILE}
echo "Make sure no rogue SUID programs have been introduced here" | tee -a ${LOG_FILE}
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type f -perm -4000 | tee -a ${LOG_FILE}

echo "Audit SGID executables" | tee -a ${LOG_FILE}
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type f -perm -2000 | tee -a ${LOG_FILE}

echo "Ensure password fields are not empty" | tee -a ${LOG_FILE}
echo "PLease add a password for each user returned"
cat /etc/shadow | awk -F: '($2 == "" ) { print $1 " does not have a password "}' | tee -a ${LOG_FILE}

echo "*********************" >> ${LOG_FILE}
echo "For the following tests, remove any output" >> ${LOG_FILE}
echo 'Ensure no legacy "+" entries exist in /etc/passwd' | tee -a ${LOG_FILE}
grep '^\+:' /etc/passwd | tee -a ${LOG_FILE}

echo 'Ensure no legacy "+" entries exist in /etc/shadow' | tee -a ${LOG_FILE}
grep '^\+:' /etc/shadow | tee -a ${LOG_FILE}

echo 'Ensure no legacy "+" entries exist in /etc/group' | tee -a ${LOG_FILE}
grep '^\+:' /etc/group | tee -a ${LOG_FILE}
echo "*********************" >> ${LOG_FILE}

echo "Ensure root is the only UID 0 account" | tee -a ${LOG_FILE}
echo "Remove any user that's not root or assign new UID" >> ${LOG_FILE}
cat /etc/passwd | awk -F: '($3 == 0) { print $1 }' | tee -a ${LOG_FILE}

echo "Ensure root PATH Integrity" | tee -a ${LOG_FILE}
echo "Correct/justify any output returned (should be empty)" >> ${LOG_FILE}
if [ "`echo $PATH | grep ::`" != "" ]; then
	echo "Empty Directory in PATH (::)" | tee -a ${LOG_FILE}
fi
if [ "`echo $PATH | grep :$`" != "" ]; then
	echo "Trailing : in PATH" | tee -a ${LOG_FILE}
fi

p=`echo $PATH | sed -e 's/::/:/' -e 's/:$//' -e 's/:/ /g'`
set -- $p
while [ "$1" != "" ]; do
	if [ "$1" = "." ]; then
		echo "PATH contains ." | tee -a ${LOG_FILE}
		shift
		continue
	fi
	if [ -d $1 ]; then
		dirperm=`ls -ldH $1 | cut -f1 -d" "`
		if [ `echo $dirperm | cut -c6` != "-" ]; then
			echo "Group Write permission set on directory $1" | tee -a ${LOG_FILE}
		fi
		if [ `echo $dirperm | cut -c9` != "-" ]; then
			echo "Other Write permission set on directory $1" | tee -a ${LOG_FILE}
		fi
		dirown=`ls -ldH $1 | awk '{print $3}'`
		if [ "$dirown" != "root" ] ; then
			echo $1 is not owned by root | tee -a ${LOG_FILE}
		fi
	else
		echo $1 is not a directory | tee -a ${LOG_FILE}
	fi
	shift
done

echo "Ensure all users' home directories exist" | tee -a ${LOG_FILE}
echo "Create missing directories" >> ${LOG_FILE}
cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
	if [ ! -d "$dir" ]; then
		echo "The home directory ($dir) of user $user does not exist." | tee -a ${LOG_FILE}
	fi
done

echo "*********************" >> ${LOG_FILE}
echo "For the following tests, please correct any output" >> ${LOG_FILE}
echo "Ensure users' home directories permissions are 750 or more restrictive" | tee -a ${LOG_FILE}
cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
	if [ ! -d "$dir" ]; then
		echo "The home directory ($dir) of user $user does not exist." | tee -a ${LOG_FILE}
	else
		dirperm=`ls -ld $dir | cut -f1 -d" "`
		if [ `echo $dirperm | cut -c6` != "-" ]; then
			echo "Group Write permission set on the home directory ($dir) of user $user" | tee -a ${LOG_FILE}
		fi
		if [ `echo $dirperm | cut -c8` != "-" ]; then
			echo "Other Read permission set on the home directory ($dir) of user $user" | tee -a ${LOG_FILE}
		fi
		if [ `echo $dirperm | cut -c9` != "-" ]; then
			echo "Other Write permission set on the home directory ($dir) of user $user" | tee -a ${LOG_FILE}
		fi
		if [ `echo $dirperm | cut -c10` != "-" ]; then
			echo "Other Execute permission set on the home directory ($dir) of user $user" | tee -a ${LOG_FILE}
		fi
	fi
done

echo "Ensure users own their home directories" | tee -a ${LOG_FILE}
cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
	if [ ! -d "$dir" ]; then
		echo "The home directory ($dir) of user $user does not exist." | tee -a ${LOG_FILE}
	else
		owner=$(stat -L -c "%U" "$dir")
		if [ "$owner" != "$user" ]; then
			echo "The home directory ($dir) of user $user is owned by $owner." | tee -a ${LOG_FILE}
		fi
	fi
done


echo "Ensure users' dot files are not group or world writable" | tee -a ${LOG_FILE}
cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
	if [ ! -d "$dir" ]; then
		echo "The home directory ($dir) of user $user does not exist."  | tee -a ${LOG_FILE}
	else 
		for file in $dir/.[A-Za-z0-9]*; do
			if [ ! -h "$file" -a -f "$file" ]; then
				fileperm=`ls -ld $file | cut -f1 -d" "`
				if [ `echo $fileperm | cut -c6` != "-" ]; then
					echo "Group Write permission set on file $file" | tee -a ${LOG_FILE}
				fi
				if [ `echo $fileperm | cut -c9` != "-" ]; then
					echo "Other Write permission set on file $file" | tee -a ${LOG_FILE}
				fi
			fi
		done
	fi
done

echo "Ensure no users have .forward files" | tee -a ${LOG_FILE}
cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
	if [ ! -d "$dir" ]; then
		echo "The home directory ($dir) of user $user does not exist." | tee -a ${LOG_FILE}
	else
		if [ ! -h "$dir/.forward" -a -f "$dir/.forward" ]; then
			echo ".forward file $dir/.forward exists" | tee -a ${LOG_FILE}
		fi
	fi
done

echo "Ensure no users have .netrc files" | tee -a ${LOG_FILE}
cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
	if [ ! -d "$dir" ]; then
		echo "The home directory ($dir) of user $user does not exist." | tee -a ${LOG_FILE}
	else
		if [ ! -h "$dir/.netrc" -a -f "$dir/.netrc" ]; then
 			echo ".netrc file $dir/.netrc exists" | tee -a ${LOG_FILE}
		fi
	fi
done

echo "Ensure users' .netrc Files are not group or world accessible" | tee -a ${LOG_FILE}
cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
	if [ ! -d "$dir" ]; then
		echo "The home directory ($dir) of user $user does not exist." | tee -a ${LOG_FILE}
	else
		for file in $dir/.netrc; do 
			if [ ! -h "$file" -a -f "$file" ]; then
				fileperm=`ls -ld $file | cut -f1 -d" "`
				if [ `echo $fileperm | cut -c5` != "-" ]; then
						echo "Group Read set on $file" | tee -a ${LOG_FILE}
				fi
				if [ `echo $fileperm | cut -c6` != "-" ]; then
					echo "Group Write set on $file" | tee -a ${LOG_FILE}
				fi
				if [ `echo $fileperm | cut -c7` != "-" ]; then
					echo "Group Execute set on $file" | tee -a ${LOG_FILE}
				fi
				if [ `echo $fileperm | cut -c8` != "-" ]; then
					echo "Other Read set on $file" | tee -a ${LOG_FILE}
				fi
				if [ `echo $fileperm | cut -c9` != "-" ]; then
					echo "Other Write set on $file" | tee -a ${LOG_FILE}
				fi
				if [ `echo $fileperm | cut -c10` != "-" ]; then
					echo "Other Execute set on $file" | tee -a ${LOG_FILE}
				fi
			fi
		done
	fi
done

echo "Ensure no users have .rhosts files" | tee -a ${LOG_FILE}
cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
	if [ ! -d "$dir" ]; then
		echo "The home directory ($dir) of user $user does not exist." | tee -a ${LOG_FILE}
	else
		for file in $dir/.rhosts; do
			if [ ! -h "$file" -a -f "$file" ]; then
				echo ".rhosts file in $dir" | tee -a ${LOG_FILE}
			fi
		done
	fi
done

echo "Ensure all groups in /etc/passwd exist in /etc/group" | tee -a ${LOG_FILE}
for i in $(cut -s -d: -f4 /etc/passwd | sort -u ); do
	grep -q -P "^.*?:[^:]*:$i:" /etc/group
	if [ $? -ne 0 ]; then
		echo "Group $i is referenced by /etc/passwd but does not exist in /etc/group" | tee -a ${LOG_FILE}
	fi
done

echo "Ensure no duplicate UIDs exist" | tee -a ${LOG_FILE}
cat /etc/passwd | cut -f3 -d":" | sort -n | uniq -c | while read x ; do
	[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]; then
		users=`awk -F: '($3 == n) { print $1 }' n=$2 /etc/passwd | xargs`
		echo "Duplicate UID ($2): ${users}" | tee -a ${LOG_FILE}
	fi
done

echo "Ensure no duplicate GIDs exist" | tee -a ${LOG_FILE}
cat /etc/group | cut -f3 -d":" | sort -n | uniq -c | while read x ; do
	[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]; then
		groups=`awk -F: '($3 == n) { print $1 }' n=$2 /etc/group | xargs`
		echo "Duplicate GID ($2): ${groups}" | tee -a ${LOG_FILE}
	fi
done

echo "Ensure no duplicate user names exist" | tee -a ${LOG_FILE}
cat /etc/passwd | cut -f1 -d":" | sort -n | uniq -c | while read x ; do
[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]; then
		uids=`awk -F: '($1 == n) { print $3 }' n=$2 /etc/passwd | xargs`
		echo "Duplicate User Name ($2): ${uids}" | tee -a ${LOG_FILE}
	fi
done

echo "Ensure no duplicate group names exist" | tee -a ${LOG_FILE}
cat /etc/group | cut -f1 -d":" | sort -n | uniq -c | while read x ; do
	[ -z "${x}" ] && break
	set - $x
	if [ $1 -gt 1 ]; then
		gids=`gawk -F: '($1 == n) { print $3 }' n=$2 /etc/group | xargs`
		echo "Duplicate Group Name ($2): ${gids}" | tee -a ${LOG_FILE}
	fi
done
echo "*********************" >> ${LOG_FILE}
