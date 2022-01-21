#!/bin/bash

source src/import.sh


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

