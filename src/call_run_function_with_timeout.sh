#!/bin/bash

# Run with:
# bash -c eg_func
# bash -c "source src/import.sh && call_eg_function_with_timeout one two three"
# or:
# export -f eg_func
# timeout 10s bash -c eg_func 
call_eg_function_with_timeout() {
	local github_repo_name="$1"
	local github_branch_name="$2"
	local gitlab_commit_sha="$3"

	# Remove build status output file if it exists.
	delete_file_if_it_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH
	# assert status file is deleted
	manual_assert_file_does_not_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH

	# Call function that runs and awaits GitLab CI with a time limit.
	export TMP_GITLAB_BUILD_STATUS_FILEPATH=$TMP_GITLAB_BUILD_STATUS_FILEPATH
	timeout 1200s bash -c "source src/import.sh && manage_get_gitlab_ci_build_status $github_repo_name $github_branch_name $gitlab_commit_sha"

	# Read if the output file eixsts
	if [ "$(file_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH)" == "FOUND" ]; then
		
		# yes: read status into variable
		local read_status=$(cat $TMP_GITLAB_BUILD_STATUS_FILEPATH)
		delete_file_if_it_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH
	else
		echo "ERROR, the $TMP_GITLAB_BUILD_STATUS_FILEPATH file is neither found nor not found."
		exit 4
	fi
	
	# Assert status file is deleted.
	manual_assert_file_does_not_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH

	read -p "AFTER EXPORTING AND IMPORTING, IN call_eg_function_with_timeout read_status=$read_status"
	echo "$read_status"
}