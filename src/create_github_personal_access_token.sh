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
# bash -c "source src/import.sh && get_github_personal_access_token a-t-0
get_github_personal_access_token() {
	local github_username="$1"
	
	# Get the repository that can automatically get the GitHub deploy token.
	download_repository "a-t-0" "$REPONAME_GET_RUNNER_TOKEN_PYTHON"
	manual_assert_dir_exists "$REPONAME_GET_RUNNER_TOKEN_PYTHON"

	# TODO: verify path before running command.

	# TODO: turn get_gitlab_generation_token into variable
	# shellcheck disable=SC2034
	if [ "$(conda_env_exists $CONDA_ENVIRONMENT_NAME)" == "FOUND" ]; then
		eval "$(conda shell.bash hook)"
		cd get-gitlab-runner-registration-token && conda deactivate && conda activate get_gitlab_generation_token && python -m code.project1.src --github-pac
	else
		eval "$(conda shell.bash hook)"
		cd get-gitlab-runner-registration-token && conda env create --file environment.yml && conda activate get_gitlab_generation_token && python -m code.project1.src --github-pac
	fi
	cd ..

	# TODO: Verify path BEFORE and after running command.
}