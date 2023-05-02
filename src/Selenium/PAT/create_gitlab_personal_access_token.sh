#!/bin/bash
# Source: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#programmatically-creating-a-personal-access-token


# Get shared registration token:
#source: https://github.com/veertuinc/getting-started/blob/ef159275743b2481e68feb92b2c56b5698ad6d6c/GITLAB/install-and-run-anka-gitlab-runners-on-mac.bash
#export SHARED_REGISTRATION_TOKEN="$(sudo docker exec -i 5303124d7b87 bash -c "gitlab-rails runner -e production \"puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token\"")"
#9r6sPoAx3BFqZnxfexLS

# TODO: revoke previous personal_creds.txt  GitLab personal access token from 
# GitLab (if it still works) before adding the new personal_access_token.

ensure_new_gitlab_personal_access_token_works() {
	echo "This method takes up to 2 minutes. We will let you know when it is done."
	export_random_gitlab_token_to_personal_creds_txt
	add_gitlab_personal_access_token_from_personal_creds_txt_to_gitlab
}

# source src/import.sh && export_random_gitlab_token_to_personal_creds_txt
export_random_gitlab_token_to_personal_creds_txt() {
	random_token=$(generate_random_gitlab_personal_access_token)
	
	# Ensure the PERSONAL_CREDENTIALS_PATH file exists(create if not).
	ensure_file_exists "$PERSONAL_CREDENTIALS_PATH"
	ensure_global_is_in_file "GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$random_token" "$PERSONAL_CREDENTIALS_PATH"
}


# source src/import.sh && generate_random_gitlab_personal_access_token
generate_random_gitlab_personal_access_token() {
	echo $RANDOM | md5sum | head -c 20; echo;
}



# bash -c "source src/import.sh && add_gitlab_personal_access_token_from_personal_creds_txt_to_gitlab"
add_gitlab_personal_access_token_from_personal_creds_txt_to_gitlab() {
	
	# Load the GitLab personal access token from file, if it is in there.
	source "$PERSONAL_CREDENTIALS_PATH"
	local docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	
	if [ "$docker_container_id" != "" ]; then
	  if [ "$GITLAB_SERVER_ACCOUNT_GLOBAL" != "" ]; then
	    if [ "$GITLAB_PERSONAL_ACCESS_TOKEN_NAME_GLOBAL" != "" ]; then
		  if [ "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" != "" ]; then
			# shellcheck disable=SC2034
			output="$(sudo docker exec -i "$docker_container_id" bash -c "gitlab-rails runner \"token = User.find_by_username('$GITLAB_SERVER_ACCOUNT_GLOBAL').personal_access_tokens.create(scopes: [:api], name: '$GITLAB_PERSONAL_ACCESS_TOKEN_NAME_GLOBAL'); token.set_token('$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL'); token.save! \"")"
			echo "output=$output"
		  else
		    echo "Error, GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL=$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL is empty."
			exit 4
		  fi
		else
		  echo "Error, GITLAB_PERSONAL_ACCESS_TOKEN_NAME_GLOBAL=$GITLAB_PERSONAL_ACCESS_TOKEN_NAME_GLOBAL is empty."
		  exit 5
        fi
	  else
	    echo "Error, GITLAB_SERVER_ACCOUNT_GLOBAL=$GITLAB_SERVER_ACCOUNT_GLOBAL is empty."
		exit 6
	  fi  
	else
	  echo "Error, docker_container_id=$docker_container_id is empty."
	  exit 7
	fi

	# Verify the token works.
	assert_personal_access_token_works "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL"
}

## TODO: complete method
# bash -c "source src/import.sh && check_if_personal_access_token_works $personal_access_token"
check_if_personal_access_token_works() {
	local personal_access_token="$1"
	
	local repositories=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "$GITLAB_SERVER_HTTPS_URL/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
	#echo "repositories=$repositories"
	if [ "${repositories:0:7}" == '[{"id":' ]; then
		echo "TRUE"
	elif [ "${repositories}" == '{"error":"invalid_token","error_description":"Token was revoked. You have to re-authorize from the user."}' ]; then
		echo "FALSE"
	elif [ "${repositories}" == '{"message":"401 Unauthorized"}' ]; then
		echo "FALSE"
	else
		echo "Error, the repositories response was unexpected:$repositories"
		exit 5
	fi
}

assert_personal_access_token_works() {
	local personal_access_token="$1"

	if [[ "$(check_if_personal_access_token_works "$personal_access_token")" != "TRUE" ]]; then
		echo "Error, the GitLab personal access token does not work."
		exit 56
	fi
}

# source src/import.sh && assert_personal_access_token_does_not_work $personal_access_token
assert_personal_access_token_does_not_work() {
	local personal_access_token="$1"
	if [ "$personal_access_token" != "" ]; then
		if [ "$(check_if_personal_access_token_works $personal_access_token)" != "FALSE" ]; then
			echo "Error, the GitLab personal access token still works(after being revoked)."
			exit 56
		fi
	fi
}

############# Revoke GitLab personal access token ###################
# source src/import.sh && revoke_token_in_personal_creds
# bash -c "source src/import.sh && revoke_token_in_personal_creds"
revoke_token_in_personal_creds() {
	
	# Load the GitLab personal access token from file, if it is in there.
	source "$PERSONAL_CREDENTIALS_PATH"
	local docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	
	if [ "$docker_container_id" != "" ]; then
      if [ "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" != "" ]; then
	    revoke_token "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$docker_container_id"
		
		assert_personal_access_token_does_not_work $GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL
	  else
		echo "The personal access token was not in the personal_creds.txt"
	  fi
	else
	  echo "Error, docker_container_id=$docker_container_id is empty."
	  exit 7
	fi

	# Remove $GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL from personal_creds.
	remove_line_from_file_if_contains_substring "$PERSONAL_CREDENTIALS_PATH" "GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL"

	## Assert $GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL is not in personal_creds
	if [ "$(file_contains_string "GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH")" == "FOUND" ]; then
		echo "Error, the GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL is still in the PERSONAL_CREDENTIALS_PATH file."
		exit 5
	fi
}

#source src/import.sh && delete_token
revoke_token(){
	local personal_access_token="$1"
	local docker_container_id="$2"

	echo "This method takes up to 2 minutes. Please wait, we will let you know when it's done."
	echo ""
	echo ""
	echo ""
	echo ""

	# Revoke token.
	output="$(sudo docker exec -i "$docker_container_id" bash -c "gitlab-rails runner \"PersonalAccessToken.find_by_token('$personal_access_token').revoke! \"")"
	echo "output=$output"
	echo "DoneRevoke"
}