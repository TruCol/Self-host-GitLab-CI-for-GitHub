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
# bash -c 'source src/import.sh && ensure_github_ssh_deploy_key_has_access_to_build_status_repo "a-t-0" "somepwd" "gitlab-ci-build-statuses"'
ensure_github_ssh_deploy_key_has_access_to_build_status_repo(){
	local github_username="$1"
	local github_pwd="$2"
	local github_repository="$3"

	local ensured_quick_ssh_access_to_github="$(ensure_quick_ssh_access_to_repo "$github_username" "$github_repository")"
	if [[ "$ensured_quick_ssh_access_to_github" == "ENSURED_QUICK_SSH_ACCESS" ]]; then
		local ensured_pull_ssh_access_to_github="$(ensure_has_pull_access_to_gitlab_build_status_repo_in_github "$github_username" "$github_pwd")"
		if [[ "$ensured_pull_ssh_access_to_github" == "ENSURED_SSH_PULL_ACCESS" ]]; then
			local ensured_push_ssh_access_to_github="$(ensure_has_push_access_to_gitlab_build_status_repo_in_github "$github_username" "$github_pwd")"
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
# bash -c 'source src/import.sh && ensure_quick_ssh_access_to_repo "a-t-0" "gitlab-ci-build-statuses"'
ensure_quick_ssh_access_to_repo(){
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
			# Ensure quick_ssh_access is obtained.
			# TODO: verify that function actually yields quick access on clean
			# Ubuntu 22.04 image.
			create_and_activate_local_github_ssh_deploy_key
			
			# Perform recursive call to run function one more time.
			echo $(ensure_quick_ssh_access_to_repo "$github_username" "$github_repository" "YES")
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
# bash -c 'source src/import.sh && ensure_has_pull_access_to_gitlab_build_status_repo_in_github "a-t-0" "somepwd"'
ensure_has_pull_access_to_gitlab_build_status_repo_in_github(){
	local github_username="$1"
	local github_pwd="$2"
	local is_retry="$3"
	
	# Check if the code has SSH access to the GitHub build status repository.
	has_pull_ssh_acces_to_github="$(has_pull_access_to_gitlab_build_status_repo_in_github "$github_username")"
	
	if [[ "$has_pull_ssh_acces_to_github" != "HAS_SSH_PULL_ACCESS" ]]; then

		if [ "$is_retry" == "YES" ]; then
			echo "Error, was not able to achieve pull ssh access."
			exit 4
		else
			# Ensure pull ssh access is obtained.
			add_ssh_deploy_key_to_github "$github_username" "$github_pwd"
			
			# Perform recursive call to run function one more time.
			echo $(ensure_has_pull_access_to_gitlab_build_status_repo_in_github "$github_username" "$github_pwd" "YES")
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
# bash -c 'source src/import.sh && ensure_has_push_access_to_gitlab_build_status_repo_in_github "a-t-0" "somepwd"'
ensure_has_push_access_to_gitlab_build_status_repo_in_github(){
	local github_username="$1"
	local github_pwd="$2"
	local is_retry="$3"
	
	# Check if the code has SSH access to the GitHub build status repository.
	has_push_ssh_acces_to_github="$(has_push_access_to_gitlab_build_status_repo_in_github)"
	
	if [[ "$has_push_ssh_acces_to_github" != "HAS_SSH_PUSH_ACCESS" ]]; then

		if [ "$is_retry" == "YES" ]; then
			echo "Error, was not able to achieve push ssh access."
			exit 4
		else
			# Ensure push ssh access is obtained.
			add_ssh_deploy_key_to_github "$github_username" "$github_pwd"
			
			# Perform recursive call to run function one more time.
			echo $(ensure_has_push_access_to_gitlab_build_status_repo_in_github "$github_username" "$github_pwd" "YES")
		fi
	else
		echo "ENSURED_SSH_PUSH_ACCESS"
	fi
}