#!/bin/bash


#######################################
# Ensures creation of the directories in which the GitHub and GitLab 
# repositories will be downloaded. Then it verifies these directories
# are indeed created.
# Local variables:
#  None.
# Globals:
#  $MIRROR_LOCATION
# Arguments:
#  None.
# Returns:
#  0 If function was evaluated succesfull.
#  1 If the mirror directory was not created.
#  2 If the GitLab folder was not created in the mirror directory.
#  3 If the GitHub folder was not created in the mirror directory.
# Outputs:
#  None.
#######################################
create_mirror_directories() {
	create_dir "$MIRROR_LOCATION"
	create_dir "$MIRROR_LOCATION/GitHub"
	create_dir "$MIRROR_LOCATION/GitLab"

	# Run function that asserts the mirror directories are indeed created.
	verify_mirror_directories_are_created
}


#######################################
# Verifies the directories in which the GitHub and GitLab repositories will be
# downloaded, indeeed exist. Throws an error if any dir is missing.
# Local variables:
#  None.
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  None.
# Returns:
#  0 If function was evaluated succesfull.
#  1 If the mirror directory was not created.
#  2 If the GitLab folder was not created in the mirror directory.
#  3 If the GitHub folder was not created in the mirror directory.
# Outputs:
#  FOUND if the mirror dir was found, and it contains 2 folders named GitHub 
# and GitLab.
#######################################
verify_mirror_directories_are_created() {
	if [ "$MIRROR_LOCATION" == "" ]; then
		echo "Mirror location is not created"
		exit 1
	elif test ! -d "$MIRROR_LOCATION"; then
		echo "Mirror location is not created"
		exit 2
	elif test ! -d "$MIRROR_LOCATION/GitLab"; then
		echo "Mirror location GitLab directory is not created"
		exit 3
	else
		echo "FOUND"
	fi
}


#######################################
# Ensures the directories in which the GitHub and GitLab repositories will be 
# downloaded, do not exist anymore. Then it verifies these directories are 
# indeed non-existant. Throws error if any of the three directories still 
# exists.
# Local variables:
#  None.
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  None.
# Returns:
#  0 If function was evaluated succesfull.
#  29 If any of the three directories do not exist.
# Outputs:
#  None.
#######################################
remove_mirror_directories() {
	remove_dir "$MIRROR_LOCATION"
	remove_dir "$MIRROR_LOCATION/GitHub"
	remove_dir "$MIRROR_LOCATION/GitLab"

	# Verify the directories are removed.
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_dir_not_exists "$MIRROR_LOCATION"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitHub"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitLab"
}


#######################################
# Ensures all files and folders, excluding the .git folder, of a locally
# cloned repository named git_repository are copied from GitHub to GitLab.
# Local variables:
#  git_repository
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  git_repository - The name of the GitHub repository from which the files are
#  copied (to the GitLab repository with the same name).
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0): Specify Outputs of this function.
# TODO(a-t-0): Include assert on correctness of output of the rsync command.
# TODO(a-t-0): Include assert (call to function) that verifies the contents of
# the GitHub and GitLab repository directories are indeed identical, (when 
# excluding the .git folder). Note this function already exists I think.
#######################################
# Structure:dir_edit
copy_files_from_github_to_gitlab_repo_branches() {
	local git_repository=$1
	rsync -av --progress "$MIRROR_LOCATION/GitHub/$git_repository/" "$MIRROR_LOCATION/GitLab/$git_repository" --exclude .git
}