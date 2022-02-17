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
establish_prerequisites() {
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