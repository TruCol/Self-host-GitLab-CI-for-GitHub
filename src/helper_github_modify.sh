#!/bin/bash
# run with:
#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github"

####source src/helper_dir_edit.sh
####source src/helper_github_status.sh
###source src/helper_gitlab_modify.sh
###source src/helper_gitlab_status.sh
####source src/helper_git_neutral.sh
####source src/helper_ssh.sh
###source src/hardcoded_variables.txt
###source src/creds.txt
###source src/get_gitlab_server_runner_token.sh
###source src/push_repo_to_gitlab.sh

# Hardcoded data:

# Get GitHub username.
github_username=$1

# Get GitHub repository name.
github_repo=$2

# OPTIONAL: get GitHub personal access token or verify ssh access to support private repositories.
github_personal_access_code=$3

verbose=$4

# Get GitLab username.
# shellcheck disable=SC2154
gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT" | tr -d '\r')

# Get GitLab user password.
GITLAB_SERVER_PASSWORD=$(echo "$GITLAB_SERVER_PASSWORD" | tr -d '\r')

# Get GitLab personal access token from hardcoded file.
# shellcheck disable=SC2153
gitlab_personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN" | tr -d '\r')

# Specify GitLab mirror repository name.
gitlab_repo="$github_repo"

if [ "$verbose" == "TRUE" ]; then
	echo "MIRROR_LOCATION=$MIRROR_LOCATION"
	echo "github_username=$github_username"
	echo "github_repo=$github_repo"
	echo "github_personal_access_code=$github_personal_access_code"
	echo "gitlab_username=$gitlab_username"
	echo "GITLAB_SERVER_PASSWORD=$GITLAB_SERVER_PASSWORD"
	echo "gitlab_personal_access_token=$gitlab_personal_access_token"
	echo "gitlab_repo=$gitlab_repo"
fi


# Structure:github_modify
# 6.e.0.helper TODO: move to helper
github_branch_exists() {
	github_repo_name="$1"
	github_branch_name="$2"
	
	# Check if Github repository exists locally
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then
	
		# Get a list of the GitHub branches in that repository
		initialise_github_branches_array "$github_repo_name"
		
		# Check if the local copy of the GitHub repository contains the branch.
		# TODO: verify if it still works after the spaces around the dollar signs are removed.
		# shellcheck disable=SC2076
		# shellcheck disable=SC2154
		if [[ " ${github_branches[*]} " =~ " ${github_branch_name} " ]]; then
			echo "FOUND"
		else
			echo "NOTFOUND"
		fi
	else 
		echo "ERROR, the GitHub repository does not exist locally."
		exit 13
	fi
}

# Structure:github_modify
clone_github_repository() {
	if [[ "$1" != "" ]] && [[ "$2" != "" ]] && [[ "$3" != "" ]] && [[ "$4" != "" ]]; then
		github_username="$1"
		github_repository="$2"
		has_access="$3"
		target_directory="$4"
	fi
	#echo  "github_username=$github_username"
	#echo  "github_repository=$github_repository"
	#echo  "has_access=$has_access"
	#echo  "target_directory=$target_directory"
	
	# Remove target directory if it already exists.
	remove_dir "$target_directory"
	
	if [[ "$has_access" == "HASACCESS" ]]; then
		git clone git@github.com:"$github_username"/"$github_repository" "$target_directory"
	else
		git clone https://github.com/"$github_username"/"$github_repository".git "$target_directory"
		echo "Did not get ssh_access, downloaded using https, assumed it was a public repository."
		# TODO: support asking for GitHub username and pw to allow cloning private repositories over HTTPS.
		# TODO: support asking for GitHub personal access token to allow cloning private repositories over HTTPS.
	fi
}

# Structure:github_modify
push_to_github_repository() {
	github_username=$1
	has_access=$2
	target_directory=$3
	
	if [[ "$has_access" == "HASACCESS" ]]; then
		#git push git@github.com:"$github_username"/"$github_repository"
		# shellcheck disable=SC2034
		output=$(cd "$target_directory" && git push)
	else
		#$(cd "$target_directory" && git push https://github.com/"$github_username"/"$github_repository".git)
		echo "Did not get ssh_access, downloaded using https, assumed it was a public repository."
		# TODO: support asking for GitHub username and pw to allow cloning private repositories over HTTPS.
		# TODO: support asking for GitHub personal access token to allow cloning private repositories over HTTPS.
		exit 125
	fi
}

# Structure:github_modify
# TODO: make neutral
commit_changes() {
	target_directory=$1
	#echo "$commit_changes"
	#add_star_output=$(cd "$target_directory" && git add *)
	#add_dot_star=$(cd "$target_directory" && git add .*)
	# shellcheck disable=SC2034
	add_output=$(cd "$target_directory" && git add -A)
	# TODO: include git status command to verify no files were not added/deleted.
	
	# TODO: write path before and after and verify it is correct.
	# shellcheck disable=SC2034
	commit_output=$(cd "$target_directory" && git commit -m "Uploaded files to trigger GitLab runner.")
	# TODO: verify no more files are changed, using Git status command.
}

# Assumes repository exists, does a git pull in it to get the latest data.
# TODO: write test for method.
git_pull_github_repo() {
	local github_repo_name="$1"
	
	
	# Determine whether the Build status repository is cloned.
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	
	# Ensure the GitLab build status repository is cloned.
	if [ "$repo_was_cloned" == "FOUND" ]; then
		
		# Get the path before executing the command (to verify it is restored correctly after).
		pwd_before="$PWD"
		
		# Do a git pull inside the gitlab repository.
		cd "$MIRROR_LOCATION/GitHub/$github_repo_name" && git pull
		cd ../../../..
		
		# Get the path after executing the command (to verify it is restored correctly after).
		pwd_after="$PWD"
		
		# Verify the current path is the same as it was when this function started.
		if [ "$pwd_before" != "$pwd_after" ]; then
			echo "The current path is not returned to what it originally was."
			exit 111
		fi
	else 
		echo "ERROR, the GitHub repository does not exist locally."
		exit 12
	fi
}