#!/bin/bash
# This script contains code that is called by the install_gitlab.sh script to
# verify the installation prerequisites/requirements are met.



#######################################
# Assertes that a GitHub user has a GitHub repository.
# Throws an error if either of these two repositories is missing.
# Locals:
#  github_username
#  repo_name
# Globals:
#  None
# Arguments:
#  github_username
#  repo_name
# Returns:
#  0 If command was evaluated successfully.
#  11 if the GitHub repository is missing.
# Outputs:
#  Nothing if the method is successfull.
# TODO: 
#  include catch for:The requested URL returned error: 403 rate limit exceeded.
#######################################
# Run with: 
# bash -c 'source src/import.sh && assert_required_repositories_exist_in_github_server a-t-0'

assert_required_repositories_exist_in_github_server(){
	local github_username="$1"
	local repo_name="$2"
	
	local repo_exists_with_api
	repo_exists_with_api=$(check_public_github_repository_exists_with_api "$github_username" "$repo_name")
	local repo_exists_without_api
	repo_exists_without_api=$(check_public_github_repository_exists_without_api "$github_username" "$repo_name")
	
	if [[ "$repo_exists_with_api" == "NOTFOUND" ]] && [[ "$repo_exists_without_api" == "NOTFOUND" ]]; then
		echo "Error, before installing GitLab, please ensure the repository:$repo_name exists in your GitHub account:$github_username"
		echo "To ensure the content is valid, fork it from: https://www.github.com/a-t-0/$repo_name"
		exit 11
	elif [[ "$repo_exists_with_api" == "FOUND" ]] || [[ "$repo_exists_without_api" == "FOUND" ]]; then
		echo ""
	else
		echo "Error, did not find GitHub repo at:$github_username/$repo_name"
		echo " with: repo_exists_with_api=$repo_exists_with_api and repo_exists_without_api=$repo_exists_without_api"
	fi
}

#######################################
# Assertes the user has SSH access to GitHub.
# Throws an error if no SSH access to GitHub has been found.
# Locals:
#  github_username
# Globals:
#  None
# Arguments:
#  github_username
# Returns:
#  0 If command was evaluated successfully.
#  11 if the GitHub user does not have SSH access to GitHub.
# Outputs:
#  Nothing if the method is successfull.
#######################################
# Run with: 
# bash -c 'source src/import.sh && assert_user_has_ssh_access_to_github a-t-0'
assert_user_has_ssh_access_to_github(){
	local github_username="$1"

	local ssh_probe_response=$(ssh -T git@github.com 2>&1)
	# local expected_output="Hi $github_username! You've successfully authenticated, but GitHub does not provide shell access."
	local expected_output='successfully authenticated, but GitHub does not provide shell access.'

	# if [ "$ssh_probe_response" != *"$expected_output"* ]; then
	if [[ "$ssh_probe_response" != *"successfully authenticated, but GitHub does not provide shell access."* ]]; then
		echo "Before installing GitLab, please ensure GitHub user:$github_username"
		echo "has ssh-access to GitHub. See: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent"
		echo ""
		echo "Error, $ssh_probe_response != $expected_output"
		exit 11
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

	# Reload GitHub personal access token from personal credentials.
	source "$PERSONAL_CREDENTIALS_PATH"
	local latest_commit_on_default_branch="$(get_latest_commit_public_github_repo "$github_username"	"$PUBLIC_GITHUB_TEST_REPO_GLOBAL")"

	
	# TODO: ensure the personal creds file contains the credentials.

	# Set and verify being able to set commit build status for: pending
	set_build_status_of_github_commit_using_github_pat "$github_username" "$github_reponame" "$latest_commit_on_default_branch" "$GITLAB_SERVER_HTTP_URL"  "pending"
	# Set and verify being able to set commit build status for: success
	set_build_status_of_github_commit_using_github_pat "$github_username" "$github_reponame" "$latest_commit_on_default_branch" "$GITLAB_SERVER_HTTP_URL"  "success"
	# TODO: verify this method set_build_status_of_github_commit_using_github_pat contains an assert
	# and change the name accordingly
}



verify_prerequisite_personal_creds_txt_contain_required_github_data() {
	if [ $(file_contains_string "GITHUB_USERNAME_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITHUB_USERNAME_GLOBAL is not in "
		echo "$PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
}

verify_prerequisite_github_personal_creds_txt_loaded() {
	if [ "$GITHUB_USERNAME_GLOBAL" == "" ]; then
		echo "Error, the GITHUB_USERNAME_GLOBAL:$GITHUB_USERNAME_GLOBAL is not"
		echo " loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
}

verify_github_pac_exists_in_persional_creds_txt() {
	if [ $(file_contains_string "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH") != "FOUND" ]; then
		echo "Error, the GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL is not in $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
	if [ "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]; then
		echo "Error, the GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL is not loaded correctly from: $PERSONAL_CREDENTIALS_PATH"
		exit 5
	fi
}