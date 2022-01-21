#!/bin/bash
# run with:
#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github"

source src/hardcoded_variables.txt
#source src/creds.txt

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

# Structure:dir_edit
# Ensure mirrors directory is created.
create_mirror_directories() {
	create_dir "$MIRROR_LOCATION"
	create_dir "$MIRROR_LOCATION/GitHub"
	create_dir "$MIRROR_LOCATION/GitLab"
}

# Structure:dir_edit
#assert_equal "$(dir_exists "$MIRROR_LOCATION")" "FOUND" 
verify_mirror_directories_are_created() {
	if [ "$MIRROR_LOCATION" == "" ]; then
		echo "Mirror location is not created"
		exit 1
	elif test ! -d "$MIRROR_LOCATION"; then
		echo "Mirror location is not created"
		exit 2
	elif test ! -d "$MIRROR_LOCATION/GitLab"; then
		echo "Mirror location GitLab directory is not created"
		exit 3
	else
		echo "FOUND"
	fi
}

# Structure:dir_edit
remove_mirror_directories() {
	remove_dir "$MIRROR_LOCATION"
	remove_dir "$MIRROR_LOCATION/GitHub"
	remove_dir "$MIRROR_LOCATION/GitLab"
}

# Structure:dir_edit
copy_files_from_github_to_gitlab_repo_branches() {
	git_repository=$1
	rsync -av --progress "$MIRROR_LOCATION/GitHub/$git_repository/" "$MIRROR_LOCATION/GitLab/$git_repository" --exclude .git
}

