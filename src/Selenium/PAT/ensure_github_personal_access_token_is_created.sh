#!/bin/bash



#######################################
# Gets a new GitHub personal access token (PAT), using the Python repository:
# get-gitlab-runner-registration-token. This repository is downloaded.
# Next, the conda environment of this repository is created if it does not
# exist, and then the environment is activated. Once activated, the Python
# code is activated, and it downloads a Firefox browser controller for 
# Selenium. This then logs into GitHub and removes the pre-existing GitHub
# PATs if they exist, then creates a new GitHub PAT, and adds it to GitHub.
# The Python module does not verify whether the GitHub PAT works.
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
# bash -c 'source src/import.sh && ensure_github_pat_is_added_to_github "a-t-0"  "somepwd"'
ensure_github_pat_is_added_to_github() {
	local github_username="$1"
	local github_pwd="$2"
	
	local can_use_github_pat=$(has_working_github_pat "$github_username")
	if [ "$can_use_github_pat" == "NOTFOUND" ]; then

		# TODO: support not passing github pwd such that the Python code asks it
		# during runtime.
		if [ "$github_pwd" == "" ]; then
			echo "Error, GitHub password was not specified. Please include it in this function."
			exit 4
		fi

		# Get the repository that can automatically get the GitHub deploy token.
		download_repository "$github_username" "$REPONAME_GET_RUNNER_TOKEN_PYTHON"
		manual_assert_dir_exists "$REPONAME_GET_RUNNER_TOKEN_PYTHON"

		# TODO: verify path before running command.

		printf "\n\n Now using a browser controller repository to create a GitHub personal access token and store it localy.\n\n."
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

		# Overwrite GitHub password export to filler.
		export github_pwd="filler"
		# TODO: Verify path BEFORE and after running command.
		# TODO: Verify the token is in the PERSONAL_CREDENTIALS_PATH file.
	elif [ "$can_use_github_pat" != "FOUND" ]; then
		echo "Error, the has_working_github_pat output was neither FOUND nor"
		echo "NOTFOUND:$can_use_github_pat"
		exit 5
	fi

	local can_use_github_pat=$(has_working_github_pat "$github_username")
	local alternative_can_use_github_pat=$(alternative_check_can_use_github_pat_to_set_commit_status "$github_username" "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	if [ "$can_use_github_pat" != "FOUND" ]; then
		echo "Error, was not able to use the GitHub personal access token (I):"
		echo "$can_use_github_pat"
		if [ "$alternative_can_use_github_pat" != "SET COMMIT STATUS USING GITHUB PAT" ]; then
			echo "Error, was not able to use the GitHub personal access token (II):"
			echo "$alternative_can_use_github_pat"
		fi
	fi
}


