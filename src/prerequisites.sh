#!/bin/bash


#######################################
# 0. Ensures a GitHub personal access token is usable to set GitHub commit 
# build status.
# 1. Asserts the GitHub build status repository exists in the user.
# 2. Ensures a GitHub ssh deploy key is useable to push build status icons
# to the GitHub build status repository.

# Local variables:
#  filepath
# Globals:
#  None.
# Arguments:
#  Relative filepath of file whose existance is verified.
# Returns:
#  0 If file was found.
#  29 If the file was not found.
# Outputs:
#  Nothing
# TODO(a-t-0): Ensure the GitHub build status repository is created in GitHub
# user if it does not yet exist.
#######################################
# Run with: 
# bash -c "source src/import.sh && establish_prerequisites a-t-0 sponsor_example"
# source src/import.sh && establish_prerequisites a-t-0 sponsor_example
ensures_gitlab_personal_access_token_can_be_used_to_set_commit_build_status() {
	local github_username="$1"
	local github_reponame="$2"
	# Get the GitHub personal access token to set the commit build status.
	#get_github_personal_access_token $GITHUB_USERNAME_GLOBAL	
	# Verify the GitHub personal access token is able to set the commit build 
	# status.
	# Reload GitHub personal access token from personal credentials.
	source ../personal_creds.txt
	# Verify for status: pending
	echo "COMMIT_WHOSE_BUILD_STATUS_IS_SET_FOR_TESTING_PURPOSES=$COMMIT_WHOSE_BUILD_STATUS_IS_SET_FOR_TESTING_PURPOSES"
	set_build_status_of_github_commit "$github_username" "$github_reponame" "$COMMIT_WHOSE_BUILD_STATUS_IS_SET_FOR_TESTING_PURPOSES" "$GITLAB_SERVER_HTTP_URL"  "pending"
	# Verify for status: success
	set_build_status_of_github_commit "$github_username" "$github_reponame" "$COMMIT_WHOSE_BUILD_STATUS_IS_SET_FOR_TESTING_PURPOSES" "$GITLAB_SERVER_HTTP_URL"  "success"

	# Verify if the GitLab Build Status repository exists.
	# TODO(a-t-0): Ensure the GitHub build status repository is created in GitHub
	assert_public_github_repository_exists "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL"

	# Get the GitHub ssh deploy key to push and pull the GitLab build status 
	# icons to the GitHub build status repository.
	get_github_build_status_repo_deploy_key "example@example.com" "some_github_deploy_key"
	verify_machine_has_push_access_to_gitlab_build_status_repo_in_github "some_github_deploy_key"
	read -p "Got the personal access token"
}

set_default_personal_creds_if_empty() {
	local gitlab_url="$1"
	local gitlab_root_username="$2"
	local gitlab_email="$3"

	set_default_personal_cred_if_empty "GITLAB_SERVER_HTTP_URL" gitlab_url
	set_default_personal_cred_if_empty "GITLAB_SERVER_ACCOUNT_GLOBAL" gitlab_root_username
	set_default_personal_cred_if_empty "GITLAB_ROOT_EMAIL_GLOBAL" gitlab_email

}


#######################################
# Sets the default value for Global in personal_creds.txt if the user does not
# manually specify this url in the command line arguments.
# Globals:
#  GITLAB_SERVER_HTTP_URL.
#  PERSONAL_CREDENTIALS_PATH
# Arguments:
#  The GitLab server that was originally passed as input argument to this 
#  program by the user.
# Returns:
#  0 if the function is set correctly.
#  5 If the GitLab server url is not set in the personal_creds.txt file at 
#  the end of the function.
# Outputs:
#  Nothing
# TODO(a-t-0): Include verification on url format (Must have http:// (I think)).
#######################################
# Run with: 
# bash -c "source src/import.sh && set_default_personal_cred_if_empty GITLAB_SERVER_HTTP_URL gitlab_url"
set_default_personal_cred_if_empty(){
	local identifier="$1"
	local incoming_value="$2"

	if [ "$incoming_value" != "" ]; then
		# Ensure the PERSONAL_CREDENTIALS_PATH file exists(create if not).
		ensure_file_exists "$PERSONAL_CREDENTIALS_PATH"
		ensure_global_is_in_file "$identifier" "$incoming_value" "$PERSONAL_CREDENTIALS_PATH"
	else
		ensure_global_is_in_file "$identifier" "$GITLAB_SERVER_HTTP_URL" "$PERSONAL_CREDENTIALS_PATH"
		# Assert the PERSONAL_CREDENTIALS_PATH contains GITLAB_SERVER_HTTP_URL.
	    assert_file_contains_string "$identifier=$GITLAB_SERVER_HTTP_URL" "$PERSONAL_CREDENTIALS_PATH"
	fi

	# Assert the PERSONAL_CREDENTIALS_PATH contains GITLAB_SERVER_HTTP_URL.
	assert_file_contains_string "$identifier" "$PERSONAL_CREDENTIALS_PATH"
}