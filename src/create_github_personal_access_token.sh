#!/bin/bash

#######################################
# Gets a new GitHub personal access token to set the build statuses of new 
# commits.
# Local variables:
#  github_username
#  github_repo_name
# Globals:
#  None.
# Arguments:
#  github_username
#  github_repo_name
# Returns:
#  0 if the GitHub repository is found.
#  5 if the GitHub repository is private or if it does not exist.
# Outputs:
#  None.
# TODO(a-t-0): Write test for function.
# TODO(a-t-0): delete, no token is created, using ssh deploy key instead.
#######################################
# run with:

# source src/import.sh && get_github_personal_access_token a-t-0
# bash -c "source src/import.sh && get_github_personal_access_token a-t-0"
get_github_personal_access_token() {
	local github_username="$1"
	local github_pwd="$2"
	
	# Get the repository that can automatically get the GitHub deploy token.
	download_repository "$github_username" "$REPONAME_GET_RUNNER_TOKEN_PYTHON"
	manual_assert_dir_exists "$REPONAME_GET_RUNNER_TOKEN_PYTHON"

	# TODO: verify path before running command.

	printf "\n\n Now using a browser controller repository to create a GitHub personal access token and store it locally.\n\n."
	# shellcheck disable=SC2034
	if [ "$(conda_env_exists $CONDA_ENVIRONMENT_NAME)" == "FOUND" ]; then
		eval "$(conda shell.bash hook)"
		export repo_name=$REPONAME_GET_RUNNER_TOKEN_PYTHON
		export github_username=$github_username
		export github_pwd=$github_pwd
		# TODO: include GITHUB_USERNAME_GLOBAL
		#cd get-gitlab-runner-registration-token && conda deactivate && conda activate get_gitlab_generation_token && python -m code.project1.src --hubcpat
		cd $repo_name && conda deactivate && conda activate get_gitlab_generation_token && python -m code.project1.src --hubcpat -hu $github_username -hp $github_pwd
	else
		eval "$(conda shell.bash hook)"
		export repo_name=$REPONAME_GET_RUNNER_TOKEN_PYTHON
		export github_username=$github_username
		export github_pwd=$github_pwd
		# TODO: GITHUB_USERNAME_GLOBAL
		#cd get-gitlab-runner-registration-token && conda env create --file environment.yml && conda activate get_gitlab_generation_token && python -m code.project1.src --hubcpat
		cd $repo_name && conda env create --file environment.yml && conda activate get_gitlab_generation_token && python -m code.project1.src --hubcpat -hu $github_username -hp $github_pwd
	fi
	cd ..

	# TODO: Verify path BEFORE and after running command.
	# TODO: Verify the token is in the PERSONAL_CREDENTIALS_PATH file.
}

#######################################
# Verifies the repository is able to set the build status of GitHub commits in 
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
#  
# TODO(a-t-0): Write tests for this method.
# TODO(a-t-0): verify incoming commit build status is valid.
# TODO(a-t-0): verify incoming redirect url is valid.
#######################################
# Run with:
# bash -c 'source src/import.sh && assert_set_build_status_of_github_commit_using_github_pat a-t-0 sponsor_example 02c5fce3500d7b9e2d79cb5b7d886020a403cf58 http://127.0.0.1  pending'
assert_set_build_status_of_github_commit_using_github_pat() {
	github_username="$1"
	github_repo_name="$2"
	github_commit_sha="$3"
	redirect_to_ci_url="$4"
	commit_build_status="$5"

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
	JSON_FMT='{"state":"%s","description":"%s","target_url":"%s"}\n'
	# shellcheck disable=SC2059
	json_string=$(printf "$JSON_FMT" "$commit_build_status" "$commit_build_status" "$redirect_to_ci_url")
	echo "json_string=$json_string"
	
	# Set the build status
	setting_output=$(curl -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" --request POST --data "$json_string" https://api.github.com/repos/"$github_username"/"$github_repo_name"/statuses/"$github_commit_sha")
	
	# Check if output is valid
	#echo "setting_output=$setting_output"
	if [ "$(lines_contain_string '"message": "Bad credentials"' "${setting_output}")" == "FOUND" ]; then
		# Remove the current GitHub personal access token from the $PERSONAL_CREDENTIALS_PATH file.
		remove_line_from_file_if_contains_substring "$PERSONAL_CREDENTIALS_PATH" "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL"

		## Assert $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL is not in personal_creds
		if [ "$(file_contains_string "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH")" == "FOUND" ]; then
			echo "Error, the GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL is still in the PERSONAL_CREDENTIALS_PATH file."
		fi

		# TODO: specify which checkboxes in the `repository` checkbox are required.
		echo "ERROR, the github personal access token is not valid. Please make a new one (or try again, it has been deleted from $PERSONAL_CREDENTIALS_PATH). See https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token and ensure you tick. $setting_output"
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
		# shellcheck disable=SC2059
		printf "Error, the status of the repo did not contain:$expected_url \n because the getting output was: $getting_output"
		exit 119
	elif [ "$(lines_contain_string "$expected_state" "${getting_output}")" == "NOTFOUND" ]; then
		echo "Error, the status of the repo did not contain:$expected_state"
		exit 120
	fi
}