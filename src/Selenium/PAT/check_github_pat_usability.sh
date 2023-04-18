#!/bin/bash
# Performs checks and verifications on the GitHub PAT usability.


#######################################
# Ensures the GitHub personal access token can be used to set the commit status
# on a GitHub commit. Does this by getting the latest commit (sha) on the
# GitHub test repository and setting the status to "pending" and "success"
# and probing the build status of that commit of that repository accordingly.
# Locals:
#  github_username
#  PUBLIC_GITHUB_TEST_REPO_GLOBAL
#  latest_commit_on_default_branch
#  personal_credits_contain_global
#  set_pending
#  set_succes
# Globals:
#  PERSONAL_CREDENTIALS_PATH
#  PUBLIC_GITHUB_TEST_REPO_GLOBAL
# Arguments:
#  github_username
#  PUBLIC_GITHUB_TEST_REPO_GLOBAL
# Returns:
#  0 If the GitHub commit build statusses can be set correctly.
#  4 If the GitHub commit sha has a length other than the expected 40.
# Outputs:
#  A lot of text on how the function was evaluated.
#######################################
# Run with: 
# bash -c "source src/import.sh && alternative_check_can_use_github_pat_to_set_commit_status a-t-0 sponsor_example"
alternative_check_can_use_github_pat_to_set_commit_status() {
	local github_username="$1"

	# Credentials are used to push to GitHub, so check if the file with
	# (GitHub) credentials exists.
	ensure_file_exists "$PERSONAL_CREDENTIALS_PATH"
	
	# Verify the GitHub personal access token is stored in the credentials 
	# file.
	local personal_credits_contain_global=$(file_contains_string "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH")
	if [ "$personal_credits_contain_global" == "FOUND" ]; then
		
		# Get the commit sha of the latest commit on the default branch.
		local latest_commit_on_default_branch="$(get_latest_commit_public_github_repo "$github_username" "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")"

		# Set the build status of a GitHub commit to "pending". GitLab server
		# url is used because clicking on the build status should refer back to
		# the build status report on GitLab.
		local set_pending=$(check_if_can_set_build_status_of_github_commit_using_github_pat $github_username $PUBLIC_GITHUB_TEST_REPO_GLOBAL $latest_commit_on_default_branch $GITLAB_SERVER_HTTPS_URL "pending")

		# Verify build status of the GitHub commit is changed successfully.
		if [ "$set_pending" == "TRUE" ]; then
			
			# Set the build status of a GitHub commit to "success".
			local set_succes=$(check_if_can_set_build_status_of_github_commit_using_github_pat $github_username $PUBLIC_GITHUB_TEST_REPO_GLOBAL $latest_commit_on_default_branch $GITLAB_SERVER_HTTPS_URL "success")			
			
			if [ "$set_succes" != "TRUE" ]; then
				echo "Error, the GitHub commit status was not succesfully set to:success"
				exit 22
			else
				echo "SET COMMIT STATUS USING GITHUB PAT"
			fi
		else
			echo "Error, the GitHub commit status was not succesfully set to:pending"
			exit 23
		fi
	else
		echo "Error, did not find GitHub pat in personal_creds."
		exit 24
	fi
}



#######################################
# Checks if the repository is able to set the build status of GitHub commits in 
# the GitHub user/organisation.
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
#  TRUE if the build status was set succesfully.
#  FALSE if the build status was not set succesfully.
# TODO(a-t-0): Write tests for this method.
# TODO(a-t-0): verify incoming commit build status is valid.
# TODO(a-t-0): verify incoming redirect url is valid.
#######################################
# Run with:
# bash -c 'source src/import.sh && check_if_can_set_build_status_of_github_commit_using_github_pat a-t-0 sponsor_example 02c5fce3500d7b9e2d79cb5b7d886020a403cf58 https://127.0.0.1  pending'
check_if_can_set_build_status_of_github_commit_using_github_pat() {
	local github_username="$1"
	local github_repo_name="$2"
	local github_commit_sha="$3"
	local redirect_to_ci_url="$4"
	local commit_build_status="$5"
	
	# Check if arguments are valid.
	if [[ "$github_commit_sha" == "" ]]; then
		echo "ERROR, the github commit sha is empty, whereas it shouldn't be."
		exit 113
	elif [[ "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]]; then
		echo "ERROR, the github personal access token is empty, whereas it shouldn't be."
		exit 114
	elif [[ "$commit_build_status" == "" ]]; then
		echo "ERROR, the GitLab build status is empty, whereas it shouldn't be."
		exit 115
	elif [[ "$redirect_to_ci_url" == "" ]]; then
		echo "ERROR, the GitLab server website url is empty, whereas it shouldn't be."
		exit 116
	fi

	# TODO: verify incoming commit build status is valid.
	# TODO: verify incoming redirect url is valid.

	
	#echo "redirect_to_ci_url=$redirect_to_ci_url"
	#echo "commit_build_status=$commit_build_status"
	
	# Create message in JSON format
	json_fmt='{"state":"%s","description":"%s","target_url":"%s"}\n'
	# shellcheck disable=SC2059
	local json_string=$(printf "$json_fmt" "$commit_build_status" "$commit_build_status" "$redirect_to_ci_url")
	#echo "json_string=$json_string"
	
	# Set the build status
	local setting_output=$(curl -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" --request POST --data "$json_string" https://api.github.com/repos/"$github_username"/"$github_repo_name"/statuses/"$github_commit_sha")
	
	# Check if output is valid
	#echo "setting_output=$setting_output"
	if [ "$(lines_contain_string '"message": "Bad credentials"' "${setting_output}")" == "FOUND" ]; then
		# TODO: specify which checkboxes in the `repository` checkbox are required.
		echo "ERROR, the github personal access token is not valid. Please make a new one. See https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token and ensure you tick. $setting_output"
		exit 117
	elif [ "$(lines_contain_string '"documentation_url": "https://docs.github.com/rest' "${setting_output}")" == "FOUND" ]; then
		echo "ERROR: $setting_output"
		exit 118
	fi
	
	# Verify the build status is set correctly
	getting_output=$(GET https://api.github.com/repos/"$github_username"/"$github_repo_name"/commits/"$github_commit_sha"/statuses)
	expected_url="\"url\":\"https://api.github.com/repos/$github_username/$github_repo_name/statuses/$github_commit_sha\","
	expected_state="\"state\":\"$commit_build_status\","
	if [ "$(lines_contain_string "$expected_url" "${getting_output}")" == "NOTFOUND" ]; then
		echo "FALSE"
	elif [ "$(lines_contain_string "$expected_state" "${getting_output}")" == "NOTFOUND" ]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi
}