
#######################################
# Creates and adds the GitHub personal access token (PAT), using the Python repository:
# get-gitlab-runner-registration-token, to GitHub and stores it locally in the
# credentials file. Then reloads the credentials file and verifies whether the
# GitHub PAT can be used to set/change GitHub commit build statusses.
#
# Locals:
#  github_username
#  PUBLIC_GITHUB_TEST_REPO_GLOBAL
#  latest_commit_on_default_branch
#  github_pwd
#  personal_credits_contain_global
#  set_pending
#  set_succes
# Globals:
#  PERSONAL_CREDENTIALS_PATH
#  PUBLIC_GITHUB_TEST_REPO_GLOBAL
# Arguments:
#  github_username
#  PUBLIC_GITHUB_TEST_REPO_GLOBAL
#  github_pwd
# Returns:
#  0 If the GitHub commit build statusses can be set correctly.
#  4 If the GitHub commit sha has a length other than the expected 40.
# Outputs:
#  A lot of text on how the function was evaluated.
#######################################
set_personal_github_pat_and_verify() {
	local github_username="$1"
	local latest_commit_on_default_branch="$2"
	local github_pwd="$3"

	
	# Ensure the PERSONAL_CREDENTIALS_PATH file exists, (and create it if not).
	ensure_file_exists "$PERSONAL_CREDENTIALS_PATH"

	# TODO: first verify if the GitHub pat exists and can be used, before
	# creating a new one.
	# Get github pat and ensure it is in PERSONAL_CREDENTIALS_PATH.
	ensure_github_pat_is_added_to_github $github_username $github_pwd
	
	# Reload personal credentials to load new GitHub token.
	source "$PERSONAL_CREDENTIALS_PATH"

	# Assert the GitHub pat can be used to set the github commit status.
	# TODO: verify if this is not a duplicate function of: 
	# ensure_github_pat_can_be_used_to_set_commit_build_status
	printf "5.g Verifying the GitHub personal access token can be used to set"
	printf "a commit status to: Pending."
	set_build_status_of_github_commit_using_github_pat $github_username $PUBLIC_GITHUB_TEST_REPO_GLOBAL $latest_commit_on_default_branch $GITLAB_SERVER_HTTP_URL "pending"
	
	printf "5.h Verifying the GitHub personal access token can be used to set"
	printf "a commit status to: Success."
	set_build_status_of_github_commit_using_github_pat $github_username $PUBLIC_GITHUB_TEST_REPO_GLOBAL $latest_commit_on_default_branch $GITLAB_SERVER_HTTP_URL "success"
}

