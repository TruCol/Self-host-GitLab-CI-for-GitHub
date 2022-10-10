#!/bin/bash
#######################################
# Checks whether the md5 checkum of the file specified with the incoming filepath
# matches that of an expected md5 filepath that is incoming.
# Local variables:
# expected_md5sum
# relative_filepath
# actual_md5sum
# actual_md5sum_head
# Globals:
#  None.
# Arguments:
#  expected_md5sum - the md5sum that is expected to be found at some file/dir.
#  relative_filepath - Filepath to file/dir whose md5sum is computed, seen from 
#  the root directory of this repository.
# Returns:
#  0 at all times, unless an unexpected error is thrown by e.g. md5sum.
# Outputs:
#  "EQUAL" if the the expected md5sum equals the measured md5sum.
# "NOTEQUAL" otherwise.
# TODO(a-t-0): rename the method to "check if md5sum is as expected.
# TODO(a-t-0): Create a duplicate named "assert.." that throws an error if the
# md5sum of the dir/file that is being inspected, is different than expected.
#######################################
# Structure:Verification
check_md5_sum() {
	local expected_md5sum=$1
	local relative_filepath=$2
	
	# Read out the md5 checksum of the downloaded social package.
	local actual_md5sum=$(sudo md5sum "$relative_filepath")
	
	# Extract actual md5 checksum from the md5 command response.
	local actual_md5sum_head=${actual_md5sum:0:32}
	
	# Assert the measured md5 checksum equals the hardcoded md5 checksum of the expected file.
	#manual_assert_equal "$md5_of_social_package_head" "$TWRP_MD5"
	if [ "$actual_md5sum_head" == "$expected_md5sum" ]; then
		echo "EQUAL"
	else
		echo "NOTEQUAL"
	fi
}

#######################################
# Calls the function that computes the md5sum of the GitLab installation file 
# that is being downloaded for the architecture that's detected in this system.
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
# TODO(a-t-0): Make this function call a hardcoded list/swtich case of expected
# md5sums from eg hardcoded variables.txt, and make it automatically 
# compute the md5sum of the respective architecture.
# TODO(a-t-0):  Run the "has supported architecture check before running the 
# md5 check.
#######################################
# Structure:Verification
# 
# 
get_expected_md5sum_of_gitlab_runner_installer_for_architecture() {
	local mapped_architecture=$1
	if [ "$mapped_architecture" == "amd64" ]; then
		# shellcheck disable=SC2154
		echo $x86_64_runner_checksum
	else
		echo "ERROR, this architecture:$mapped_architecture is not yet supported by this repository, meaning we did not yet find a GitLab runner package for this architecture. So there is no md5sum available for verification of the md5 checksum of such a downloaded package."
		exit 15
	fi
}