#!/bin/bash
# Source: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#programmatically-creating-a-personal-access-token


# Get shared registration token:
#source: https://github.com/veertuinc/getting-started/blob/ef159275743b2481e68feb92b2c56b5698ad6d6c/GITLAB/install-and-run-anka-gitlab-runners-on-mac.bash
#export SHARED_REGISTRATION_TOKEN="$(sudo docker exec -i 5303124d7b87 bash -c "gitlab-rails runner -e production \"puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token\"")"
#9r6sPoAx3BFqZnxfexLS


# source src/import.sh && create_gitlab_personal_access_token
# verify at: http://127.0.0.1/-/profile/personal_access_tokens
create_gitlab_personal_access_token() {
	# TODO: process the gitlab_personal_access_token input to set the token
	# instead of reading it from the personal_creds.txt
	local gitlab_personal_access_token="$1"
	local docker_container_id=$(get_docker_container_id_of_gitlab_server)
	echo "This method takes up to 2 minutes. Please wait, we will let you know when it's done."
	echo ""
	echo ""
	
	# Trim newlines of global variables.
	personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	token_name=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_NAME_GLOBAL" | tr -d '\r')
	#echo "personal_access_token=$personal_access_token"
	#echo "gitlab_username=$gitlab_username"
	#echo "token_name=$token_name"
	
	# Source: https://gitlab.example.com/-/profile/personal_access_tokens?name=Example+Access+token&scopes=api,read_user,read_registry
	# Create a personal access token
	# TODO: limit scope to only required scope
	# https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html
	# shellcheck disable=SC2154
	if [ "$(gitlab_personal_access_token_exists)" == "NOTFOUND" ]; then
		# shellcheck disable=SC2034
		output="$(sudo docker exec -i "$docker_container_id" bash -c "gitlab-rails runner \"token = User.find_by_username('$gitlab_username').personal_access_tokens.create(scopes: [:api], name: '$token_name'); token.set_token('$personal_access_token'); token.save! \"")"
	fi
}

# Run with:
# bash -c "source src/import.sh && gitlab_personal_access_token_exists"
gitlab_personal_access_token_exists() {
	# shellcheck disable=SC2034
	#list_of_personal_access_tokens=$(get_personal_access_token_list "Filler")
	list_of_personal_access_tokens=$(get_personal_access_token_list)
	if [  "$(string_in_lines "$GITLAB_PERSONAL_ACCESS_TOKEN_NAME_GLOBAL" "${list_of_personal_access_tokens}")" == "NOTFOUND" ]; then
		echo "NOTFOUND"
	else
		echo "FOUND"
	fi
}


# Run with:
# bash -c "source src/import.sh && get_personal_access_token_list"
get_personal_access_token_list() {
	personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
	#command="curl --header \"PRIVATE-TOKEN:$personal_access_token\" ""$gitlab_host""/api/v4/personal_access_tokens"
	#echo "Command=$command"

	# TODO: Note used to be a space after the semicolon, check if it is required
	token_list=$(curl --header "PRIVATE-TOKEN:$personal_access_token" "$GITLAB_SERVER_HTTP_URL""/api/v4/personal_access_tokens")
	echo "$token_list"
}


## TODO: complete method
check_if_personal_access_token_works() {
	echo "hi"
}

## TODO: complete method
assert_personal_access_token_works() {
	echo "hi"
}