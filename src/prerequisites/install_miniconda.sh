#!/bin/bash
# This script installs miniconda, if conda is not yet installed.

# Run with:
# bash -c "source src/import.sh && src/prerequisites/firefox_version.sh swap_snap_firefox_with_ppa_apt_firefox_installation"
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
ensure_miniconda_is_installed(){
	
	found_conda=$(conda_is_installed || true)

	if [[ "$found_conda" == "NOTFOUND" ]]; then
		
		# Perform an update to make sure the system is up to date.
    	sudo apt-get update --fix-missing -y
    	
		# Download miniconda.
    	wget -q https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh; bash miniconda.sh -b -f -p $HOME/miniconda;
    	
		# Ensure the (mini) conda environment can be activated.
    	export PATH="$HOME/miniconda/bin:$PATH"
		conda init bash
	fi
}

conda_is_installed() {
	local exit_code
	exit_code=0
	conda >/dev/null 2>&1
	exit_code=$?
	
	
	if [[ $exit_code -eq 127 ]]; then
		echo "NOTFOUND"
	elif [[ $exit_code -eq 0 ]]; then
		echo "FOUND"
	else
		echo "Unexpected error code when running command:conda.:$EXIT_CODE"
		exit "$EXIT_CODE"
	fi
}