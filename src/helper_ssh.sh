#!/bin/bash

# Structure:ssh
# Activates/enables the ssh for 
activate_ssh_account() {
	git_username=$1
	#eval "$(ssh-agent -s)"
	#$(eval "$(ssh-agent -s)")
	#$("$(ssh-agent -s)")
	#$(ssh-add ~/.ssh/"$git_username")
	#ssh-add ~/.ssh/"$git_username"
	eval "$(ssh-agent -s 3>&-)"
    ssh-add ~/.ssh/"$git_username"
}

# Structure:ssh
# Check ssh-access to GitHub repo.
check_ssh_access_to_repo() {
	local local_git_username=$1
	github_repository=$2
	retry=$3
	
	# shellcheck disable=SC2034
	my_service_status=$(git ls-remote git@github.com:"$local_git_username"/"$github_repository".git 2>&1)
	found_error_in_ssh_command=$(lines_contain_string "ERROR" "\${my_service_status}")
	
	if [ "$found_error_in_ssh_command" == "NOTFOUND" ]; then
		echo "HASACCESS"
	elif [ "$found_error_in_ssh_command" == "FOUND" ]; then
		if [ "$retry" == "YES" ]; then
			echo "Your ssh-account:$local_git_username does not have pull access to the repository:$github_repository"
			exit 4
			# TODO: Throw error
			#(A public repository should grant ssh access even if no ssh credentials for that GitHub user is given.)
		else
			#activate_ssh_account "$local_git_username"
			check_ssh_access_to_repo "$local_git_username" "$github_repository" "YES"
		fi
	fi
}

# Structure:ssh
has_access() {
	local github_repo="$1"
	#echo $(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo")
	check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo"
}