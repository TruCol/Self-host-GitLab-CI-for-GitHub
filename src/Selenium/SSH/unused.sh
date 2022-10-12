#!/bin/bash

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
# TODO(a-t-0): Write tests for this method.
# TODO(a-t-0): If only one of two files exists, generate or get the public key
# sha, then delete the keypair with: ssh-agent d. (Currently it only does that 
# if both files exist). Also remove the assert that both key files dont exist.
#######################################
# Run with: source src/import.sh && delete_ssh_key_from_agent_if_it_is_in_agent some_test_ssh_key_name
delete_ssh_key_from_agent_if_it_is_in_agent() {
	local identifier="$1"
	local public_key_filename="$identifier.pub"
	local private_key_filename="$identifier"

	if [ "$(file_exists $DEFAULT_SSH_LOCATION/$private_key_filename)" == "FOUND" ] || [ "$(file_exists $DEFAULT_SSH_LOCATION/$public_key_filename)" == "FOUND" ]; then
		# Convert ssh-identifier to public key_sha
		public_key_sha=$(get_public_key_sha_from_key_filename $identifier)

		# Activate the ssh-agent in this shell.
		if [ "$(check_if_public_key_sha_is_in_ssh_agent $public_key_sha)" == "FOUND" ]; then
			ssh-add -d "$DEFAULT_SSH_LOCATION/$public_key_filename"
		fi

		# Assert the key pair is not in ssh-agent -l anymore.
		if [ "$(check_if_public_key_sha_is_in_ssh_agent $public_key_sha)" == "FOUND" ]; then
			echo "The ssh-key pair:$identifier was expected to be deleted, but it still exists in: ssh-agent -l"
			echo "$(ssh-add -l)"
			#exit 5
		fi
	else
		# Ensure an error is thrown if one of two keyfiles still exists.
		manual_assert_file_does_not_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
		manual_assert_file_does_not_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
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
# TODO(a-t-0): DELETE IF THIS IS NOT USED
#######################################
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
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): DELETE IF THIS IS NOT USED
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
# TODO(a-t-0): DELETE IF THIS IS NOT USED
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