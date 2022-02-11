#!/bin/bash

#######################################
# Creates/generates a private ssh-key if it does not exist already. If one of 2
# expected keys is found, the found key is deleted and a new keypair is 
# created.
# man ssh-keygen says: -t is followed by the type of key/encryption method.
# man ssh-keygen says: -C is followed by a comment.
# man ssh-keygen says: -P is followed the passphrase to encrypt the key.  
#
# Locals:
#  email
#  identifier
# Globals:
#  DEFAULT_SSH_LOCATION
# Arguments:
#  The email address that is added to the ssh-key as comment.
#  The filenames of the ssh-key pair that is created (without extension).
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  PARTIALFOUND if one of the 2 expected keyfiles were found at function start.
#  FOUND if both private and public keyfiles were found at start of function.
#  NOTFOUND if neither keyfiles were found at start of function.
# TODO (a-t-0): check if ouput keyfile exists.
# TODO (a-t-0): check if email is correctly formatted.
# TODO (a-t-0): verify whether the comment has to be the GitHub user email address.	
#######################################
# Run with: source src/import.sh && generate_ssh_key_if_not_exists "example@example.com" "id_github_deploy_key"
generate_ssh_key_if_not_exists() {
	local email="$1"
	local identifier="$2"

	
	local public_key_filename="$identifier.pub"
	local private_key_filename="$identifier"

	# TODO: check if ouput keyfile exists.
	# TODO: check if email is correctly formatted.
	# TODO: verify whether the comment has to be the GitHub user email address.	

	# TODO: assert key is created
	if [ "$(file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename")" == "FOUND" ]; then
		if [ "$(file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename")" == "FOUND" ]; then
			echo "FOUND"
		else
			# Delete the file if only 1/2 keys is found and recreate them.
			delete_file_if_it_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
			
			# Indicate only half of expected keys were found.
			echo "PARTIALFOUND"

			# Recreate ssh-key pair
			ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/"$identifier" -P ""
		fi
	else
		if [ "$(file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename")" == "FOUND" ]; then
			
			# Delete the file if only 1/2 keys is found and recreate them.
			delete_file_if_it_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
			
			# Indicate only half of expected keys were found.
			echo "PARTIALFOUND"
			# Recreate ssh-key pair
			ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/"$identifier" -P ""
		else
			echo "NOTFOUND"
			# Create ssh-key pair
			ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/"$identifier" -P ""
		fi
	fi
}


#######################################
# Activates an ssh-account such that its "key" is shared when reaching out to
# the Git(Hub/Lab) server, when one pushes. More technically correct is:
#
# Source: https://superuser.com/a/1356941/809273 The eval $(ssh-agent -s)
# starts the ssh-agent=a program, and configures the environment for the 
# shell in which the "eval.." command is executed, to point to the ssh-agent.
# This means that if a command that is executed in that same shell, expects
# /requires some private ssh-key, that the command automatically asks the 
# ssh-agent that you just started for that key.
#
# Source: https://superuser.com/a/360706/809273 The ssh-add ~/.ssh/something 
# command adds the private key (?identities?) (from the ~/.ssh/ directory)
# to the ssh-agent that was started within its particular shell with the 
# "eval .." command.

# One may ask, why don't all programs just look into ~/.ssh/something for all
# the private ssh-keys by default? That is because some ssh keys are encrypted
# with a password, which would mean the user would have to type that password
# everytime at arbitrary commands. Instead, you can decrypt the private key
# with the password, give it to the ssh-agent, (I assume this ssh-agent then
# encrypts it again with some system/random password). You can tell the agent 
# to keep that decrypted key only for a limited amount of seconds according to
# the manual pages: (man ssh-agent) using: ssh-agent -t 500 (for 500 seconds).
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
# TODO(a-t-0): Rename to add_ssh_key_to_ssh_agent()
#######################################
activate_ssh_agent_and_add_ssh_key_to_ssh_agent() {
	local git_username="$1"

	# Activate the ssh-agent in this shell.
	eval "$(ssh-agent -s 3>&-)"

	# Add the private ssh-key with name git_username to the ssh-agent that was
	# activated in this shell
    ssh-add ~/.ssh/"$git_username"
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:ssh
# Untested function to retrieve email pertaining to ssh key
get_ssh_email() {
	local ssh_account=$1
	
	local username
	username=$(whoami)
	local key_filepath="/home/$username/.ssh/$ssh_account.pub"
	
	# Check if file exists.
	manual_assert_file_exists "$key_filepath"
	
	# Read the ssh pub file.
	local public_ssh_content
	public_ssh_content=$(cat "$key_filepath")
	
	# Get email from ssh pub file.
	local email
	email=$(get_last_space_delimted_item_in_line "$public_ssh_content")
	echo "$email"
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:ssh
# Checks for both GitHub username as well as for the email address that is 
# tied to that acount.
any_ssh_key_is_added_to_ssh_agent() {
	local ssh_account=$1
	local ssh_output
	ssh_output=$(ssh-add -L)
	
	# Check if the ssh key is added to ssh-agent by means of username.
	found_ssh_username="$(github_account_ssh_key_is_added_to_ssh_agent "$ssh_account" "\"${ssh_output}")"
	if [[ "$found_ssh_username" == "FOUND" ]]; then
		echo "FOUND"
	else
		
		# Get the email address tied to the ssh-account.
		ssh_email=$(get_ssh_email "$ssh_account")
		#echo "ssh_email=$ssh_email"
		
		if [ "$ssh_email" == "" ]; then
			#echo "The ssh key file does not exist, so the email address of that ssh-account can not be extracted."
			echo "NOTFOUND_FILE"
			exit 27
		else 
			
			# Check if the ssh key is added to ssh-agent by means of email.
			found_ssh_email="$(github_account_ssh_key_is_added_to_ssh_agent "$ssh_email" "\"${ssh_output}")"
			
			if [ "$found_ssh_email" == "FOUND" ]; then
				echo "FOUND"
			else
				#manual_assert_equal  "$found_ssh_email" "FOUND"
				echo "NOTFOUND_EMAIL"
			fi
		fi
	fi
}


#######################################
# Checks if the ssh-key is added to the ssh-agent.
# This is a requirement for ssh to work, even for deployment key.
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  FOUND if the incoming ssh account is activated,
#  NOTFOUND otherwise.
#######################################
github_account_ssh_key_is_added_to_ssh_agent() {
	local ssh_account="$1"
	local activated_ssh_output=("$@")
	local found="false"
	
	
	local count=0
	while IFS= read -r line; do
		count=$((count+1))
		
		# Get the username from the ssh key .pub file.
		local username
		username="$(get_last_space_delimted_item_in_line "$line")"
		
		if [ "$username" == "$ssh_account" ]; then
			if [ "$found" == "false" ]; then
				echo "FOUND"
				found="true"
			fi
		fi

	done <<< "${activated_ssh_output[@]}"
	if [ "$found" == "false" ]; then
		echo "NOTFOUND"
	fi
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:ssh
assert_ssh_key_is_added_to_ssh_agent() {
	local ssh_account=$1
	local ssh_output
	ssh_output=$(ssh-add -L)
	local ssh_key_in_ssh_agent
	ssh_key_in_ssh_agent=$(any_ssh_key_is_added_to_ssh_agent "$ssh_account")
	if [[ "$ssh_key_in_ssh_agent" == "NOTFOUND_FILE" ]] || [[ "$ssh_key_in_ssh_agent" == "NOTFOUND_EMAIL" ]]; then
		printf 'Please ensure the ssh-account '%ssh_account' key is added to the ssh agent. You can do that with commands:'"\\n"" eval $(ssh-agent -s)""\n"'ssh-add ~/.ssh/'$ssh_account''"\n"' Please run this script again once you are done.'
		exit 28
	fi
}


#######################################
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
# TODO(a-t-0): Remove this function and replace its usage with:
# check_ssh_access_to_repo or assert_ssh_access_to_repo.
#######################################
has_access() {
	local github_repo="$1"
	#echo $(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo")
	check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo"
}


#######################################
# Checks if the device has ssh-access to some repository. If retry argument is
# passed, it will call itself once more.
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
#  0 If function was evaluated succesfull.
# Outputs:
#  FOUND if the machine has ssh-access to a repository.
#  NOTFOUND if the machine does not have ssh-access to a repository.
#######################################
check_ssh_access_to_repo() {
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
			echo "NOTFOUND"
		else
			# Perform recursive call to run function one more time.
			check_ssh_access_to_repo "$local_git_username" "$github_repository" "YES"
		fi
	fi
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
			check_ssh_access_to_repo "$local_git_username" "$github_repository" "YES"
		fi
	fi
}



#######################################
# Gets a new deploy key for the GitHub build status repository.
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
#######################################
# run with:
# source src/import.sh && get_github_build_status_repo_deploy_key
get_github_build_status_repo_deploy_key() {
	delete_file_if_it_exists "$GITHUB_BUILD_STATUS_REPO_DEPLOY_TOKEN_FILEPATH"
	manual_assert_file_does_not_exists "$GITHUB_BUILD_STATUS_REPO_DEPLOY_TOKEN_FILEPATH"
	
	# Get the repository that can automatically get the GitHub deploy token.
	download_repository "a-t-0" "$REPONAME_GET_RUNNER_TOKEN_PYTHON"

	# TODO: Verify repository is downloaded.

	# TODO: verify path before running command.

	# TODO: turn get_gitlab_generation_token into variable
	# shellcheck disable=SC2034
	if [ "$(conda_env_exists $CONDA_ENVIRONMENT_NAME)" == "FOUND" ]; then
		eval "$(conda shell.bash hook)"
		# TODO: allow passing and parsing arguments in src/get_gitlab_server_runner_token.sh
		cd get-gitlab-runner-registration-token && conda deactivate && conda activate get_gitlab_generation_token && python -m code.project1.src
	else
		eval "$(conda shell.bash hook)"
		cd get-gitlab-runner-registration-token && conda env create --file environment.yml && conda activate get_gitlab_generation_token && python -m code.project1.src
		
	fi
	cd ..

	# TODO: Verify path after running command.
}