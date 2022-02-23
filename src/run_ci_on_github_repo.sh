#!/bin/bash

# source src/import.sh src/helper_github_status.sh && initialise_github_repositories_array "hiveminds"
# source src/import.sh src/helper_github_status.sh && initialise_github_repositories_array "a-t-0"
# Make a list of the repositories in the GitHub repository.
initialise_github_repositories_array() {
	local github_organisation_or_username="$1"
	get_org_repos github_repositories "$github_organisation_or_username" # call function to populate the array
	declare -p github_repositories
}

# source src/import.sh src/run_ci_on_github_repo.sh && run_ci_on_all_repositories_of_user "hiveminds"
# source src/import.sh src/run_ci_on_github_repo.sh && run_ci_on_all_repositories_of_user "a-t-0"
run_ci_on_all_repositories_of_user(){
	local github_organisation_or_username="$1"
	
	initialise_github_repositories_array "$github_organisation_or_username"
	
	for github_repository in "${github_repositories[@]}"; do
		echo "$github_repository"
		run_ci_on_github_repo "$github_organisation_or_username" "$github_repository"
	done
}

# run with:
# bash -c "source src/import.sh src/run_ci_on_github_repo.sh && run_ci_on_github_repo a-t-0 sponsor_example"
# source src/import.sh src/run_ci_on_github_repo.sh && run_ci_on_github_repo "a-t-0" "sponsor_example"
run_ci_on_github_repo() {
	github_username="$1"
	github_repo_name="$2"
	
	# TODO: write test to verify whether the build status can be pushed to a branch. (access wise).
	# TODO: Store log file output if a repo (and/or branch) have been skipped.
	# TODO: In that log file, inlcude: time, which user, which repo, which branch, why.
	
	download_github_repo_on_which_to_run_ci "$github_username" "$github_repo_name"
	copy_github_branches_with_yaml_to_gitlab_repo "$github_username" "$github_repo_name"
}


# run with:
# source src/import.sh && download_github_repo_on_which_to_run_ci "a-t-0" "sponsor_example"
download_github_repo_on_which_to_run_ci() {
	local github_username="$1"
	local github_repo_name="$2"
	
	# 1. Clone the GitHub repo.
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_dir_not_exists "$MIRROR_LOCATION"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitHub"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	# TODO: replace asserts with functions
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_dir_exists "$MIRROR_LOCATION"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitLab"
	
	

	# Verify ssh-access
	# TODO: resolve error when ran from test.
	has_access="$(check_ssh_access_to_repo "$github_username" "$github_repo_name")"

	# Clone GitHub repo at start of test.
	clone_github_repository "$github_username" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	# TODO: determine why this downloads to: src/mirrors/GitHub/sponsor_example/sponsor_example (one too deep.)
	#download_and_overwrite_repository_using_ssh "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL" "$MIRROR_LOCATION/GitHub/"
	sleep 2
	
	# 2. Verify the GitHub repo is cloned.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
}


#######################################
# Copies the GitHub branches that have a yaml file, to the local copy of the
# GitLab repository.
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
# bash -c "source src/import.sh src/run_ci_on_github_repo.sh && copy_github_branches_with_yaml_to_gitlab_repo a-t-0 sponsor_example"
# bash -c "source src/import.sh src/run_ci_on_github_repo.sh && copy_github_branches_with_yaml_to_gitlab_repo hiveminds renamed_test_repo"
# source src/import.sh && copy_github_branches_with_yaml_to_gitlab_repo a-t-0 sponsor_example
copy_github_branches_with_yaml_to_gitlab_repo() {
	local github_username="$1"
	local github_repo_name="$2"
	
	# Delete the repository locally if it exists.
	remove_dir "$MIRROR_LOCATION/GitHub/$github_repo_name"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"

	# TODO: change this method to download with https?
	# Download the GitHub repo on which to run the GitLab CI:
	download_github_repo_on_which_to_run_ci "$github_username" "$github_repo_name"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"

	# 3. Get the GitHub branches
	get_git_branches github_branches "GitHub" "$github_repo_name"      # call function to populate the array
	# shellcheck disable=SC2154
	declare -p github_branches

	#manual_assert_equal ""${github_branches[0]}"" "attack_in_new_file"
	#manual_assert_equal ""${github_branches[1]}"" "attack_unit_test"
	#manual_assert_equal ""${github_branches[2]}"" "main"
	#manual_assert_equal ""${github_branches[3]}"" "no_attack_in_filecontent"
	#manual_assert_equal ""${github_branches[4]}"" "no_attack_in_new_file"
	
	# 4. Loop over the GitHub branches by checking each branch out.
	for i in "${!github_branches[@]}"; do
		#echo "${github_branches[i]}"
		
		# Check if branch is found in local GitHub repo.
		local checkout_output="$(checkout_branch_in_github_repo "$github_repo_name" "${github_branches[i]}" "GitHub")"
		# TODO: write some test to verify this.
		
		# Get SHA of commit of local GitHub branch.
		local current_branch_github_commit_sha=$(get_current_github_branch_commit "$github_repo_name" "${github_branches[i]}" "GitHub")
		echo "current_branch_github_commit_sha=$current_branch_github_commit_sha"
		if [ "$current_branch_github_commit_sha" == "" ]; then
			echo "github_repo_name=$github_repo_name, branch=${github_branches[i]} in folder GitHub, the commit is empty:$current_branch_github_commit_sha"
			exit 4
		fi
		
		
		# 5. If the branch contains a gitlab yaml file then
		# TODO: change to return a list of branches that contain GitLab 
		# yaml files, such that this function can get tested, instead 
		# of diving a method deeper.
		local branch_contains_yaml="$(verify_github_branch_contains_gitlab_yaml "$github_repo_name" "${github_branches[i]}" "GitHub")"
		if [[ "$branch_contains_yaml" == "FOUND" ]]; then
		
			# TODO: check if github commit already has CI build status
			# TODO: allow overriding this check to enforce the CI to run again on this commit.
			commit_filename="$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/${github_branches[i]}/$current_branch_github_commit_sha.txt"
			exists="$(file_exists $commit_filename)"
			echo "commit_filename=$commit_filename"
			echo "exists=$exists"
			if [ "$(file_exists $commit_filename)" == "NOTFOUND" ]; then
			#if [ "$does_not_yet_have_a_build_status" == "TRUE" ]; then
				#echo "The commit:$current_branch_github_commit_sha does not yet have a build status."
				if [[ "$branch_contains_yaml" == "FOUND" ]]; then
					echo "The commit:$current_branch_github_commit_sha does not yet have a build status, and it DOES have a GitLab yaml."
					copy_github_branch_with_yaml_to_gitlab_repo "$github_username" "$github_repo_name" "${github_branches[i]}" "$current_branch_github_commit_sha"
					echo "Copied GitHub branch with GitLab yaml to GitLab repository mirror."
				fi
			else
				echo "Already has build status in GitHub:$github_repo_name/${github_branches[i]}/$current_branch_github_commit_sha"
			fi
		fi
	done
	
}


# This copies a single branch, the other, similar function above, copies all 
# branches.
copy_github_branch_with_yaml_to_gitlab_repo() {
	github_username="$1"
	github_repo_name="$2"
	github_branch_name="$3"
	github_commit_sha="$4"
	
	# Assume identical repository and branch names:
	gitlab_repo_name="$github_repo_name"
	gitlab_branch_name="$github_branch_name"
	
	
	
	# Get GitLab server url from credentials file.
	local gitlab_website_url=$(echo "$GITLAB_WEBSITE_URL_GLOBAL" | tr -d '\r')
	
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch "$github_repo_name" "$github_branch_name" "GitHub")"
	manual_assert_equal "$actual_result" "$github_branch_name"
	
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(verify_github_branch_contains_gitlab_yaml "$github_repo_name" "$github_branch_name" "GitHub")"
	manual_assert_equal "$actual_result" "FOUND"
	
	# 5.1 Create the empty GitLab repo.
	# Create the empty GitLab repository (deletes any existing GitLab repos with same name).
	create_empty_repository_v0 "$gitlab_repo_name" "$GITLAB_SERVER_ACCOUNT_GLOBAL"
	
	# 5.2 Clone the empty Gitlab repo from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# 5.3 Check if the GitLab branch exists, if not, create it.
	# 5.4 Check out the GitLab branch
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo "$gitlab_repo_name" "$gitlab_branch_name" "GitLab")"
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	# shellcheck disable=SC2154
	actual_result="$(get_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name" "$company")"
	manual_assert_equal "$actual_result" "$gitlab_branch_name"
	
	# 5.5 TODO: Check whether the GitLab branch already contains this
	# GitHub commit sha in its commit messages. (skip branch if yes)
	# 5.6 TODO: Verify whether the build status of this repository, branch, commit is not yet
	# known. (skip branch if yes)
	
	# 5.7 Copy the files from the GitHub branch into the GitLab branch.
	branch_content_identical_between_github_and_gitlab_output="$(copy_files_from_github_to_gitlab_branch "$github_repo_name" "$github_branch_name" "$gitlab_repo_name" "$gitlab_branch_name")"
	# TODO: change this method to ommit getting last line!
	#read -p "RESULTRESULT=$result"
	#last_line_result=$(get_last_line_of_set_of_lines_without_evaluation_of_arg "${result}")
	#manual_assert_equal "$last_line_result" "IDENTICAL"
	branch_content_identical_between_github_and_gitlab=$(assert_ends_in_identical ${branch_content_identical_between_github_and_gitlab_output})
	if [ "$branch_content_identical_between_github_and_gitlab" == "TRUE" ]; then
	
		# 5.8 Commit the changes to GitLab.
		manual_assert_not_equal "" "$github_commit_sha"
		commit_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
		# TODO: verify the changes are committed correctly

		# 5.8. Push the results to GitLab, with the commit message of the GitHub commit sha.
		# Perform the Push function.
		push_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
		# TODO: verify the changes are pushed correctly

		# Get last commit of GitLab repo.
		gitlab_commit_sha=$(get_commit_sha_of_branch "$github_branch_name" "$github_repo_name" "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL")
		gitlab_commit_sha=$(echo "$gitlab_commit_sha" | tr -d '"') # removes double quotes at start and end.
		#echo "gitlab_commit_sha=$gitlab_commit_sha"

		# 6. Get the GitLab CI build status for that GitLab commit.
		build_status="$(manage_get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")"
		#echo "build_status=$build_status"
		#last_line_gitlab_ci_build_status=$(get_last_line_of_set_of_lines_without_evaluation_of_arg "${build_status}")
		#echo "last_line_gitlab_ci_build_status=$last_line_gitlab_ci_build_status"



		# 7. Once the build status is found, use github personal access token to
		# set the build status in the GitHub commit.
		# TODO: ensure personal access token is created automatically to set build status.
		# output=$(set_build_status_of_github_commit_using_github_pat "$github_username" "$github_repo_name" "$github_commit_sha" "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$gitlab_website_url" "$last_line_gitlab_ci_build_status")
		# echo "output=$output"

		# 8. Copy the commit build status from GitLab into the GitHub build status repo.
		copy_commit_build_status_to_github_status_repo "$github_username" "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$build_status"

		# 9. Push the commit build status to the GitHub build status repo. 
		push_commit_build_status_in_github_status_repo_to_github "$github_username"
		
		# TODO: delete this function
		#get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha"
	else
		echo "ERROR, the GitHub branch content was not copied correctly to the GitLab branch."
		exit 77
	fi
}	

# TODO: 5.9 Verify the CI is running for this commit.

manage_get_gitlab_ci_build_status() {
	github_repo_name="$1"
	github_branch_name="$2"
	gitlab_commit_sha="$3"
	count=0
	
	parsed_github_build_status="$(rebuild_get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")"
	while [[ "$(is_desirable_github_build_status_excluding_pending "$parsed_github_build_status")" == "NOTFOUND" ]]; do
	
		sleep 10
		count=$((count+1))
		if [[ "$count" -gt 20 ]]; then
			echo "Waiting on the GitLab CI build status took too long. Raising error. The last known status was:$parsed_github_build_status"
			#exit 111
		else
			parsed_github_build_status="$(rebuild_get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")"
			
		fi
	done
	echo "$parsed_github_build_status"
}

rebuild_get_gitlab_ci_build_status() {
	local github_repo_name="$1"
	local github_branch_name="$2"
	local gitlab_commit_sha="$3"
	
	# Assume identical repository and branch names:
	gitlab_repo_name="$github_repo_name"
	gitlab_branch_name="$github_branch_name"

	
	
	# curl --header "PRIVATE-TOKEN: <your_access_token>" "http://127.0.0.1/api/v4/projects/1/pipelines"
	pipelines=$(curl --header "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" "http://127.0.0.1/api/v4/projects/$GITLAB_SERVER_ACCOUNT_GLOBAL%2F$gitlab_repo_name/pipelines")
	
	# get build status from pipelines
	job=$(echo "$pipelines" | jq -r 'map(select(.sha == "'"$gitlab_commit_sha"'"))')
	#echo "job=$job"
	#gitlab_ci_status="$(echo "$job" | jq ".[].status")" | tr -d '"')
	gitlab_ci_status=$(echo "$(echo $job | jq ".[].status")" | tr -d '"')
	#read -p "gitlab_ci_status=$gitlab_ci_status"
	parsed_github_status="$(parse_gitlab_ci_status_to_github_build_status "$gitlab_ci_status")"
	echo "$parsed_github_status"
}

parse_gitlab_ci_status_to_github_build_status() {
	gitlab_status="$1"
	
	if [[ "$gitlab_status" == "failed" ]]; then
		echo "failure"
	elif [[ "$gitlab_status" == "success" ]]; then
		echo "success"
	elif [[ "$gitlab_status" == "error" ]]; then
		echo "error"
	elif [[ "$gitlab_status" == "unknown" ]]; then
		echo "unknown"
	elif [[ "$gitlab_status" == "running" ]]; then
		echo "pending"
	elif [[ "$gitlab_status" == "" ]]; then
		echo ""
	else 
		echo "ERROR, an invalid state is found:$gitlab_status"
		#exit 112
	fi
}

#######################################
# Verifies the repository is able to set the build status of GitHub commits in 
# the GitHub user/organisation.
# 7. Once the build status is found, use github personal access token to
# set the build status in the GitHub commit.
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
# TODO(a-t-0): verify incoming commit build status is valid.
# TODO(a-t-0): verify incoming redirect url is valid.
#######################################
# Run with:
# bash -c 'source src/import.sh && set_build_status_of_github_commit_using_github_pat a-t-0 sponsor_example 02c5fce3500d7b9e2d79cb5b7d886020a403cf58 http://127.0.0.1  pending'
set_build_status_of_github_commit_using_github_pat() {
	local github_username="$1"
	local github_repo_name="$2"
	local github_commit_sha="$3"
	local redirect_to_ci_url="$4"
	local commit_build_status="$5"

	# Check if arguments are valid.
	if [[ "$github_commit_sha" == "" ]]; then
		echo "ERROR, the github commit sha is empty, whereas it shouldn't be."
		exit 113
	elif [[ "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]]; then
		echo "ERROR, the github personal access token is empty, whereas it shouldn't be."
		exit 114
	elif [[ "$commit_build_status" == "" ]]; then
		echo "ERROR, the GitLab build status is empty, whereas it shouldn't be."
		exit 115
	elif [[ "$redirect_to_ci_url" == "" ]]; then
		echo "ERROR, the GitLab server website url is empty, whereas it shouldn't be."
		exit 116
	fi

	# TODO: verify incoming commit build status is valid.
	# TODO: verify incoming redirect url is valid.

	
	#echo "redirect_to_ci_url=$redirect_to_ci_url"
	#echo "commit_build_status=$commit_build_status"
	
	# Create message in JSON format
	JSON_FMT='{"state":"%s","description":"%s","target_url":"%s"}\n'
	# shellcheck disable=SC2059
	json_string=$(printf "$JSON_FMT" "$commit_build_status" "$commit_build_status" "$redirect_to_ci_url")
	echo "json_string=$json_string"
	
	# Set the build status
	setting_output=$(curl -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" --request POST --data "$json_string" https://api.github.com/repos/"$github_username"/"$github_repo_name"/statuses/"$github_commit_sha")
	
	# Check if output is valid
	#echo "setting_output=$setting_output"
	if [ "$(lines_contain_string '"message": "Bad credentials"' "${setting_output}")" == "FOUND" ]; then
		# TODO: specify which checkboxes in the `repository` checkbox are required.
		echo "ERROR, the github personal access token is not valid. Please make a new one. See https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token and ensure you tick. $setting_output"
		exit 117
	elif [ "$(lines_contain_string '"documentation_url": "https://docs.github.com/rest' "${setting_output}")" == "FOUND" ]; then
		echo "ERROR: $setting_output"
		exit 118
	fi
	
	# Verify the build status is set correctly
	getting_output=$(GET https://api.github.com/repos/"$github_username"/"$github_repo_name"/commits/"$github_commit_sha"/statuses)
	expected_url="\"url\":\"https://api.github.com/repos/$github_username/$github_repo_name/statuses/$github_commit_sha\","
	expected_state="\"state\":\"$commit_build_status\","
	if [ "$(lines_contain_string "$expected_url" "${getting_output}")" == "NOTFOUND" ]; then
		# shellcheck disable=SC2059
		printf "Error, the status of the repo did not contain:$expected_url \n because the getting output was: $getting_output"
		exit 119
	elif [ "$(lines_contain_string "$expected_state" "${getting_output}")" == "NOTFOUND" ]; then
		echo "Error, the status of the repo did not contain:$expected_state"
		exit 120
	fi
}


#######################################
# Checks if the repository is able to set the build status of GitHub commits in 
# the GitHub user/organisation.
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
#  TRUE if the build status was set succesfully.
#  FALSE if the build status was not set succesfully.
# TODO(a-t-0): Write tests for this method.
# TODO(a-t-0): verify incoming commit build status is valid.
# TODO(a-t-0): verify incoming redirect url is valid.
#######################################
# Run with:
# bash -c 'source src/import.sh && check_if_can_set_build_status_of_github_commit_using_github_pat a-t-0 sponsor_example 02c5fce3500d7b9e2d79cb5b7d886020a403cf58 http://127.0.0.1  pending'
check_if_can_set_build_status_of_github_commit_using_github_pat() {
	local github_username="$1"
	local github_repo_name="$2"
	local github_commit_sha="$3"
	local redirect_to_ci_url="$4"
	local commit_build_status="$5"
	#echo "github_username=$github_username"
	#echo "github_repo_name=$github_repo_name"
	#echo "github_commit_sha=$github_commit_sha"
	#echo "redirect_to_ci_url=$redirect_to_ci_url"
	#echo "commit_build_status=$commit_build_status"

	# Check if arguments are valid.
	if [[ "$github_commit_sha" == "" ]]; then
		echo "ERROR, the github commit sha is empty, whereas it shouldn't be."
		exit 113
	elif [[ "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]]; then
		echo "ERROR, the github personal access token is empty, whereas it shouldn't be."
		exit 114
	elif [[ "$commit_build_status" == "" ]]; then
		echo "ERROR, the GitLab build status is empty, whereas it shouldn't be."
		exit 115
	elif [[ "$redirect_to_ci_url" == "" ]]; then
		echo "ERROR, the GitLab server website url is empty, whereas it shouldn't be."
		exit 116
	fi

	# TODO: verify incoming commit build status is valid.
	# TODO: verify incoming redirect url is valid.

	
	#echo "redirect_to_ci_url=$redirect_to_ci_url"
	#echo "commit_build_status=$commit_build_status"
	
	# Create message in JSON format
	JSON_FMT='{"state":"%s","description":"%s","target_url":"%s"}\n'
	# shellcheck disable=SC2059
	json_string=$(printf "$JSON_FMT" "$commit_build_status" "$commit_build_status" "$redirect_to_ci_url")
	#echo "json_string=$json_string"
	
	# Set the build status
	setting_output=$(curl -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" --request POST --data "$json_string" https://api.github.com/repos/"$github_username"/"$github_repo_name"/statuses/"$github_commit_sha")
	
	# Check if output is valid
	#echo "setting_output=$setting_output"
	if [ "$(lines_contain_string '"message": "Bad credentials"' "${setting_output}")" == "FOUND" ]; then
		# TODO: specify which checkboxes in the `repository` checkbox are required.
		echo "ERROR, the github personal access token is not valid. Please make a new one. See https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token and ensure you tick. $setting_output"
		exit 117
	elif [ "$(lines_contain_string '"documentation_url": "https://docs.github.com/rest' "${setting_output}")" == "FOUND" ]; then
		echo "ERROR: $setting_output"
		exit 118
	fi
	
	# Verify the build status is set correctly
	getting_output=$(GET https://api.github.com/repos/"$github_username"/"$github_repo_name"/commits/"$github_commit_sha"/statuses)
	expected_url="\"url\":\"https://api.github.com/repos/$github_username/$github_repo_name/statuses/$github_commit_sha\","
	expected_state="\"state\":\"$commit_build_status\","
	if [ "$(lines_contain_string "$expected_url" "${getting_output}")" == "NOTFOUND" ]; then
		echo "FALSE"
	elif [ "$(lines_contain_string "$expected_state" "${getting_output}")" == "NOTFOUND" ]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi
}

# Run with:
# bash -c "source src/import.sh && copy_commit_build_status_to_github_status_repo a-t-0 sponsor_example main something failed"
copy_commit_build_status_to_github_status_repo() {
	local github_username="$1"
	local github_repo_name="$2"
	local github_branch_name="$3"
	local github_commit_sha="$4"
	local status="$5"
	
	# Verify the mirror location exists
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_dir_exists "$MIRROR_LOCATION"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	#has_access="$(check_ssh_access_to_repo "$github_username" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
	
	# 8. Clone the GitHub build statusses repository.
	download_and_overwrite_repository_using_ssh "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	sleep 2
	
	# 9. Verify the Build status repository is cloned.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	# 10. Copy the GitLab CI Build status icon to the build status repository.
	# Create a folder of the repository on which a CI has been ran, inside the GitHub build status website repository, if it does not exist yet
	# Also add a folder for the branch(es) of that GitLab CI repository, in that respective folder.
	
	mkdir -p "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name"
	
	
	# TODO: 11. Include the build status and link to the GitHub commit in the repository in the SVG file.
	# Create build status icon
	if [  "$status" == "pending" ] || [ "$status" == "running" ]; then
		echo "ERROR, a pending or running build status should not reach this method."
		exit 121
	elif [  "$status" == "success" ]; then
		cp "src/svgs/passed.svg" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name""/build_status.svg"
	elif [  "$status" == "failure" ]; then
		cp "src/svgs/failed.svg" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name""/build_status.svg"
	elif [  "$status" == "error" ]; then
		cp "src/svgs/error.svg" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name""/build_status.svg"
	elif [  "$status" == "unknown" ]; then
		cp "src/svgs/unknown.svg" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name""/build_status.svg"
	fi
	
	# Assert svg file is created correctly
	manual_assert_equal "$(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name""/build_status.svg")" "FOUND"
	
	# Explicitly store build status per commit per branch per repo.
	echo "$status" > "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name""/$github_commit_sha.txt"
	
	# manual_assert GitHub commit build status txt file is created correctly
	manual_assert_equal "$(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name""/$github_commit_sha.txt")" "FOUND"
	
	# manual_assert GitHub commit build status txt file contains the right data.
	manual_assert_equal "$(cat "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$github_repo_name/$github_branch_name""/$github_commit_sha.txt")" "$status"
}

push_commit_build_status_in_github_status_repo_to_github() {
	local github_username="$1"
	
	# Verify the Build status repository is cloned.
	repo_was_cloned=$(verify_github_repository_is_cloned "$GITHUB_STATUS_WEBSITE_GLOBAL" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL")
	manual_assert_equal "$repo_was_cloned" "FOUND"
	
	# 12. Verify there have been changes made. Only push if changes are added."
	if [[ "$(git_has_changes "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL")" == "FOUND" ]]; then
		commit_changes "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL" "New_build_status."
		
		# Verify ssh-access
		#has_access="$(check_ssh_access_to_repo "$github_username" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
		
		# 13. Push the changes to the GitHub build status repository.
		#push_to_github_repository "$github_username" "$has_access" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
		push_to_github_repository_with_ssh "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	fi
	
	# TODO 14. Verify the changes are pushed to the GitHub build status repository.
}