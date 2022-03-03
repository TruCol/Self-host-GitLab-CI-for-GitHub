#!/bin/bash


#######################################
# Copies the GitHub commit if it has a yaml file, to the local copy of the
# GitLab repository. And then proceeds to run the GitLab CI on it, and pushes
# the results back GitHub.
#
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
#######################################
# Run with: 
# bash -c "source src/import.sh src/run_ci_on_github_repo.sh && copy_github_commits_with_yaml_to_gitlab_repo hiveminds renamed_test_repo main b0964a97eb82a3ff533548202b6eecc477039dbb hiveminds"
copy_github_commits_with_yaml_to_gitlab_repo() {
	local github_username="$1"
	local github_repo_name="$2"
	local github_branch="$3"
	local github_commit_sha="$4"
	local organisation="$5"
	
	# Verify GitHub repository on which the CI is ran, exists locally.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
	# TODO: Assert GitHub build status repository exists.

	# Remove the GitLab repository. # TODO: move this to each branch
	# Similarly for each commit
	remove_the_gitlab_repository_on_which_ci_is_ran

	
	# Check if branch is found in local GitHub repo.
	printf "\n\n\n Checkout a local GitHub branch."
	local checkout_output="$(checkout_commit_in_github_repo "$github_repo_name" "$github_commit_sha" "GitHub")"
	
	
	# 5. If the branch contains a gitlab yaml file then
	# TODO: change to return a list of branches that contain GitLab 
	# yaml files, such that this function can get tested, instead 
	# of diving a method deeper.
	printf "\n\n\n Check if the local GitHub branch contains a GitLab yaml."
	#read -p "verify_github_commit_contains_gitlab_yaml\n\n"
	local branch_contains_yaml="$(verify_github_commit_contains_gitlab_yaml "$github_repo_name" "GitHub")"

	if [[ "$branch_contains_yaml" == "FOUND" ]]; then
	
		# TODO: check if github commit already has CI build status
		# TODO: allow overriding this check to enforce the CI to run again on this commit.
		printf "\n\n\n Check if the commit of the GitHub branch already has CI results."
		commit_filename="$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$organisation/$github_repo_name/$github_branch/$github_commit_sha.txt"
		exists="$(file_exists $commit_filename)"
		echo "commit_filename=$commit_filename"
		echo "exists=$exists"
		if [ "$(file_exists $commit_filename)" == "NOTFOUND" ]; then
		#if [ "$does_not_yet_have_a_build_status" == "TRUE" ]; then
			#echo "The commit:$github_commit_sha does not yet have a build status."
			if [[ "$branch_contains_yaml" == "FOUND" ]]; then
				echo "The commit:$github_commit_sha does not yet have a build status, and it DOES have a GitLab yaml."
				printf "\n\n\n Copy GitHub branch content to a GItLab branch to run the GitLab CI on it."
				copy_github_commit_with_yaml_to_gitlab_repo "$github_username" "$github_repo_name" "$github_branch" "$github_commit_sha" "$organisation"
				echo "Copied GitHub branch with GitLab yaml to GitLab repository mirror."
			fi
		else
			echo "Already has build status in GitHub:$github_repo_name/$github_branch/$github_commit_sha"
		fi
	fi
		
	# 4.b Export the evaluated GitHub commit SHA to GitHub build 
	# status repo.
	copy_evaluated_commit_to_github_status_repo "$github_repo_name" "$github_branch" "$github_commit_sha" "$organisation"
		
}


# This copies a single branch, the other, similar function above, copies all 
# branches.
copy_github_commit_with_yaml_to_gitlab_repo() {
	local github_username="$1"
	local github_repo_name="$2"
	local github_branch_name="$3"
	local github_commit_sha="$4"
	local organisation="$5"
	
	# Assume identical repository and branch names:
	local gitlab_repo_name="$github_repo_name"
	local gitlab_branch_name="$github_branch_name"
	
	
	
	# Get GitLab server url from credentials file.
	local gitlab_website_url=$(echo "$GITLAB_SERVER_HTTP_URL" | tr -d '\r')
		

	# 5.1 Create the empty GitLab repo.
	# Create the empty GitLab repository (deletes any existing GitLab repos with same name).
	# TODO: determine what happens if it already exists in GitLab
	create_empty_repository_v0 "$gitlab_repo_name" "$GITLAB_SERVER_ACCOUNT_GLOBAL"
	
	# 5.2 Clone the empty Gitlab repo from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# 5.3 Check if the GitLab branch exists, if not, create it.
	# 5.4 Check out the GitLab branch
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo "$gitlab_repo_name" "$gitlab_branch_name" "GitLab")"
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	# shellcheck disable=SC2154
	actual_result="$(get_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name" "GitLab")"
	manual_assert_equal "$actual_result" "$gitlab_branch_name"
	
	# 5.5 TODO: Check whether the GitLab branch already contains this
	# GitHub commit sha in its commit messages. (skip branch if yes)
	# 5.6 TODO: Verify whether the build status of this repository, branch, commit is not yet
	# known. (skip branch if yes)
	
	# 5.7 Copy the files from the GitHub branch into the GitLab branch.
	branch_content_identical_between_github_and_gitlab_output="$(copy_files_from_github_to_gitlab_commit "$github_repo_name" "$github_branch_name" "$gitlab_repo_name" "$gitlab_branch_name")"
	# TODO: change this method to ommit getting last line!
	#read -p "RESULTRESULT=$result"
	#last_line_result=$(get_last_line_of_set_of_lines_without_evaluation_of_arg "${result}")
	#manual_assert_equal "$last_line_result" "IDENTICAL"
	branch_content_identical_between_github_and_gitlab=$(assert_ends_in_identical ${branch_content_identical_between_github_and_gitlab_output})
	if [ "$branch_content_identical_between_github_and_gitlab" == "TRUE" ]; then
	
		# 5.8 Commit the changes to GitLab.
		manual_assert_not_equal "" "$github_commit_sha"
		commit_changes_to_gitlab_for_commit "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
		# TODO: verify the changes are committed correctly

		# 5.8. Push the results to GitLab, with the commit message of the GitHub commit sha.
		# Perform the Push function.
		#read -p "\n\n\n Push the commit to GitLab."
		push_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
		# TODO: verify the changes are pushed correctly

		# Get last commit of GitLab repo.
		#read -p "\n\n\n Get the commit sha from GitLab."
		gitlab_commit_sha=$(get_commit_sha_of_branch "$github_branch_name" "$github_repo_name" "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL")
		gitlab_commit_sha=$(echo "$gitlab_commit_sha" | tr -d '"') # removes double quotes at start and end.
		#echo "gitlab_commit_sha=$gitlab_commit_sha"

		# 6. Get the GitLab CI build status for that GitLab commit.
		#read -p "\n\n\n GETTING BUILD STATUS from managing GItLab CI build status."
		#build_status="$(manage_get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")"
		build_status="$(call_eg_function_with_timeout "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")"
		echo "build_status=$build_status"
		#read -p "\n\n\n DONE GETTING build status., IT IS:$build_status \n\n\n"
		#last_line_gitlab_ci_build_status=$(get_last_line_of_set_of_lines_without_evaluation_of_arg "${build_status}")
		#echo "last_line_gitlab_ci_build_status=$last_line_gitlab_ci_build_status"

		# TODO: modified till here

		# 7. Once the build status is found, use github personal access token to
		# set the build status in the GitHub commit.
		#read -p "\n\n\n Set the build status of the GitHub commit using GitHub personal access token."
		# TODO: ensure personal access token is created automatically to set build status.
		#output=$(set_build_status_of_github_commit_using_github_pat "$github_username" "$github_repo_name" "$github_commit_sha" "$gitlab_website_url" "$last_line_gitlab_ci_build_status")
		output=$(set_build_status_of_github_commit_using_github_pat "$github_username" "$github_repo_name" "$github_commit_sha" "$gitlab_website_url" "$build_status")
		echo "output=$output"

		# 8. Copy the commit build status from GitLab into the GitHub build status repo.
		copy_commit_build_status_to_github_status_repo "$github_username" "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$build_status" "$organisation" "FALSE"

		# 9. Push the commit build status to the GitHub build status repo. 
		#push_commit_build_status_in_github_status_repo_to_github "$github_username"
		
		# TODO: delete this function
		#get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha"
	else
		echo "ERROR, the GitHub branch content was not copied correctly to the GitLab branch."
		exit 77
	fi
}