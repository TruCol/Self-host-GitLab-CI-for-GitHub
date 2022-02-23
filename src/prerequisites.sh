#!/bin/bash

#######################################
# Sets the default value for GitLab url, username and email in 
# personal_creds.txt if the user does not manually specify these.
# Globals:
#  GITLAB_SERVER_HTTP_URL.
#  GITLAB_SERVER_ACCOUNT_GLOBAL
#  GITLAB_ROOT_EMAIL_GLOBAL
# Arguments:
#  gitlab -url The GitLab server that was originally passed as input argument to this 
#  program by the user.
#  gitlab_root_username  - 
#  gitlab_email - 
# Returns:
#  0 if the function is set correctly.
# Outputs:
#  Nothing
# TODO(a-t-0): Include verification on url format (Must have http:// (I think)).
# TODO(a-t-0): Include verification on email format.
# TODO(a-t-0): Include verification on GitLab username format (a-Z0-9).
#######################################
# Run with: 
# bash -c "source src/import.sh && set_default_personal_creds_if_empty gitlab_urls gitlab_username gitlab@email.com"
set_default_personal_creds_if_empty() {
	local gitlab_url="$1"
	local gitlab_root_username="$2"
	local gitlab_email="$3"

	set_default_personal_cred_if_empty "GITLAB_SERVER_HTTP_URL" $gitlab_url
	set_default_personal_cred_if_empty "GITLAB_SERVER_ACCOUNT_GLOBAL" $gitlab_root_username
	set_default_personal_cred_if_empty "GITLAB_ROOT_EMAIL_GLOBAL" "$gitlab_email"
}

# Run with: 
# bash -c "source src/import.sh && set_gitlab_pwd gitlab_pwd"
set_gitlab_pwd() {
	local gitlab_pwd="$1"
	
	if [ "$gitlab_pwd" != "" ]; then
		set_default_personal_cred_if_empty "GITLAB_SERVER_PASSWORD_GLOBAL" "$gitlab_pwd"
	else
		echo "Error, the GitLab password entered by the user is empty."
		exit 5
	fi
}


# Run with: 
# bash -c "source src/import.sh && assert_required_repositories_exist a-t-0"
assert_required_repositories_exist(){
	local github_username="$1"
	#$GITHUB_STATUS_WEBSITE_GLOBAL
	#$PUBLIC_GITHUB_TEST_REPO_GLOBAL
	if [ $(check_public_github_repository_exists $GITHUB_STATUS_WEBSITE_GLOBAL) == "FOUND" ]; then
		if [ $(check_public_github_repository_exists $PUBLIC_GITHUB_TEST_REPO_GLOBAL) == "FOUND" ]; then
			echo "FOUND"
		else
			echo "Before installing GitLab, please ensure the repository:$PUBLIC_GITHUB_TEST_REPO_GLOBAL exists in your GitHub account:$github_username"
			exit 11
		fi
	else
		echo "Before installing GitLab, please ensure the repository:$GITHUB_STATUS_WEBSITE_GLOBAL exists in your GitHub account:$github_username"
		exit 12
	fi
}

# Run with: 
# bash -c "source src/import.sh && ensure_github_pat_can_be_used_to_set_commit_build_status a-t-0 sponsor_example "
ensure_github_pat_can_be_used_to_set_commit_build_status() {
	local github_username="$1"
	local github_reponame_to_set_commit_status_on="$2"
	local github_pat="$3"

	# TODO(a-t-0): Ensure the github_reponame_to_set_commit_status_on repository is 
	# created in GitHub.

	# Verify github repository exists.
	assert_public_github_repository_exists "$GITHUB_USERNAME_GLOBAL" "$github_reponame_to_set_commit_status_on"

	# TODO: Get the latest commit of that repository.

	

	# If GitHub pat is in personal_creds.txt:
		# Safely check if it can be used to set the github commit status
		# if yes, return FOUND
	# else
		# if github_pat is empty:
			# raise error, saying, you don't want to be using the default token.
		# else:
			# write github pat to file.
			# Safely check if it can be used to set the github commit status
			# if yes, return FOUND
			# if no, raise error, saying it did not work for unknown reason.
		#fi
	#fi

}

ensure_github_ssh_deploy_key_can_be_used_to_push_github_build_status() {
	local github_username="$1"
	local github_pat="$2"

	# TODO(a-t-0): Ensure the GITHUB_STATUS_WEBSITE_GLOBAL repository is 
	# created in GitHub.

	# Verify if the GitLab Build Status repository exists in GitHub.	
	assert_public_github_repository_exists "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL"

	# Get the GitHub ssh deploy key to push and pull the GitLab build status 
	# icons to the GitHub build status repository.
	get_github_build_status_repo_ssh_deploy_key "example@example.com" "some_github_deploy_key"
	verify_machine_has_push_access_to_gitlab_build_status_repo_in_github "some_github_deploy_key"
	read -p "Got the personal access token"
}

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
assert_github_pat_can_be_used_to_set_commit_build_status() {
	local github_username="$1"
	local github_reponame="$2"
	# Get the GitHub personal access token to set the commit build status.
	#get_github_personal_access_token $GITHUB_USERNAME_GLOBAL	
	# Verify the GitHub personal access token is able to set the commit build 
	# status.
	# Reload GitHub personal access token from personal credentials.
	source "$PERSONAL_CREDENTIALS_PATH"
	
	# TODO: ensure the personal creds file contains the credentials.

	# Set and verify being able to set commit build status for: pending
	set_build_status_of_github_commit_using_github_pat "$github_username" "$github_reponame" "$COMMIT_WHOSE_BUILD_STATUS_IS_SET_FOR_TESTING_PURPOSES" "$GITLAB_SERVER_HTTP_URL"  "pending"
	# Set and verify being able to set commit build status for: success
	set_build_status_of_github_commit_using_github_pat "$github_username" "$github_reponame" "$COMMIT_WHOSE_BUILD_STATUS_IS_SET_FOR_TESTING_PURPOSES" "$GITLAB_SERVER_HTTP_URL"  "success"
	# TODO: verify this method set_build_status_of_github_commit_using_github_pat contains an assert
	# and change the name accordingly
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