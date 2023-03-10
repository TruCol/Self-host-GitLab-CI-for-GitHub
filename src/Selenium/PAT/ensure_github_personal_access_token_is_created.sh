#!/bin/bash



#######################################
# Gets a new GitHub personal access token (PAT), using the Python repository:
# gitbrowserinteract. This repository is downloaded.
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
	
	# Verify personal credentials can be loaded from file.
	if [[ "$PERSONAL_CREDENTIALS_PATH" == "" ]]; then 
		echo "Error, cannot find personal credentials path."
		exit 5
	fi

	source $PERSONAL_CREDENTIALS_PATH
	# Check if GitHub PAT is in personal access tokens.
	if [[ "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]]; then
		# If not, put it in there.
		set_github_pat "$github_username" "$github_pwd"
		
		# Then assert it is in there.
		source $PERSONAL_CREDENTIALS_PATH
		if [[ "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]]; then
			echo "Error, after adding the personal access token to GitHub, it"
			echo "was not found in $PERSONAL_CREDENTIALS_PATH:"
			exit 5
		fi
	fi

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


set_github_pat() {
	local github_username="$1"
	local github_pwd="$2"

	# TODO: support not passing github pwd such that the Python code asks it
	# during runtime.
	if [ "$github_pwd" == "" ]; then
		echo "Error, GitHub password was not specified. Please include it in this function."
		exit 4
	fi

	export repo_name=$REPONAME_GET_RUNNER_TOKEN_PYTHON
	export github_username=$github_username
	export github_pwd=$github_pwd

	# TODO: verify path before running command.
	printf "\n\n Now using a browser controller repository to create a GitHub personal access token and store it localy.\n\n."

	pip install gitbrowserinteract --yes
	# TODO: assert the pip package is installed succesfully.
	
	python -m gitbrowserinteract.__main__ --hubcpat -hu $github_username -hp $github_pwd

	# Overwrite GitHub password export to filler.
	export github_pwd="filler"
	
	# TODO: Verify the token is in the PERSONAL_CREDENTIALS_PATH file.

}