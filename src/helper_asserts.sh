#!/bin/bash


#######################################
# Verifies a file exists, throws error otherwise.
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
#######################################
manual_assert_file_exists() {
	local filepath="$1"
	if [ ! -f "$filepath" ]; then
		echo "The file: $filepath does not exist."
		exit 29
	fi
}

#######################################
# Verifies a file does not exists, throws error otherwise.
# Local variables:
#  filepath
# Globals:
#  None.
# Arguments:
#  Relative filepath of file whose existance is verified.
# Returns:
#  0 If file was found.
#  30 If the file was not found.
# Outputs:
#  Nothing
#######################################
manual_assert_file_does_not_exists() {
	local filepath="$1"
	if [ -f "$filepath" ]; then
		echo "The file: $filepath exists, even though it shouldn't."
		exit 30
	fi
}


#######################################
# Verifies a directory exists, throws error otherwise.
# Local variables:
#  dirpath
# Globals:
#  None.
# Arguments:
#  Relative folderpath of folder whose existance is verified.
# Returns:
#  0 If folder was found.
#  31 If the folder was not found.
# Outputs:
#  Nothing
#######################################
manual_assert_dir_exists() {
	local dirpath="$1"
	if [ ! -d "$dirpath" ]; then
		echo "The dir: $dirpath does not exist, even though one would expect it does."
		exit 31
	fi
}


#######################################
# Asserts a directory does not exist. Throws an error if it does.
# Local variables:
#  dirpath
# Globals:
#  None.
# Arguments:
#  Relative folderpath of folder whose existance is verified.
# Returns:
#  0 If folder was found.
#  29 If the folder was not found.
# Outputs:
#  Nothing
#######################################
manual_assert_dir_not_exists() {
	local dirpath=$1
	if [ -d "$dirpath" ]; then
		echo "The dir: $dirpath exists, even though the directory should have been deleted."
		exit 29
	fi
}


#######################################
# Asserts the left and right strings are equal to eachother. Throws error if
# they are not equal.
# Local variables:
#  left
#  right
# Globals:
#  None.
# Arguments:
#  Relative folderpath of folder whose existance is verified.
# Returns:
#  0 If the two values are equal.
#  32 If the two values are different.
# Outputs:
#  Nothing
#######################################
manual_assert_equal() {
	local left="$1"
	local right="$2"
	if [ "$left" != "$right" ]; then
		echo "Error, $left does not equal: $right"
		exit 32
	fi
}


#######################################
# Asserts the left and right strings are not equal to eachother. Throws error
# if they are equal.
# Local variables:
#  left
#  right
# Globals:
#  None.
# Arguments:
#  Relative folderpath of folder whose existance is verified.
# Returns:
#  0 If the two values are different.
#  33 If the two values are equal.
# Outputs:
#  Nothing
#######################################
manual_assert_not_equal() {
	local left="$1"
	local right="$2"
	if [ "$left" == "$right" ]; then
		echo "Error, $left equals: $right"
		exit 33
	fi
}