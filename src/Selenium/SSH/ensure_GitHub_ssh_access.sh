#!/bin/bash
# Ensures a valid SSH deploy key is added to GitHub. 

#######################################
# Ensures this machine has pull and push access to the GitLab build status
# repository in GitLab. First performs a check whether it already has such
# access, and if not, creates that access.
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
#######################################
# bash -c 'source src/import.sh && ensure_github_ssh_deploy_key_has_access_to_build_status_repo "a-t-0" "gitlab-ci-build-statuses"'
ensure_github_ssh_deploy_key_has_access_to_build_status_repo(){
	local github_username="$1"
	local github_repository=$2

	local ensured_quick_ssh_access_to_github="$(ensure_check_quick_ssh_access_to_repo "$github_username" "$github_repository")"
	if [[ "$ensured_quick_ssh_access_to_github" == "ENSURED_QUICK_SSH_ACCESS" ]]; then
		local ensured_pull_ssh_access_to_github="$(ensure_has_pull_access_to_gitlab_build_status_repo_in_github "$github_username")"
		if [[ "$ensured_pull_ssh_access_to_github" == "ENSURED_SSH_PULL_ACCESS" ]]; then
			local ensured_push_ssh_access_to_github="$(ensure_has_push_access_to_gitlab_build_status_repo_in_github)"
			if [[ "$ensured_push_ssh_access_to_github" == "ENSURED_SSH_PUSH_ACCESS" ]]; then
				echo "Got SSH push and pull access to GitHub build status repo."
			else
				echo "Error, was not able to achieve push ssh access:$ensured_push_ssh_access_to_github"
				exit 9
			fi
		else
			echo "Error, was not able to achieve pull ssh access:$ensured_pull_ssh_access_to_github"
			exit 7
		fi
	else
		echo "Error, was not able to achieve quick_ssh_access:$ensured_quick_ssh_access_to_github"
		exit 5
	fi
}


#######################################
# Ensures this machine has quick access to the GitHub build status repo through
# ssh. 

# If quick access to the GitHub build status repo is not obtained at first
# try, it does the work that should realise quick access to the GitHub build
# status repo, and then calls the function again. In the second, recursive 
# call, the "is_retry" argument is included. In this second try, if it fails,
# the function throws an error, otherwise it echo's "FOUND". The first call
# then propagates the output of that second function call.
# 
# Local variables:
#  is_retry
# Globals:
#  GITHUB_USERNAME_GLOBAL
#  GITHUB_STATUS_WEBSITE_GLOBAL
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0): Write tests for this method.
#######################################
# bash -c 'source src/import.sh && ensure_check_quick_ssh_access_to_repo "a-t-0" "gitlab-ci-build-statuses"'
ensure_check_quick_ssh_access_to_repo(){
	local github_username=$1
	local github_repository=$2
	local is_retry="$3"
	
	# Check if the code has SSH access to the GitHub build status repository.
	has_quick_ssh_access_to_github="$(check_quick_ssh_access_to_repo "$github_username" "$github_repository")"
	
	if [[ "$has_quick_ssh_access_to_github" != "HAS_QUICK_SSH_ACCESS" ]]; then

		if [ "$is_retry" == "YES" ]; then
			echo "Error, was not able to achieve quick_ssh_access."
			exit 4
		else
			# TODO: Ensure quick_ssh_access is obtained.

			
			# Perform recursive call to run function one more time.
			echo $(ensure_check_quick_ssh_access_to_repo "$github_username" "$github_repository" "YES")
		fi
	else
		echo "ENSURED_QUICK_SSH_ACCESS"
	fi
}


#######################################
# Ensures this machine has pull access to the GitHub build status repo through
# ssh. 
#
# If pull access to the GitHub build status repo is not obtained at first
# try, it does the work that should realise pull access to the GitHub build
# status repo, and then calls the function again. In the second, recursive 
# call, the "is_retry" argument is included. In this second try, if it fails,
# the function throws an error, otherwise it echo's "FOUND". The first call
# then propagates the output of that second function call.
# 
# Local variables:
#  is_retry
# Globals:
#  GITHUB_USERNAME_GLOBAL
#  GITHUB_STATUS_WEBSITE_GLOBAL
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0): Write tests for this method.
#######################################
# bash -c 'source src/import.sh && ensure_has_pull_access_to_gitlab_build_status_repo_in_github "a-t-0"'
ensure_has_pull_access_to_gitlab_build_status_repo_in_github(){
	local github_username="$1"
	local is_retry="$2"
	
	# Check if the code has SSH access to the GitHub build status repository.
	has_pull_ssh_acces_to_github="$(has_pull_access_to_gitlab_build_status_repo_in_github "$github_username")"
	
	if [[ "$has_pull_ssh_acces_to_github" != "HAS_SSH_PULL_ACCESS" ]]; then

		if [ "$is_retry" == "YES" ]; then
			echo "Error, was not able to achieve pull ssh access."
			exit 4
		else
			# TODO: Ensure pull ssh access is obtained.

			
			# Perform recursive call to run function one more time.
			echo $(ensure_has_pull_access_to_gitlab_build_status_repo_in_github "$github_username" "YES")
		fi
	else
		echo "ENSURED_SSH_PULL_ACCESS"
	fi
}


#######################################
# Ensures this machine has push access to the GitHub build status repo through
# ssh. 

# If push access to the GitHub build status repo is not obtained at first
# try, it does the work that should realise push access to the GitHub build
# status repo, and then calls the function again. In the second, recursive 
# call, the "is_retry" argument is included. In this second try, if it fails,
# the function throws an error, otherwise it echo's "FOUND". The first call
# then propagates the output of that second function call.
# 
# Local variables:
#  is_retry
# Globals:
#  GITHUB_USERNAME_GLOBAL
#  GITHUB_STATUS_WEBSITE_GLOBAL
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0): Write tests for this method.
#######################################
# bash -c "source src/import.sh && ensure_has_push_access_to_gitlab_build_status_repo_in_github"
ensure_has_push_access_to_gitlab_build_status_repo_in_github(){
	local is_retry="$1"
	
	# Check if the code has SSH access to the GitHub build status repository.
	has_push_ssh_acces_to_github="$(has_push_access_to_gitlab_build_status_repo_in_github)"
	
	if [[ "$has_push_ssh_acces_to_github" != "HAS_SSH_PUSH_ACCESS" ]]; then

		if [ "$is_retry" == "YES" ]; then
			echo "Error, was not able to achieve push ssh access."
			exit 4
		else
			# TODO: Ensure push ssh access is obtained.

			
			# Perform recursive call to run function one more time.
			echo $(ensure_has_push_access_to_gitlab_build_status_repo_in_github "YES")
		fi
	else
		echo "ENSURED_SSH_PUSH_ACCESS"
	fi
}

# source src/import.sh && get_github_build_status_repo_ssh_deploy_key "example@example.com" some_github_deploy_key a-t-0 somepwd
# bash -c "source src/import.sh && get_github_build_status_repo_ssh_deploy_key example@example.com some_github_deploy_key a-t-0 somepwd"
get_github_build_status_repo_ssh_deploy_key() {
	local email="$1"
	local github_username="$3"
	local github_pwd="$4"

	local public_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME.pub"
	local private_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME"

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




#######################################
# Asserts the device has ssh-access to some repository. If retry argument is
# passed, it will call itself once more. Throws an error upon no ssh-access.
# Local variables:
#  local_git_username
#  github_repository
#  is_retry
#  my_service_status
#  found_error_in_ssh_command
# Globals:
#  None.
# Arguments:
#  local_git_username
#  github_repository
#  is_retry
# Returns:
#  0 if the machine has ssh-access to a repository.
#  4 if the machine does not have ssh-access to a repository.
# Outputs:
#  FOUND if the machine has ssh-access to a repository.
#######################################
assert_ssh_access_to_repo() {
	local local_git_username=$1
	local github_repository=$2
	local is_retry=$3
	
	# shellcheck disable=SC2034
	local my_service_status=$(git ls-remote git@github.com:"$local_git_username"/"$github_repository".git 2>&1)
	local found_error_in_ssh_command=$(lines_contain_string "ERROR" "\${my_service_status}")
	if [ "$found_error_in_ssh_command" == "NOTFOUND" ]; then
		echo "FOUND"
	elif [ "$found_error_in_ssh_command" == "FOUND" ]; then
		# Two tries is enough to determine the device does not have ssh-access.
		if [ "$is_retry" == "YES" ]; then
			echo "Your ssh-account:$local_git_username does not have pull access to the repository:$github_repository"
			#(A public repository should grant ssh access even if no ssh credentials for that GitHub user is given.)
			exit 4
		else
			# Perform recursive call to run function one more time.
			check_quick_ssh_access_to_repo "$local_git_username" "$github_repository" "YES"
		fi
	fi
}