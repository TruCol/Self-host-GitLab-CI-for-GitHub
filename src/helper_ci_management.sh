#!/bin/bash


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
# Run with:
# bash -c "source src/import.sh && github_commit_already_has_gitlab_ci_build_status_result a-t-0 sponsor_example attack_in_new_file aeaaa57120f74a695ef4215e819a175296a3de10"
# source src/import.sh src/helper_ci_management.sh && github_commit_already_has_gitlab_ci_build_status_result "a-t-0" "sponsor_example" "no_attack_in_filecontent" "0dee4abdc50ccd7683eb4326678d8c9dde4ea05d"
github_commit_already_has_gitlab_ci_build_status_result() {
	local github_username="$1"
	local github_repo_name="$2"
	local github_branch_name="$3"
	local github_commit_sha="$4"
	
	
	# Verify the mirror location exists
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_dir_exists "$MIRROR_LOCATION"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub"
	
	# Verify ssh-access
	#has_access="$(check_ssh_access_to_repo "$github_username" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
	
	# Determine whether the Build status repository is cloned.
	repo_was_cloned=$(verify_github_repository_is_cloned "$GITHUB_STATUS_WEBSITE_GLOBAL" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL")
	#read -p "repo_was_cloned=$repo_was_cloned"

	# Ensure the GitLab build status repository is cloned.
	if [ "$repo_was_cloned" == "FOUND" ]; then
		# If it does exist, do a git pull to ensure one uses the latest version.
		git_pull_github_repo "$GITHUB_STATUS_WEBSITE_GLOBAL"
	else
		# Clone the GitHub build statusses repository.
		download_and_overwrite_repository_using_ssh "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
		# Verify the Build status repository is cloned.
		manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	fi
	# 9. Verify the Build status repository is cloned.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	
	# Check if the commit build status file exists, if yes, echo FOUND.
	# Otherwise, echo NOTFOUND.
	#read -p "checking if:$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name/$github_commit_sha.txt exists"
	file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name/$github_commit_sha.txt"
}