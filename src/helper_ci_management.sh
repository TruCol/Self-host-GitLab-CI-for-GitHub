#!/bin/bash

github_commit_already_has_gitlab_ci_build_status_result() {
	github_repo_name="$1"
	github_branch_name="$2"
	company="$3"
	
	# Get GitHub username.
	github_username=$1
	
	# Verify the mirror location exists
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_file_exist "$MIRROR_LOCATION"
	manual_assert_file_exist "$MIRROR_LOCATION/GitHub"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$github_username" "$GITHUB_STATUS_WEBSITE")"
	
	# Determine whether the Build status repository is cloned.
	repo_was_cloned=$(verify_github_repository_is_cloned "$GITHUB_STATUS_WEBSITE" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE")
	
	# Ensure the GitLab build status repository is cloned.
	if [ "$repo_was_cloned" == "FOUND" ]; then
		# If it does exist, do a git pull to ensure one uses the latest version.
		
	else
		# 8. Clone the GitHub build statusses repository.
		clone_github_repository "$github_username" "$GITHUB_STATUS_WEBSITE" "$has_access" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE"
	fi
	
	# 9. Verify the Build status repository is cloned.
	repo_was_cloned=$(verify_github_repository_is_cloned "$GITHUB_STATUS_WEBSITE" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE")
	manual_assert_equal "$repo_was_cloned" "FOUND"
	
	# Check if the commit build status file exists, if yes, echo FOUND.
	# Otherwise, echo NOTFOUND.
}