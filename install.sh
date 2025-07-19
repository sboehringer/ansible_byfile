#!/bin/bash

if [ "$(pushd .. >/dev/null ; basename $(pwd))" != "roles_meta" ]; then
	printf "[\u274c] byfile folder located inside roles_meta"
	echo "	Suggested folder structure: ansible > roles_meta > ansible_byfile"
	echo '	pushd "$ANSIBLE_HOME/roles_meta"; git clone ...'
	exit 1
fi

printf "[\u2714\ufe0e] byfile folder located inside roles_meta\n"

if [ ! -e "../../roles" ]; then
	printf "[\u274c] Ansible role folder located at ../../roles\n"
	exit 1
fi

printf "[\u2714\ufe0e] Ansible role folder located at ../../roles\n"

if [ -e "../../roles/byfile" ]; then
	printf "[\u274c] Byfile already installed as ansible role\n"
	exit 1
fi

ln -s ../roles_meta/ansible_byfile/byfile ../../roles

printf "[\u2714\ufe0e] Created symbolic link in ansible roles folder\n"
