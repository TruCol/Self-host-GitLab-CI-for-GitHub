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
# Structure:dir_edit
# Ensure mirrors directory is created.
create_mirror_directories() {
	create_dir "$MIRROR_LOCATION"
	create_dir "$MIRROR_LOCATION/GitHub"
	create_dir "$MIRROR_LOCATION/GitLab"
}


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
# Structure:dir_edit
#assert_equal "$(dir_exists "$MIRROR_LOCATION")" "FOUND" 
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
# Structure:dir_edit
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
# Structure:dir_edit
copy_files_from_github_to_gitlab_repo_branches() {
	git_repository=$1
	rsync -av --progress "$MIRROR_LOCATION/GitHub/$git_repository/" "$MIRROR_LOCATION/GitLab/$git_repository" --exclude .git
}