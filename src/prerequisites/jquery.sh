#!/bin/bash
# This script ensures jquery is installed using apt.

# Run with:
# bash -c "source src/import.sh && src/prerequisites/jquery.sh install_jquery_using_ppa"

#######################################
# Checks if jquery is installed using ppa and apt or not.
# Locals:
#  respones_lines
#  found_jquery
# Globals:
#  None
# Arguments:
#  None
# Returns:
#  0 If command was evaluated successfully.
# Outputs:
#  FOUND if jquery is installed using ppa and apt.
#  NOTFOUND if jquery is not installed using ppa and apt.
#######################################
jquery_via_apt(){
	local respons_lines="$(apt list --installed)"
    
    local jquery_indicator="jq/"
    if grep -q "$jquery_indicator" <<< "$(apt list --installed)"; then
   		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}

assert_jquery_is_installed_using_ppa(){
	if [ "$(jquery_via_apt)" != "FOUND" ]; then
		echo "Error, jquery installation was not performed using ppa and apt." > /dev/tty
		exit 2
	fi
}

#######################################
# Installs jquery using ppa and apt.
# Locals:
#  None
# Globals:
#  None
# Arguments:
#  None
# Returns:
#  0 If jquery is installed using ppa and apt.
#  1 If jquery is mpt installed using ppa and apt.
# Outputs:
#  Nothing
#######################################
install_jquery_using_apt(){
	if [ "$(jquery_via_apt)" == "NOTFOUND" ]; then
		yes | sudo apt install jq
         2>&1
	fi
	assert_jquery_is_installed_using_ppa
	echo "3.a jquery is installed succesfully using ppa and apt." > /dev/tty
}