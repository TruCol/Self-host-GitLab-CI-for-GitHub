#!/bin/bash
# Ensures a valid SSH deploy key is added to GitHub. 
# TODO: first check if there already is a valid SSH deploy key in GitHub.
# If yes, then don't do anything.
# TODO: verify afterwards that the GitHub SSH deploy key is valid.

# Run with: 
# bash -c "source src/import.sh && ensure_github_ssh_deploy_key_can_be_used_to_push_github_build_status a-t-0"
ensure_github_ssh_deploy_key_can_be_used_to_push_github_build_status() {
	local github_username="$1"
	local github_pwd="$2"

	# Assumes the GitLab build status repository exists in GitHub.
	# Verify if the GitLab build status repository exists in GitHub.	
	assert_public_github_repository_exists "$github_username" "$GITHUB_STATUS_WEBSITE_GLOBAL"

	# Get the GitHub ssh deploy key to push and pull the GitLab build status 
	# icons to the GitHub build status repository.
	printf "\n\n\n Ensuring a ssh deploy key is to GitHub to push build status icons to your build status repository.\n\n\n."
	get_github_build_status_repo_ssh_deploy_key "example@example.com" "$GITHUB_SSH_DEPLOY_KEY_NAME" "$github_username" "$github_pwd"
	printf "\n\n\n Verifying the GitHub ssh deploy token is able to push build status icons to your build status repository.\n\n\n."
	verify_machine_has_push_access_to_gitlab_build_status_repo_in_github "$GITHUB_SSH_DEPLOY_KEY_NAME"
}

# source src/import.sh && get_github_build_status_repo_ssh_deploy_key "example@example.com" some_github_deploy_key a-t-0 somepwd
# bash -c "source src/import.sh && get_github_build_status_repo_ssh_deploy_key example@example.com some_github_deploy_key a-t-0 somepwd"
get_github_build_status_repo_ssh_deploy_key() {
	local email="$1"
	local identifier="$2"
	local github_username="$3"
	local github_pwd="$4"

	local public_key_filename="$identifier.pub"
	local private_key_filename="$identifier"
	
	

	# Generate ssh-key and add it to ssh-agent
	generate_ssh_key_if_not_exists "$email" "$identifier"
	# Assert the ssh-keys exist.
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
	activate_ssh_agent_and_add_ssh_key_to_ssh_agent "$identifier"
	public_ssh_key_data=$(cat "$DEFAULT_SSH_LOCATION/$public_key_filename")

	# Delete GitHub Build status token
	# TODO: delete, no token is created, using ssh deploy key instead.
	delete_file_if_it_exists "$GITHUB_BUILD_STATUS_REPO_DEPLOY_TOKEN_FILEPATH"
	manual_assert_file_does_not_exists "$GITHUB_BUILD_STATUS_REPO_DEPLOY_TOKEN_FILEPATH"
	

	# Get the repository that can automatically get the GitHub deploy token.
	download_repository "a-t-0" "$REPONAME_GET_RUNNER_TOKEN_PYTHON"
	manual_assert_dir_exists "$REPONAME_GET_RUNNER_TOKEN_PYTHON"

	# TODO: verify path before running command.

	printf "\n\n Now using a browser controller repository to add the generated ssh deploy key to GitHub.\n\n."
	# shellcheck disable=SC2034
	if [ "$(conda_env_exists $CONDA_ENVIRONMENT_NAME)" == "FOUND" ]; then
		eval "$(conda shell.bash hook)"
		export github_username=$github_username
		export github_pwd=$github_pwd
		cd get-gitlab-runner-registration-token && conda deactivate && conda activate get_gitlab_generation_token && python -m code.project1.src --d --ssh "$public_ssh_key_data" -hu $github_username -hp $github_pwd
	else
		eval "$(conda shell.bash hook)"
		export github_username=$github_username
		export github_pwd=$github_pwd
		cd get-gitlab-runner-registration-token && conda env create --file environment.yml && conda activate get_gitlab_generation_token && python -m code.project1.src --d --ssh "$public_ssh_key_data" -hu $github_username -hp $github_pwd
		
	fi
	cd ..

	# TODO: Verify path BEFORE and after running command.
}
