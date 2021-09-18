#!/bin/bash
# Source: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#programmatically-creating-a-personal-access-token
source src/hardcoded_variables.txt
source src/creds.txt
source src/helper.sh

gitlab_host=$GITLAB_SERVER_HTTP_URL
gitlab_user=$gitlab_server_account
gitlab_password=$gitlab_server_password


# Get shared registration token:
#source: https://github.com/veertuinc/getting-started/blob/ef159275743b2481e68feb92b2c56b5698ad6d6c/GITLAB/install-and-run-anka-gitlab-runners-on-mac.bash
#export SHARED_REGISTRATION_TOKEN="$(sudo docker exec -i 5303124d7b87 bash -c "gitlab-rails runner -e production \"puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token\"")"
#9r6sPoAx3BFqZnxfexLS


# source src/create_personal_access_token.sh && create_gitlab_personal_access_token
# verify at: http://127.0.0.1/-/profile/personal_access_tokens
create_gitlab_personal_access_token() {
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	# trim newlines
	personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
	gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
	token_name=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN_NAME | tr -d '\r')
	
	# Source: https://gitlab.example.com/-/profile/personal_access_tokens?name=Example+Access+token&scopes=api,read_user,read_registry
	# Create a personal access token
	# TODO: limit scope to only required scope
	# https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html
	output="$(sudo docker exec -i $docker_container_id bash -c "gitlab-rails runner \"token = User.find_by_username('$gitlab_username').personal_access_tokens.create(scopes: [:api], name: '$token_name'); token.set_token('$personal_access_token'); token.save! \"")"
}

