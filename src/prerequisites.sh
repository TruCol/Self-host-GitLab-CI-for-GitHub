#!/bin/bash

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

# Run with: 
# bash -c "source src/import.sh && ensure_github_pat_can_be_used_to_set_commit_build_status a-t-0 sponsor_example"
ensure_github_pat_can_be_used_to_set_commit_build_status() {
	local github_username="$1"
	local github_reponame_to_set_commit_status_on="$2"
	local github_pwd="$3"
	
	# TODO(a-t-0): Ensure the github_reponame_to_set_commit_status_on repository is 
	# created in GitHub.

	# Verify github repository exists.
	assert_public_github_repository_exists "$github_username" "$github_reponame_to_set_commit_status_on"

	# Get the latest commit of that repository.
	latest_commit_on_default_branch=$(get_latest_commit_public_github_repo $github_username $github_reponame_to_set_commit_status_on)

	
	if [ ${#latest_commit_on_default_branch} -eq 40 ]; then 
		echo "len=${#latest_commit_on_default_branch}"
	else 
		echo "Error, the commit sha:$latest_commit_on_default_branch is not of correct length"
		exit 4
	fi
	
	ensure_file_exists "$PERSONAL_CREDENTIALS_PATH"
	
	local personal_credits_contain_global=$(file_contains_string "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH")

	if [ "$personal_credits_contain_global" == "FOUND" ]; then
		echo "Found GitHub pat in personal_creds.txt"
		echo "github_username=$github_username"
		echo "github_reponame_to_set_commit_status_on=$github_reponame_to_set_commit_status_on"
		echo "latest_commit_on_default_branch=$latest_commit_on_default_branch"
		echo "GITLAB_SERVER_HTTP_URL=$GITLAB_SERVER_HTTP_URL"
		set_pending=$(check_if_can_set_build_status_of_github_commit_using_github_pat $github_username $github_reponame_to_set_commit_status_on $latest_commit_on_default_branch $GITLAB_SERVER_HTTP_URL "pending")
		#echo "set_pending=$set_pending"
		
		# Safely check if it can be used to set the github commit status
		if [ "$set_pending" == "TRUE" ]; then
			echo "Set status to pending"
			set_succes=$(check_if_can_set_build_status_of_github_commit_using_github_pat $github_username $github_reponame_to_set_commit_status_on $latest_commit_on_default_branch $GITLAB_SERVER_HTTP_URL "success")
			echo "set_succes=$set_succes"
			if [ "$set_succes" == "TRUE" ]; then
				echo "Set status to success"
			else
				echo "Did not set status to success"
				set_personal_github_pat_and_verify $github_username $github_reponame_to_set_commit_status_on $latest_commit_on_default_branch $github_pwd
			fi
		else
			echo "Did not set status to pending"
			set_personal_github_pat_and_verify $github_username $github_reponame_to_set_commit_status_on $latest_commit_on_default_branch $github_pwd
		fi
	else
		echo "Did not find GitHub pat in personal_creds"
		set_personal_github_pat_and_verify $github_username $github_reponame_to_set_commit_status_on $latest_commit_on_default_branch $github_pwd
	fi
}

set_personal_github_pat_and_verify() {
	local github_username="$1"
	local github_reponame_to_set_commit_status_on="$2"
	local latest_commit_on_default_branch="$3"
	local github_pwd="$4"

	
	# Ensure the PERSONAL_CREDENTIALS_PATH file exists(create if not).
	ensure_file_exists "$PERSONAL_CREDENTIALS_PATH"

	# Get github pat and ensure it is in PERSONAL_CREDENTIALS_PATH.
	get_github_personal_access_token $github_username $github_pwd
	
	# Reload personal credentials to load new GitHub token.
	source "$PERSONAL_CREDENTIALS_PATH"


	# Assert the GitHub pat can be used to set the github commit status.
	printf "\n\n\n Verifying the GitHub personal access token can be used to set a commit status to: Pending."
	set_build_status_of_github_commit_using_github_pat $github_username $github_reponame_to_set_commit_status_on $latest_commit_on_default_branch $GITLAB_SERVER_HTTP_URL "pending"
	printf "\n\n\n Verifying the GitHub personal access token can be used to set a commit status to: Success."
	set_build_status_of_github_commit_using_github_pat $github_username $github_reponame_to_set_commit_status_on $latest_commit_on_default_branch $GITLAB_SERVER_HTTP_URL "success"

	#ensure_global_is_in_file "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$github_pat"
}


# Run with: 
# bash -c "source src/import.sh && ensure_github_ssh_deploy_key_can_be_used_to_push_github_build_status a-t-0"
ensure_github_ssh_deploy_key_can_be_used_to_push_github_build_status() {
	local github_username="$1"
	local github_pwd="$2"

	# Assumes the GitLab build status repository exists in GitHub.
	# Verify if the GitLab build status repository exists in GitHub.	
	assert_public_github_repository_exists "$github_username" "$GITHUB_STATUS_WEBSITE_GLOBAL"

	# Get the GitHub ssh deploy key to push and pull the GitLab build status 
	# icons to the GitHub build status repository.
	printf "\n\n\n Ensuring a ssh deploy key is to GitHub to push build status icons to your build status repository.\n\n\n."
	get_github_build_status_repo_ssh_deploy_key "example@example.com" "$GITHUB_SSH_DEPLOY_KEY_NAME" "$github_username" "$github_pwd"
	printf "\n\n\n Verifying the GitHub ssh deploy token is able to push build status icons to your build status repository.\n\n\n."
	verify_machine_has_push_access_to_gitlab_build_status_repo_in_github "$GITHUB_SSH_DEPLOY_KEY_NAME"
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

verify_prerequisite_personal_creds_txt_contain_required_data() {
	if [ $(file_contains_string "GITHUB_USERNAME_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITHUB_USERNAME_GLOBAL is not in $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ $(file_contains_string "GITLAB_SERVER_ACCOUNT_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITLAB_SERVER_ACCOUNT_GLOBAL is not in $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ $(file_contains_string "GITLAB_SERVER_PASSWORD_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITLAB_SERVER_PASSWORD_GLOBAL is not in $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ $(file_contains_string "GITLAB_ROOT_EMAIL_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITLAB_ROOT_EMAIL_GLOBAL is not in $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
}

verify_prerequisite_personal_creds_txt_loaded() {
	if [ "$GITHUB_USERNAME_GLOBAL" == "" ]; then
		echo "Error, the GITHUB_USERNAME_GLOBAL:$GITHUB_USERNAME_GLOBAL is not loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ "$GITLAB_SERVER_ACCOUNT_GLOBAL" == "" ]; then
		echo "Error, the GITLAB_SERVER_ACCOUNT_GLOBAL is not loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ "$GITLAB_SERVER_PASSWORD_GLOBAL" == "" ]; then
		echo "Error, the GITLAB_SERVER_PASSWORD_GLOBAL is not loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi

	if [ "$GITLAB_ROOT_EMAIL_GLOBAL" == "" ]; then
		echo "Error, the GITLAB_ROOT_EMAIL_GLOBAL is not loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
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