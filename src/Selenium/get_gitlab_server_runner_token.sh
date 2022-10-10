#!/bin/bash


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_gitlab_server_runner_tokenV1() {
	GITURL="$GITLAB_SERVER_HTTP_URL"
	# shellcheck disable=SC2154
	GITUSER="$GITLAB_SERVER_ACCOUNT_GLOBAL"
	# shellcheck disable=SC2154
	GITROOTPWD="$GITLAB_SERVER_PASSWORD_GLOBAL"
	#echo "GITUSER=$GITUSER"
	#echo "GITROOTPWD=$GITROOTPWD"
	
	# 1. curl for the login page to get a session cookie and the sources with the auth tokens
	body_header=$(curl -k -c "$LOG_LOCATION"gitlab-cookies.txt -i "${GITURL}/users/sign_in" -sS)
	#echo "body_header=$body_header"
	
	# grep the auth token for the user login for
	#   not sure whether another token on the page will work, too - there are 3 of them
	csrf_token=$(echo "$body_header" | perl -ne 'print "$1\n" if /new_user.*?authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)
	#echo "csrf_token=$csrf_token"
	
	# 2. send login credentials with curl, using cookies and token from previous request
	curl -sS -k -b "$LOG_LOCATION"gitlab-cookies.txt -c "$LOG_LOCATION"gitlab-cookies.txt "${GITURL}/users/sign_in" \
		--data "user[login]=${GITUSER}&user[password]=${GITROOTPWD}" \
		--data-urlencode "authenticity_token=${csrf_token}"  -o /dev/null
	
	# 3. send curl GET request to gitlab runners page to get registration token
	body_header=$(curl -sS -k -H 'user-agent: curl' -b "$LOG_LOCATION"gitlab-cookies.txt "${GITURL}/admin/runners" -o "$LOG_LOCATION"gitlab-header.txt)
	
	if [ "$body_header" == "" ]; then
		get_registration_token_with_python
		reg_token=$(cat "$RUNNER_REGISTRATION_TOKEN_FILEPATH")
	else
		reg_token=$(cmd < "$LOG_LOCATION"gitlab-header.txt | perl -ne 'print "$1\n" if /code id="registration_token">(.+?)</' | sed -n 1p)
		echo "$reg_token" > "$RUNNER_REGISTRATION_TOKEN_FILEPATH"
	fi
	if [ "$reg_token" == "" ]; then
		echo "ERROR, would have expected the runner registration token to be found by now, but it was not."
		exit 1
	fi
	#echo "$reg_token"
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_gitlab_server_runner_tokenV0() {
	export GITURL="$GITLAB_SERVER_HTTP_URL"
	export GITUSER="$GITLAB_SERVER_ACCOUNT_GLOBAL"
	export GITROOTPWD="$GITLAB_SERVER_PASSWORD_GLOBAL"
	
	# 1. curl for the login page to get a session cookie and the sources with the auth tokens
	body_header=$(curl -k -c gitlab-cookies.txt -i "${GITURL}/users/sign_in" -sS)
	
	# grep the auth token for the user login for
	#   not sure whether another token on the page will work, too - there are 3 of them
	csrf_token=$(echo "$body_header" | perl -ne 'print "$1\n" if /new_user.*?authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)
	
	# 2. send login credentials with curl, using cookies and token from previous request
	curl -sS -k -b gitlab-cookies.txt -c gitlab-cookies.txt "${GITURL}/users/sign_in" \
		--data "user[login]=${GITUSER}&user[password]=${GITROOTPWD}" \
		--data-urlencode "authenticity_token=${csrf_token}"  -o /dev/null
	
	# 3. send curl GET request to gitlab runners page to get registration token
	body_header=$(curl -sS -k -H 'user-agent: curl' -b gitlab-cookies.txt "${GITURL}/admin/runners" -o gitlab-header.txt)
	reg_token=$(cmd < gitlab-header.txt | perl -ne 'print "$1\n" if /code id="registration_token">(.+?)</' | sed -n 1p)
	echo "$reg_token"
	# TODO: restore the functionality of this method!
	#echo "sPgAnNea3WxvTRsZN5hB"
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
# source src/get_gitlab_server_runner_token.sh && get_registration_token_with_python
get_registration_token_with_python() {
	sudo rm -r "get-gitlab-runner-registration-token"
	
	# delete the runner registration token file if it exist
	if [ -f "$RUNNER_REGISTRATION_TOKEN_FILEPATH" ] ; then
	    rm "$RUNNER_REGISTRATION_TOKEN_FILEPATH"
	fi
	
	# Check if the repository exists
	download_repository "a-t-0" "$REPONAME_GET_RUNNER_TOKEN_PYTHON"
	
	
	# TODO: turn get_gitlab_generation_token into variable
	# shellcheck disable=SC2034
	#conda_environments=$(conda env list)
	#read -p "CONDA_ENVIRONMENT_NAME=$CONDA_ENVIRONMENT_NAME"
	#read -p "conda_environments=$conda_environments"
	#if [ "$(lines_contain_string "$CONDA_ENVIRONMENT_NAME" "\${conda_environments}")" == "FOUND" ]; then
	if [ "$(conda_env_exists $CONDA_ENVIRONMENT_NAME)" == "FOUND" ]; then
		eval "$(conda shell.bash hook)"
		cd get-gitlab-runner-registration-token && conda deactivate && conda activate get_gitlab_generation_token && python -m code.project1.src --glr
		#cd get-gitlab-runner-registration-token && conda init get_gitlab_generation_token && python -m code.project1.src
		# eval $(conda shell.bash hook)
	else
		eval "$(conda shell.bash hook)"
		cd get-gitlab-runner-registration-token && conda env create --file environment.yml && conda activate get_gitlab_generation_token && python -m code.project1.src --glr
		
	fi
	cd ..
	# TODO: verify path
}

get_gitlab_server_runner_tokenV2() {
	GITURL="$GITLAB_SERVER_HTTP_URL"
	GITUSER="$GITLAB_SERVER_ACCOUNT_GLOBAL"
	GITROOTPWD="$GITLAB_SERVER_PASSWORD_GLOBAL"
	
	# 1. curl for the login page to get a session cookie and the sources with the auth tokens
	body_header=$(curl -k -c gitlab-cookies.txt -i "${GITURL}/users/sign_in" -sS)
	
	# grep the auth token for the user login for
	#   not sure whether another token on the page will work, too - there are 3 of them
	csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /new_user.*?authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)
	
	# 2. send login credentials with curl, using cookies and token from previous request
	output=$(curl -sS -k -b gitlab-cookies.txt -c gitlab-cookies.txt "${GITURL}/users/sign_in" \
		--data "user[login]=${GITUSER}&user[password]=${GITROOTPWD}" \
		--data-urlencode "authenticity_token=${csrf_token}"  -o /dev/null)
	
	# 3. send curl GET request to gitlab runners page to get registration token
	body_header=$(curl -sS -k -H 'user-agent: curl' -b gitlab-cookies.txt "${GITURL}/admin/runners" -o gitlab-header.txt)
	
	reg_token=$(cat gitlab-header.txt | perl -ne 'print "$1\n" if /code id="registration_token">(.+?)</' | sed -n 1p)
	echo $reg_token
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_gitlab_server_runner_tokenV3() {
	source src/hardcoded_variables.txt
	export GITURL="$GITLAB_SERVER_HTTP_URL"
	#read  -p "GITURL=$GITURL"
	export GITUSER="$GITLAB_SERVER_ACCOUNT_GLOBAL"
	#read  -p "GITUSER=$GITUSER"
	export GITROOTPWD="$GITLAB_SERVER_PASSWORD_GLOBAL"
	#read  -p "GITROOTPWD=$GITROOTPWD"
	
	# 1. curl for the login page to get a session cookie and the sources with the auth tokens
	body_header=$(curl -k -c gitlab-cookies.txt -i "${GITURL}/users/sign_in" -sS)
	#read  -p "body_header=$body_header"
	
	# grep the auth token for the user login for
	#   not sure whether another token on the page will work, too - there are 3 of them
	csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /new_user.*?authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)
	
	# 2. send login credentials with curl, using cookies and token from previous request
	output=$(curl -sS -k -b gitlab-cookies.txt -c gitlab-cookies.txt "${GITURL}/users/sign_in" \
		--data "user[login]=${GITUSER}&user[password]=${GITROOTPWD}" \
		--data-urlencode "authenticity_token=${csrf_token}"  -o /dev/null)
	
	# 3. send curl GET request to gitlab runners page to get registration token
	body_header=$(curl -sS -k -H 'user-agent: curl' -b gitlab-cookies.txt "${GITURL}/admin/runners" -o gitlab-header.txt)
	reg_token=$(cat gitlab-header.txt | perl -ne 'print "$1\n" if /code id="registration_token">(.+?)</' | sed -n 1p)
	echo $reg_token
}