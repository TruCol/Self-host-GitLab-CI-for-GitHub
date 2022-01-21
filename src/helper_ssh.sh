#!/bin/bash
# run with:
#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github"

###source src/helper_dir_edit.sh
###source src/helper_github_modify.sh
###source src/helper_github_status.sh
###source src/helper_gitlab_modify.sh
###source src/helper_gitlab_status.sh
###source src/helper_git_neutral.sh
####source src/helper_ssh.sh
###source src/hardcoded_variables.txt
###source src/creds.txt
###source src/get_gitlab_server_runner_token.sh
###source src/push_repo_to_gitlab.sh

# Hardcoded data:

# Get GitHub username.
GITHUB_USERNAME_GLOBAL=$1

# Get GitHub repository name.
github_repo=$2

# OPTIONAL: get GitHub personal access token or verify ssh access to support private repositories.
github_personal_access_code=$3

verbose=$4

# Get GitLab username.
# shellcheck disable=SC2154
gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')

# Get GitLab user password.
GITLAB_SERVER_PASSWORD_GLOBAL=$(echo "$GITLAB_SERVER_PASSWORD_GLOBAL" | tr -d '\r')

# Get GitLab personal access token from hardcoded file.
# shellcheck disable=SC2153
GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')

# Specify GitLab mirror repository name.
gitlab_repo="$github_repo"

if [ "$verbose" == "TRUE" ]; then
	echo "PUBLIC_GITHUB_TEST_REPO_GLOBAL=$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	echo "GITHUB_USERNAME_GLOBAL=$GITHUB_USERNAME_GLOBAL"
	echo "github_repo=$github_repo"
	echo "github_personal_access_code=$github_personal_access_code"
	echo "gitlab_username=$gitlab_username"
	echo "GITLAB_SERVER_PASSWORD_GLOBAL=$GITLAB_SERVER_PASSWORD_GLOBAL"
	echo "GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL=$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL"
	echo "gitlab_repo=$gitlab_repo"
fi


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
	GITHUB_USERNAME_GLOBAL=$1
	github_repository=$2
	retry=$3
	
	# shellcheck disable=SC2034
	my_service_status=$(git ls-remote git@github.com:"$GITHUB_USERNAME_GLOBAL"/"$github_repository".git 2>&1)
	found_error_in_ssh_command=$(lines_contain_string "ERROR" "\${my_service_status}")
	
	if [ "$found_error_in_ssh_command" == "NOTFOUND" ]; then
		echo "HASACCESS"
	elif [ "$found_error_in_ssh_command" == "FOUND" ]; then
		if [ "$retry" == "YES" ]; then
			echo "Your ssh-account:$GITHUB_USERNAME_GLOBAL does not have pull access to the repository:$github_repository"
			exit 4
			# TODO: Throw error
			#(A public repository should grant ssh access even if no ssh credentials for that GitHub user is given.)
		else
			#activate_ssh_account "$GITHUB_USERNAME_GLOBAL"
			check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repository" "YES"
		fi
	fi
}

# Structure:ssh
has_access() {
	#echo $(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo")
	check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo"
}