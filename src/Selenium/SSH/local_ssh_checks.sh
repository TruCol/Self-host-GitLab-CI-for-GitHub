#!/bin/bash
# Performs ssh activities/checks on the local ssh agent.

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
# Run with: source src/import.sh && generate_ssh_key_if_not_exists "example@example.com"
generate_ssh_key_if_not_exists() {
	local email="$1"

	local public_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME.pub"
	local private_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME"

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
			ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/"$GITHUB_SSH_DEPLOY_KEY_NAME" -P ""
		fi
	else
		if [ "$(file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename")" == "FOUND" ]; then
			
			# Delete the file if only 1/2 keys is found and recreate them.
			delete_file_if_it_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
			
			# Indicate only half of expected keys were found.
			echo "PARTIALFOUND"
			# Recreate ssh-key pair
			ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/"$GITHUB_SSH_DEPLOY_KEY_NAME" -P ""
		else
			echo "NOTFOUND"
			# Create ssh-key pair
			yes | ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/"$GITHUB_SSH_DEPLOY_KEY_NAME" -P ""
		fi
	fi

	# Assert the ssh-keys exist.
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
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
# TODO(a-t-0): Write test that expect failure if 1 of 2, or both keys of pair
# is/are missing. Duplicate:
# @test "Check if ssh-key is added to ssh-agent after adding it to ssh-agent." 
# for that.
#######################################
activate_ssh_agent_and_add_ssh_key_to_ssh_agent() {
	
	
	# Assert the ssh-keys exist.
	local public_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME.pub"
	local private_key_filename="$GITHUB_SSH_DEPLOY_KEY_NAME"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"

	# Activate the ssh-agent in this shell.
	eval "$(ssh-agent -s 3>&-)"
	assert_ssh_agent_is_running_in_this_shell

	# Add the private ssh-key with filename GITHUB_SSH_DEPLOY_KEY_NAME to the ssh-agent that was
	# activated in this shell.
    ssh-add ~/.ssh/"$GITHUB_SSH_DEPLOY_KEY_NAME"

	# Verify the ssh-key is added to the ssh-agent.
	public_key_sha=$(get_public_key_sha_from_key_filename $GITHUB_SSH_DEPLOY_KEY_NAME)
	if [ "$(check_if_public_key_sha_is_in_ssh_agent $public_key_sha)" != "FOUND" ]; then
		echo "Error, the ssh-key should added to the ssh-agent (in ssh-add -l), however, they were not found in the ssh-agent."
		exit 10
	fi
}


#######################################
# Returns public sha of public ssh key file if the file exists. Throws error otherwise.
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
# TODO(a-t-0): write tests.
#######################################
# Run with: source src/import.sh && get_public_key_sha_from_key_filename some_test_ssh_key_name
get_public_key_sha_from_key_filename() {
	local identifier="$1"
	local public_key_filename="$identifier.pub"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	
	# Get the output that contains the public key sha belonging to the key pair: $identifier.
	local line_with_public_key_sha="$(cat $DEFAULT_SSH_LOCATION/$public_key_filename)"
	
	# Parse the output to extract the public key sha.
	# The line_with_public_key_sha format is: 
	# <encoding type> <public sha> <email address>
	# so first one can get the rhs after the first space, which results in: 
	# <public sha> <email address>
	# And then taking the lhs after the first space of that new string results in:
	# <public sha>
	rhs_after_first_space=$(get_rhs_of_line_till_character "$line_with_public_key_sha" " ")
	rhs_before_second_space=$(get_lhs_of_line_till_character "$rhs_after_first_space" " ")

	# Output the public key sha that belongs to the identifier
	echo "$rhs_before_second_space"
}


#######################################
# Deletes a key (pair) from the ssh-agent if it is in the ssh-agent.
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
# TODO(a-t-0): Include function to convert identifier into public key sha with:
# Source: https://stackoverflow.com/a/57365766/7437143
# solution: ssh-keygen -y -f /home/jsmith/keys/mytest.pem > /home/jsmith/keys/mytest.pub
# TODO(a-t-0): Write tests for this function. (Re-use: @test "Check if ssh-key 
# is added to ssh-agent after adding it to ssh-agent." {).
#######################################
# Run with: source src/import.sh && check_if_public_key_sha_is_in_ssh_agent 'AAAAC3NzaC1lZDI1NTE5AAAAIMCMWw5DSN7z8O+rZu7WO49pQtLzQeDvN6104bAKjEpb'
check_if_public_key_sha_is_in_ssh_agent() {
	local public_key_sha="$1"
	
	# Get the list of public sha keys in the ssh-agent.
	# This does not care if the ssh-agent is activated or not.
	local output_ssh_key_list=$(ssh-add -L)
	
	# Check if the public sha key is found in the ssh-agent
	found_public_sha=$(lines_contain_string "$public_key_sha" $output_ssh_key_list)
	
	# Check if output_ssh_key_list contains the public_key_sha
	if [ "$found_public_sha" == "FOUND" ]; then
		echo "FOUND"
	else
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
# Run with: source src/import.sh && check_ssh_agent_is_running_in_this_shell
check_ssh_agent_is_running_in_this_shell() {
	if [ "$SSH_AGENT_PID" == "" ]; then
		echo "NOTFOUND"
	elif ps -p $SSH_AGENT_PID > /dev/null; then
		echo "FOUND"
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
# Run with: source src/import.sh && assert_ssh_agent_is_running_in_this_shell
assert_ssh_agent_is_running_in_this_shell() {
	if [ "$(check_ssh_agent_is_running_in_this_shell)" != "FOUND" ]; then
		echo "The ssh-agent was not running, even though it was expected to be running."
		exit 5
	fi
}


#######################################
# Gets the latest commit sha of the repository to test the GitHub pac token.
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
# Run with: 
# bash -c 'source src/import.sh && get_latest_commit_public_github_repo "a-t-0" sponsor_example'
get_latest_commit_public_github_repo() {
	local github_username="$1"
	local github_repo_name="$2"

	# TODO(a-t-0): If the GitHub repository for testing purposes does not yet
	# exist in GitHub, create it automatically for the user.

	# Verify GitHub repository for testing purposes, exists.
	assert_public_github_repository_exists "$github_username" "$github_repo_name"

	# Get the latest commit of that repository GitHub repository.
	local latest_commit_on_default_branch=$(get_latest_commit_sha_of_default_branch $github_username $github_repo_name)

	# Verify the GitHub commit sha has a correct lenght/formatting.
	if [ ${#latest_commit_on_default_branch} -eq 40 ]; then 
		echo "$latest_commit_on_default_branch"
	else 
		echo "Error, the commit sha:$latest_commit_on_default_branch is not of correct length"  > /dev/tty
		exit 4
	fi
}

# Uses GitHub api to get the latest commit of a GitHub repository (branch).
# Run with: 
# bash -c "source src/import.sh && get_latest_commit_public_github_repo a-t-0 sponsor_example"
get_latest_commit_sha_of_default_branch() {
	local github_username="$1"
	local github_repo_name="$2"

	# Assert repo exists.
	assert_public_github_repository_exists "$github_username" "$github_repo_name"

	# Get commits
	local commits_json=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$github_username/$github_repo_name/commits?per_page=1&page=1)
	#echo "commits_json=$commits_json"
	#echo ""

	# Get the first commit.
	readarray -t branch_commits_arr <  <(echo "$commits_json" | jq ".[].sha")
	#echo "branch_commits_arr=$branch_commits_arr"
	
	# remove quotations
	echo "$branch_commits_arr" | tr -d '"'
}