#!/bin/bash
# This script contains code that is called by the install_gitlab.sh script to
# verify the installation prerequisites/requirements are met.

#######################################
# Installs curl
# Locals:
#  None
# Globals:
#  None
# Arguments:
#  None
# Returns:
#  0 If command was evaluated successfully.
# Outputs:
#  None
#######################################
install_curl() {
	yes | sudo apt install curl

	# TODO: verify curl is installed succesfully.
}


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
# bash -c "source src/import.sh && set_gitlab_pwd gitlab_pwd"
set_gitlab_pwd() {
	local gitlab_pwd="$1"
	
	if [ "$gitlab_pwd" != "" ]; then
		add_entry_to_personal_cred_file "GITLAB_SERVER_PASSWORD_GLOBAL" "$gitlab_pwd"
	else
		echo "Error, the GitLab password entered by the user is empty."
		exit 5
	fi
}








verify_prerequisite_personal_creds_txt_contain_required_gitlab_data() {
	if [ $(file_contains_string "GITLAB_SERVER_ACCOUNT_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITLAB_SERVER_ACCOUNT_GLOBAL is not in "
		echo "$PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ $(file_contains_string "GITLAB_SERVER_PASSWORD_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITLAB_SERVER_PASSWORD_GLOBAL is not in "
		echo "$PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ $(file_contains_string "GITLAB_ROOT_EMAIL_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITLAB_ROOT_EMAIL_GLOBAL is not in "
		echo "$PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
}

verify_prerequisite_gitlab_personal_creds_txt_loaded() {
	
	if [ "$GITLAB_SERVER_ACCOUNT_GLOBAL" == "" ]; then
		echo "Error, the GITLAB_SERVER_ACCOUNT_GLOBAL is not loaded correctly "
		echo "from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ "$GITLAB_SERVER_PASSWORD_GLOBAL" == "" ]; then
		echo "Error, the GITLAB_SERVER_PASSWORD_GLOBAL is not loaded correctly"
		echo " from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ "$GITLAB_ROOT_EMAIL_GLOBAL" == "" ]; then
		echo "Error, the GITLAB_ROOT_EMAIL_GLOBAL is not loaded correctly from"
		echo ": $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
}


verify_gitlab_pac_exists_in_persional_creds_txt() {
	if [ $(file_contains_string "GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL is not in $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
	if [ "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]; then
		echo "Error, the GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL is not loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
}

verify_personal_credentials() {
    if [ "$(file_exists "$PERSONAL_CREDENTIALS_PATH")" == "FOUND" ]; then
    	source $PERSONAL_CREDENTIALS_PATH
    elif [ "$(file_exists "src/creds.txt")" == "FOUND" ]; then
    	source src/creds.txt
    	echo "Note you are using the default credentials, would you like to create your own personal credentials file (outside this repo) y/n?"
    else
    	echo "No credentials found."
    	exit 7
    fi
}