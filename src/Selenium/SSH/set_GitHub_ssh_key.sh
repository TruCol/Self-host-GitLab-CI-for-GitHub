#!/bin/bash
# This file adds the GitHub SSH deploy key to GitHub.

#######################################
# Adds the local SSH key, that is created for the GitHub deploy of the GitHub
# build status repository, to GitHub.
#
# Assumes:
# 0. That a local SSH deploy key is created and added to the local SSH agent.
# 
# Local variables:
#  github_username
#  github_pwd
# Globals:
#  GITHUB_SSH_DEPLOY_KEY_NAME
#  DEFAULT_SSH_LOCATION
#  REPONAME_GET_RUNNER_TOKEN_PYTHON
#  CONDA_ENVIRONMENT_NAME
# Arguments:
#  github_username
#  github_pwd
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0): Write tests for this method.
#######################################
# bash -c "source src/import.sh && add_ssh_deploy_key_to_github example@example.com "a-t-0" somepwd"
add_ssh_deploy_key_to_github() {
	local github_username="$1"
	local github_pwd="$2"

    # 0. Load the public ssh key data from public SSH key file.
    local public_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME.pub"
    manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	public_ssh_key_data=$(cat "$DEFAULT_SSH_LOCATION/$public_key_filename")
	
	# 1. Get the repository that can automatically add the GitHub SSH deploy key
    # to GitHub.
	download_repository "a-t-0" "$REPONAME_GET_RUNNER_TOKEN_PYTHON"
	manual_assert_dir_exists "$REPONAME_GET_RUNNER_TOKEN_PYTHON"

    # 2. Run the Selenium browser controller to add the GitHub public SSH 
    # deploy key to GitHub.
	# TODO: verify path before running command.
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
    # TODO: verify the GitHub SSH deploy key works.
}


#######################################
# Creates alocal GitHub SSH deploy key, and adds it to the local SSH agent.
# 
# Local variables:
#  email
#  public_key_filename
#  private_key_filename
# Globals:
#  GITHUB_SSH_DEPLOY_KEY_NAME
#  DEFAULT_SSH_LOCATION
# Arguments:
#  email
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0): Write tests for this method.
#######################################
# bash -c 'source src/import.sh && create_and_activate_local_github_ssh_deploy_key'
create_and_activate_local_github_ssh_deploy_key() {
    
    local public_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME.pub"
	local private_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME"

	# Generate ssh-key and add it to ssh-agent
	read -p "Setting"
	generate_ssh_key_if_not_exists "$GITHUB_SSH_EMAIL"
	read -p "Done"
	
    # Assert the ssh-keys exist.
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
	activate_ssh_agent_and_add_ssh_key_to_ssh_agent
}