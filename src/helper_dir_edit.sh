#!/bin/bash
# run with:
#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github"

source src/hardcoded_variables.txt
#source src/creds.txt

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

# Structure:dir_edit
# Ensure mirrors directory is created.
create_mirror_directories() {
	create_dir "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	create_dir "$PUBLIC_GITHUB_TEST_REPO_GLOBAL/GitHub"
	create_dir "$PUBLIC_GITHUB_TEST_REPO_GLOBAL/GitLab"
}

# Structure:dir_edit
#assert_equal "$(dir_exists "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")" "FOUND" 
verify_mirror_directories_are_created() {
	if [ "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" == "" ]; then
		echo "Mirror location is not created"
		exit 1
	elif test ! -d "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"; then
		echo "Mirror location is not created"
		exit 2
	elif test ! -d "$PUBLIC_GITHUB_TEST_REPO_GLOBAL/GitLab"; then
		echo "Mirror location GitLab directory is not created"
		exit 3
	else
		echo "FOUND"
	fi
}

# Structure:dir_edit
remove_mirror_directories() {
	remove_dir "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	remove_dir "$PUBLIC_GITHUB_TEST_REPO_GLOBAL/GitHub"
	remove_dir "$PUBLIC_GITHUB_TEST_REPO_GLOBAL/GitLab"
}

# Structure:dir_edit
copy_files_from_github_to_gitlab_repo_branches() {
	git_repository=$1
	rsync -av --progress "$PUBLIC_GITHUB_TEST_REPO_GLOBAL/GitHub/$git_repository/" "$PUBLIC_GITHUB_TEST_REPO_GLOBAL/GitLab/$git_repository" --exclude .git
}

