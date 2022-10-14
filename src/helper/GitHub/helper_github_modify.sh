#!/bin/bash

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
		local github_username="$1"
		local github_repository="$2"
		local has_quick_ssh_access="$3"
		local target_directory="$4"
	else
		echo "ERROR, incoming args not None."
		exit 14
	fi
	
	# Remove target directory if it already exists.
	remove_dir "$target_directory"

	if [[ "$has_quick_ssh_access" == "HAS_QUICK_SSH_ACCESS" ]]; then
		git clone --quiet git@github.com:"$github_username"/"$github_repository" "$target_directory"
	else
		git clone --quiet https://github.com/"$github_username"/"$github_repository".git "$target_directory"
		echo "Warning: did not get ssh_access, downloaded using https, assumed it was a public repository."
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
		echo "Error, did not get ssh_access, downloaded, so was not able to push succesfully."
		# TODO: support asking for GitHub username and pw to allow cloning private repositories over HTTPS.
		# TODO: support asking for GitHub personal access token to allow cloning private repositories over HTTPS.
		exit 125
	fi
}

# Run with:
# bash -c "source src/import.sh && push_to_github_repository_with_ssh src/mirrors/GitHub/gitlab-ci-build-statuses"
push_to_github_repository_with_ssh() {
	local target_directory="$1"
	# Verify has push access
	
	# Push
	if [ "$target_directory" != "" ]; then
		if [ -d "$target_directory" ]; then
			output=$(cd "$target_directory" && git push > /dev/null 2>&1)
			echo "SUCCESS"
		else
			echo "The target directory:$target_directory was not found."
			exit 4
		fi
	fi
}

# Structure:github_modify
# TODO: make neutral
commit_changes() {
	local target_directory="$1"
	local commit_message="$2"
	#echo "$commit_changes"
	#add_star_output=$(cd "$target_directory" && git add *)
	#add_dot_star=$(cd "$target_directory" && git add .*)

	# shellcheck disable=SC2034
	local add_output=$(cd "$target_directory" && git add -A)
	# TODO: include git status command to verify no files were not added/deleted.
	
	# TODO: write path before and after and verify it is correct.
	# shellcheck disable=SC2034
	#local commit_output=$(cd "$target_directory" && git commit -m "Uploaded files to trigger GitLab runner.")
	local commit_output=$(cd "$target_directory" && git commit -m "$commit_message")
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

# Run with:
# bash -c "source src/import.sh && copy_evaluated_commit_to_github_status_repo sponsor_example main somecommit_sha hiveminds"
copy_evaluated_commit_to_github_status_repo() {
	local github_repo_name="$1"
	local github_branch_name="$2"
	local github_commit_sha="$3"
	local organisation="$4"

	# Verify the mirror location exists
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_dir_exists "$MIRROR_LOCATION"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub"
	
	## 8. Clone the GitHub build statusses repository.
	#printf "\n download_and_overwrite_repository_using_ssh "
	#download_and_overwrite_repository_using_ssh "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	#sleep 1
	
	# 9. Verify the Build status repository is cloned.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"

	# 10. Copy the GitLab CI Build status icon to the build status repository.
	# Create a folder of the repository on which a CI has been ran, inside the GitHub build status website repository, if it does not exist yet
	# Also add a folder for the branch(es) of that GitLab CI repository, in that respective folder.
	local build_status_icon_output_dir="$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$organisation/$github_repo_name/$github_branch_name"
	mkdir -p "$build_status_icon_output_dir"
	
	
	# TODO: 11. Include the build status and link to the GitHub commit in the repository in the SVG file.
	# Create build status icon
	touch "$build_status_icon_output_dir""/$github_commit_sha.txt"
	# Assert svg file is created correctly
	manual_assert_equal "$(file_exists "$build_status_icon_output_dir""/$github_commit_sha.txt")" "FOUND"
	
	if [ "$github_commit_sha" == "" ]; then
		echo "github_repo_name=$github_repo_name, branch=$github_branch_name in folder GitHub, the commit is empty:$github_commit_sha"
		exit 4
	fi

	# Ensure evaluated commit list exists.
	touch "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME"

	# Append commit to list of evaluated commits.
	# TODO: verify works: if not in list already
	matches_on_commit="$(grep $github_commit_sha "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME")"
	printf "\n4.$i.8.6 Checking if the file at:$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME contains the github_commit_sha=$github_commit_sha \n and matches_on_commit=$matches_on_commit"
	contains_sha_already=$(string_in_lines "$github_commit_sha" "$matches_on_commit")
	printf "\n4.$i.8.7 contains_sha_already=$contains_sha_already"
	if [ "$contains_sha_already" == "NOTFOUND" ]; then
		printf "\n4.$i.8.8 appending commit sha to the list "
		echo "$github_commit_sha" >> "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME"
		#read -p "ADDED! Verify it is there, and verify the GitHub commit status of the repo."
	fi

	# manual_assert evaluated GitHub commit list file exists.
	printf "\n4.$i.8.9 Assert the GitHub build status file list exists at: "$(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME")" "FOUND""
	manual_assert_equal "$(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME")" "FOUND"
	
	# TODO: assert evaluated GitHub commit lists contains the GitHub commit
	# sha.
}


# Run width:
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && get_build_status_repository_from_github"
get_build_status_repository_from_github() {

	# Ensure the mirror directories are created.
	create_mirror_directories

	# Verify the mirror location exists
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_dir_exists "$MIRROR_LOCATION"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	#has_access="$(check_quick_ssh_access_to_repo "$github_username" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
	
	# 8. Clone the GitHub build statusses repository.
	download_and_overwrite_repository_using_ssh "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	sleep 2
	
	# 9. Verify the Build status repository is cloned.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	# 10. Copy the GitLab CI Build status icon to the build status repository.
	# Create a folder of the repository on which a CI has been ran, inside the GitHub build status website repository, if it does not exist yet
	# Also add a folder for the branch(es) of that GitLab CI repository, in that respective folder.
}