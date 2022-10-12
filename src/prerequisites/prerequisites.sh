#!/bin/bash
# This script contains code that is called by the install_gitlab.sh script to
# verify the installation prerequisites/requirements are met.

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
		set_default_personal_cred_if_empty "GITLAB_SERVER_PASSWORD_GLOBAL" "$gitlab_pwd"
	else
		echo "Error, the GitLab password entered by the user is empty."
		exit 5
	fi
}

#######################################
# Assertes that the following GitHub resositories of this user exist:
# 0. A GitHub respository that stores the GitLab CI build statusses.
# 1. A GitHub respository that can be used to test the GitLab CI.
# Throws an error if either of these two repositories is missing.
# Locals:
#  github_username
# Globals:
#  GITHUB_STATUS_WEBSITE_GLOBAL
#  PUBLIC_GITHUB_TEST_REPO_GLOBAL
# Arguments:
#  github_username
# Returns:
#  0 If command was evaluated successfully.
#  11 if the GitHub repository for GitLab CI testing purposes, is missing.
#  12 if the GitHub repository containing the GitLab CI build statusses, is
#  missing.
# Outputs:
#  FOUND if Both repositories are found. 
#######################################
# Run with: 
# bash -c "source src/import.sh && assert_required_repositories_exist a-t-0"
# TODO: silence the echo "FOUND" if assert passes.
# TODO: include catch for: The requested URL returned error: 403 rate limit exceeded
assert_required_repositories_exist(){
	local github_username="$1"
	#$GITHUB_STATUS_WEBSITE_GLOBAL
	#$PUBLIC_GITHUB_TEST_REPO_GLOBAL
	if [ $(check_public_github_repository_exists "$github_username" $GITHUB_STATUS_WEBSITE_GLOBAL) == "FOUND" ]; then
		if [ $(check_public_github_repository_exists "$github_username" $PUBLIC_GITHUB_TEST_REPO_GLOBAL) == "FOUND" ]; then
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

	local latest_commit_on_default_branch="$(get_latest_commit_public_github_repo "$github_username"	"$PUBLIC_GITHUB_TEST_REPO_GLOBAL")"

	# Get the GitHub personal access token to set the commit build status.
	#ensure_github_pat_is_added_to_github $GITHUB_USERNAME_GLOBAL	
	# Verify the GitHub personal access token is able to set the commit build 
	# status.
	# Reload GitHub personal access token from personal credentials.
	source "$PERSONAL_CREDENTIALS_PATH"
	
	# TODO: ensure the personal creds file contains the credentials.

	# Set and verify being able to set commit build status for: pending
	set_build_status_of_github_commit_using_github_pat "$github_username" "$github_reponame" "$latest_commit_on_default_branch" "$GITLAB_SERVER_HTTP_URL"  "pending"
	# Set and verify being able to set commit build status for: success
	set_build_status_of_github_commit_using_github_pat "$github_username" "$github_reponame" "$latest_commit_on_default_branch" "$GITLAB_SERVER_HTTP_URL"  "success"
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
	    assert_file_contains_string "$identifier=$GITLAB_SERVER_HTTP_URL" "$PERSONAL_CREDENTIALS_PATH" > /dev/null 2>&1 &
	fi
	# Assert the PERSONAL_CREDENTIALS_PATH contains GITLAB_SERVER_HTTP_URL.
	assert_file_contains_string "$identifier" "$PERSONAL_CREDENTIALS_PATH" > /dev/null 2>&1 &
	
}

verify_prerequisite_personal_creds_txt_contain_required_data() {
	if [ $(file_contains_string "GITHUB_USERNAME_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITHUB_USERNAME_GLOBAL is not in "
		echo "$PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

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

verify_prerequisite_personal_creds_txt_loaded() {
	if [ "$GITHUB_USERNAME_GLOBAL" == "" ]; then
		echo "Error, the GITHUB_USERNAME_GLOBAL:$GITHUB_USERNAME_GLOBAL is not"
		echo " loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

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

verify_personal_creds_txt_contain_pacs() {
	if [ $(file_contains_string "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL is not in $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
	if [ "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]; then
		echo "Error, the GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL is not loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi


	if [ $(file_contains_string "GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL is not in $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
	if [ "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]; then
		echo "Error, the GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL is not loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
}