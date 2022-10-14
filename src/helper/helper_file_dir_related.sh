#!/bin/bash

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# Structure:dir_edit
dir_exists() {
	dir=$1 
	[ -d "$dir" ] && echo "FOUND" || echo "NOTFOUND"
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# Structure:dir_edit
sudo_dir_exists() {
	dir=$1 
	if sudo test -d "$dir"; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# Structure:file_edit
file_exists() {
	filepath=$1 
	if test -f "$filepath"; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi

}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# # Structure:file_edit
sudo_file_exists() {
	filepath=$1 
	if sudo test -f "$filepath"; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi

}

#######################################
# Creates file if it does not yet exist, and verifies the file exists 
# afterwards.
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
ensure_file_exists() {
	filepath="$1"
	touch "$filepath"

	manual_assert_file_exists "$filepath"
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# Structure:dir_edit
create_dir() {
	abs_dir=$1
	if [ "$(dir_exists "$abs_dir")" == "NOTFOUND" ]; then
		mkdir "$abs_dir"
	fi
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# Structure:dir_edit
remove_dir() {
	abs_dir=$1
	# TODO: silence.
	if [ "$(dir_exists "$abs_dir")" == "FOUND" ]; then
		rm -rf "$abs_dir"
	fi
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# Structure:dir_edit
make_user_owner_of_dir() {
	user=$1
	dir=$2
	#sudo chown -R gitlab-runner: $path_to_gitlab_hook_dir
	sudo chown -R "$user": "$dir"
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# Structure:dir_edit
is_owner_of_dir() {
	owner=$1
	dir=$2
	output=$(sudo ls -ld "$dir")
	actual_result=$(lines_contain_string "$owner" "\${output}")
	echo "$actual_result"
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
# Structure:dir_edit
# Checks whether the path before and after a command that 
# contains: "cd", is the same.
path_before_equals_path_after_command() {
	pwd_before="$1"
	pwd_after="$2"
	
	if [ "$pwd_before" != "$pwd_after" ]; then
		exit 179
	fi
}


#######################################
# Deletes file if it exists, and then asserts the file is deleted.
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0):
#######################################
delete_file_if_it_exists() {
	local filepath="$1"
	rm -f -- "$filepath"
	manual_assert_file_does_not_exists "$filepath"
}


#######################################
# Checks if either of the two test boolean files exist in a repository.
# Local variables:
#  dir
# Globals:
#  TEST_FILENAME_TRUE
#  TEST_FILENAME_FALSE
# Arguments:
#   
# Returns:
#  0 if the function was executed succesfully. 
# Outputs:
#  FOUND if either of the two files is found.
#  NOTFOUND if neither of the two test boolean files are found.
# TODO(a-t-0):
#######################################
dir_contains_at_least_one_test_boolean_file() {
	local dir="$1"
	
	if [ "$(file_exists "$dir/$TEST_FILENAME_TRUE")" == "FOUND" ]; then
		echo "FOUND"
	elif [ "$(file_exists "$dir/$TEST_FILENAME_FALSE")" == "FOUND" ]; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}