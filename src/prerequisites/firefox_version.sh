#!/bin/bash
# This script verifies Firefox is installed in the right way. Firefox is used
# to set the GitHub SSH keys and GitHub personal access tokens automatically.
# And to control a Firefox browser, it needs to be installed using apt instead
# of snap. https://stackoverflow.com/questions/72405117
# https://www.omgubuntu.co.uk/2022/04/how-to-install-firefox-deb-apt-ubuntu-22-04

source src/import.sh

#######################################
# Checks if firefox is installed using snap or not.
# Locals:
#  respones_lines
#  found_firefox
# Globals:
#  None
# Arguments:
#  None
# Returns:
#  0 If command was evaluated successfully.
# Outputs:
#  FOUND if firefox is installed using snap.
#  NOTFOUND if firefox is not installed using snap.
#######################################
# Run with:
# bash -c "source src/import.sh && src/prerequisites/firefox_version.sh firefox_via_snap"
firefox_via_snap(){
	local respons_lines="$(snap list)"
	local found_firefox=$(command_output_contains "firefox" "${respons_lines}")
	echo $found_firefox
}


#######################################
# Remove Firefox if it is installed using snap.
# Locals:
#  respones_lines
#  found_firefox
# Globals:
#  None
# Arguments:
#  None
# Returns:
#  0 If command was evaluated successfully.
# Outputs:
#  FOUND if firefox is installed using snap.
#  NOTFOUND if firefox is not installed using snap.
#######################################
# Run with:
# bash -c "source src/import.sh && src/prerequisites/firefox_version.sh remove_snap_install_firefox_if_existant"
remove_snap_install_firefox_if_existant(){
	if [ "$(firefox_via_snap)" == "FOUND" ]; then
		# Prompt user for permission.
		ask_user_swapping_firefox_install_is_ok
		yes | sudo snap remove firefox 2>&1
		assert_firefox_is_not_installed_using_snap
		echo "Firefox is removed."
	fi
	assert_firefox_is_not_installed_using_snap
}

#######################################
# Ask user for permission to swap out Firefox installation.
# Locals:
#  yn
# Globals:
#  None
# Arguments:
#  None
# Returns:
#  0 If command was evaluated successfully.
#  3 If the user terminates the program.
# Outputs:
#  Mesage indicating Firefox will be uninstalled.
#######################################
# Run with:
# bash -c "source src/import.sh && src/prerequisites/firefox_version.sh remove_snap_install_firefox_if_existant"
ask_user_swapping_firefox_install_is_ok(){
	echo "" > /dev/tty
	echo "Hi, firefox is installed using snap. To automatically add your " > /dev/tty
	echo "access tokens to GitHub, we need to control the firefox browser." > /dev/tty
	echo "To control the firefox browser, we need to switch the installation" > /dev/tty
	echo "method from snap to apt." > /dev/tty
	echo "" > /dev/tty
	echo "We will not preserve your bookmarks, history and extensions." > /dev/tty
	echo "" > /dev/tty
	while true; do
		read -p "May we proceed? (y/n)? " yn
		case $yn in
			[Yy]* ) echo "Removing Firefox, please wait 5 minutes, we will tell you when it is done."; break;;
			[Nn]* ) echo "Installation terminated by user."; exit 3;;
			* ) echo "Please answer yes or no." > /dev/tty;;
		esac
	done
}

#######################################
# Asserts Firefox is not installed using snap, throws an error otherwise.
# Locals:
#  None
# Globals:
#  None
# Arguments:
#  None
# Returns:
#  0 If Firefox is not installed using snap.
#  1 If Firefox is still isntalled using snap.
# Outputs:
#  Nothing
#######################################
# Run with:
assert_firefox_is_not_installed_using_snap(){
	if [ "$(firefox_via_snap)" == "FOUND" ]; then
		echo "Error, Firefox installation was still installed using snap."
		exit 2
	fi
}

# 0. Detect how firefox is installed.
# 1. If firefox installed with snap:
# 1.a Ask user for permission to swap out Firefox installation.
# 1.b. Verify and mention the bookmarks, addons and history are not removed.
# 1.c Remove snap firefox if it exists.
# 1.d Verify snap firefox is removed.
remove_snap_install_firefox_if_existant
# 1.e Add firefox ppa.

##sudo add-apt-repository ppa:mozillateam/ppa
# 1.f Verify firefox ppa is added (successfully).
# 1.g Change Firefox package priority to ensure it is installed from PPA/deb/apt
# instead of snap.
##echo '
##Package: *
##Pin: release o=LP-PPA-mozillateam
##Pin-Priority: 1001
##' | sudo tee /etc/apt/preferences.d/mozilla-firefox
# 1.g. Verify Firefox installation priority was set correctly.
# 1.h. Ensure the Firefox installation is automatically updated.
##echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
# 1.i Verify the auto update command is completed succesfully.
# 1.h Install Firefox using apt.
# 1.j Verify firefox is installed succesfully, and only once, using apt/PPA.

