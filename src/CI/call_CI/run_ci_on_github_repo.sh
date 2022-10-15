#!/bin/bash


#######################################
# Make a liThis branch is 45 commits ahead, 3 commits behind v-bosch:main.st of the repositories in the GitHub repository.
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
# Run with: 
# bash -c "source src/import.sh src/helper/GitHub/helper_github_status.sh && initialise_github_repositories_array "hiveminds"
# bash -c "source src/import.sh src/helper/GitHub/helper_github_status.sh && initialise_github_repositories_array "a-t-0"
# bash -c "source src/import.sh src/helper/GitHub/helper_github_status.sh && initialise_github_repositories_array "trucol"
initialise_github_repositories_array() {
	local github_organisation_or_username="$1"
	get_org_repos github_repositories "$github_organisation_or_username" # call function to populate the array
	declare -p github_repositories
}

# source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_all_repositories_of_user "hiveminds"
# source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_all_repositories_of_user "a-t-0"
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_all_repositories_of_user hiveminds"
run_ci_on_all_repositories_of_user(){
	local github_organisation_or_username="$1"
	
	# Get the GitHub build status repository.
	get_build_status_repository_from_github

	initialise_github_repositories_array "$github_organisation_or_username"
	echo "github_repositories=${github_repositories[@]}"

	for github_repository in "${github_repositories[@]}"; do
		echo "$github_repository"

		# TODO: redo with timeout.
		run_ci_on_github_repo "$github_organisation_or_username" "$github_repository" "$github_organisation_or_username"
	done

	# push build status icons to GitHub build status repository.
	push_commit_build_status_in_github_status_repo_to_github "$github_username"
}

# run with:
# First:
# bash -c "source src/import.sh helper_github_modify.sh && get_build_status_repository_from_github"
# Then:
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_github_repo a-t-0 sponsor_example a-t-0"
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_github_repo hiveminds sponsor_example hiveminds"
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_github_repo hiveminds renamed_test_repo hiveminds"
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_github_repo trucol trucol trucol"
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_github_repo trucol checkstyle-for-bash trucol"
run_ci_on_github_repo() {
	github_username="$1"
	github_repo_name="$2"
	local organisation="$3"
	
	# 9. Verify the Build status repository is cloned.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"

	# TODO: change this method to download with https?
	# Download the GitHub repo on which to run the GitLab CI:
	printf "\n\n0. Download the GitHub repository on which to run GitLab CI."
	download_github_repo_on_which_to_run_ci "$github_username" "$github_repo_name"

	# Remove the GitLab repository. # TODO: move this to each branch
	# Similarly for each commit
	printf "\n1. Download the GitHub repository on which to run GitLab CI."
	remove_the_gitlab_repository_on_which_ci_is_ran

	# TODO: write test to verify whether the build status can be pushed to a branch. (access wise).
	# TODO: Store log file output if a repo (and/or branch) have been skipped.
	# TODO: In that log file, inlcude: time, which user, which repo, which branch, why.
	printf "\n2. Exporting GitLab CI result back to a GitHub repository."
	copy_github_branches_with_yaml_to_gitlab_repo "$github_username" "$github_repo_name" "$organisation"
	printf "\n4. Done with CI."

}


#######################################
# This downloads a GitHub repository from a GitHub user over SSH if it is
# possible, otherwise over https. For https it assumes the repo is public.
# Local variables:
#  github_username
#  github_repo_name
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  github_username
#  github_repo_name
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  Nothing if the GitHub repo was downloaded correctly.
#######################################
# run with:
# source src/import.sh && download_github_repo_on_which_to_run_ci "a-t-0" "sponsor_example"
download_github_repo_on_which_to_run_ci() {
	local github_username="$1"
	local github_repo_name="$2"
	
	# Create mirror directories
	create_mirror_directories
	manual_assert_not_equal "$MIRROR_LOCATION" ""
	manual_assert_dir_exists "$MIRROR_LOCATION"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_quick_ssh_access="$(check_quick_ssh_access_to_repo "$github_username" "$github_repo_name")"

	# Clone GitHub repo at start of test.
	clone_github_repository "$github_username" "$github_repo_name" "$has_quick_ssh_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	
	# 2. Verify the GitHub repo is cloned.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
}



#######################################
# 0. First verifies that the GitHub repository on which the CI is ran, exists.
# 1. Then loops over the branches of that repository, and checkes out the 
# latest commit of each branch.
# 2. Then it checks whether the commit contains a GitLab CI yaml. If it does:
# 2.1 It checks whether the commit sha already has a GitLab build status.
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
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && copy_github_branches_with_yaml_to_gitlab_repo a-t-0 sponsor_example"
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && copy_github_branches_with_yaml_to_gitlab_repo hiveminds renamed_test_repo"
copy_github_branches_with_yaml_to_gitlab_repo() {
	local github_username="$1"
	local github_repo_name="$2"
	local organisation="$3"
	
	# Verify GitHub repository on which the CI is ran, exists locally.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"

	# 3. Get the GitHub branches
	printf "\n3. Get the branches of the GitHub repository on which to run GitLab CI.\n"
	printf "The first letter of each branch of the GitHub repo is:\n"
	get_git_branches github_branches "GitHub" "$github_repo_name"      # call function to populate the array
	printf "\n"
	
	# shellcheck disable=SC2154
	declare -p github_branches
	#manual_assert_equal ""${github_branches[0]}"" "attack_in_new_file"
	#manual_assert_equal ""${github_branches[1]}"" "attack_unit_test"
	#manual_assert_equal ""${github_branches[2]}"" "main"
	#manual_assert_equal ""${github_branches[3]}"" "no_attack_in_filecontent"
	#manual_assert_equal ""${github_branches[4]}"" "no_attack_in_new_file"
	
	# 4. Loop over the GitHub branches by checking each branch out.
	printf "\n4. Loop over each GitHub branch and run the GitLab CI on it."
	for i in "${!github_branches[@]}"; do
		printf "\n4.$i next branch: ${github_branches[i]}"
		
		# Check if branch is found in local GitHub repo.
		printf "\n4.$i.1 Checkout a local GitHub branch.\n"
		local checkout_output="$(checkout_branch_in_github_repo "$github_repo_name" "${github_branches[i]}" "GitHub")"
		# TODO: write some test to verify this.
		
		# Get SHA of the current commit of local GitHub branch.
		local current_branch_github_commit_sha=$(get_current_github_branch_commit "$github_repo_name" "${github_branches[i]}" "GitHub")
		
		if [ "$current_branch_github_commit_sha" == "" ]; then
			echo "ERROR, github_repo_name=$github_repo_name, branch=${github_branches[i]} in folder GitHub, the commit is empty:$current_branch_github_commit_sha"
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
			commit_filename="$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$organisation/$github_repo_name/${github_branches[i]}/$current_branch_github_commit_sha.txt"
			exists="$(file_exists $commit_filename)"
			
			if [ "$(file_exists $commit_filename)" == "NOTFOUND" ]; then
				printf "\n4.$i.2 Commit file: $commit_filename"
				printf "has GitLab yml, no build status yet. Running GitLab CI on:$github_repo_name-${github_branches[i]}"
				
				create_empty_build_status_txt "$github_repo_name" "${github_branches[i]}" "$current_branch_github_commit_sha" "$organisation"

				copy_github_branch_with_yaml_to_gitlab_repo "$github_username" "$github_repo_name" "${github_branches[i]}" "$current_branch_github_commit_sha" "$organisation"
				printf "\n4.$i.3 Completed running GitLab CI on repo."

				# 4.b Export the evaluated GitHub commit SHA to GitHub build status repo.
				add_commit_sha_to_evaluated_list "$current_branch_github_commit_sha" "$EVALUATED_COMMITS_WITH_CI_LIST_FILENAME"

				# TODO: copy build status to build_status txt.
			else
				printf "\n4.$i.4 The following commit already has GitLab build status in GitHub:\n$github_repo_name/${github_branches[i]}/$current_branch_github_commit_sha "
			fi

			# 4.b Export the evaluated GitHub commit SHA to evaluated_commits 
			# list in the GitHub build status repo.
			add_commit_sha_to_evaluated_list "$current_branch_github_commit_sha" "$EVALUATED_COMMITS_LIST_FILENAME"
		fi
	done
		

	## 4.c Push the evaluated commit to the GitHub build status repo.
	# TODO determine whether the push should be completed.
	push_commit_build_status_in_github_status_repo_to_github "$github_username"
	printf "DONE"
}


# This copies a single branch, the other, similar function above, copies all 
# branches.
copy_github_branch_with_yaml_to_gitlab_repo() {
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
	
	
	# Verify the get_current_github_branch function returns the correct branch.
	printf "\n4.x.6.1 Verify if the local GitHub branch returns the correct branch."
	actual_result="$(get_current_github_branch "$github_repo_name" "$github_branch_name" "GitHub")"
	manual_assert_equal "$actual_result" "$github_branch_name"
	
	# Checkout branch, if branch is found in local GitHub repo.
	printf "\n4.x.6.2 Verify if the local GitHub branch indeed contains a GitLab yaml."
	actual_result="$(verify_github_branch_contains_gitlab_yaml "$github_repo_name" "$github_branch_name" "GitHub")"
	manual_assert_equal "$actual_result" "FOUND"
	
	# 5.1 Create the empty GitLab repo.
	# Create the empty GitLab repository (deletes any existing GitLab repos with same name).
	printf "\n4.x.6.3 Create a new empty repository in GitLab."
	# TODO: determine what happens if it already exists in GitLab
	create_empty_repository_v0 "$gitlab_repo_name" "$GITLAB_SERVER_ACCOUNT_GLOBAL"
	
	# 5.2 Clone the empty Gitlab repo from the GitLab server
	printf "\n4.x.6.3 Clone the new empty GitLab repository."
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# 5.3 Check if the GitLab branch exists, if not, create it.
	# 5.4 Check out the GitLab branch
	# Checkout branch, if branch is found in local Gitlab repo.
	printf "\n4.x.6.4 Checkout the (new) GitHub branch in the local GitLab repository."
	actual_result="$(checkout_branch_in_gitlab_repo "$gitlab_repo_name" "$gitlab_branch_name" "GitLab")"
		
	# Verify the get_current_gitlab_branch function returns the correct branch.
	# shellcheck disable=SC2154
	printf "\n4.x.6.5 Verify if the local GitLab branch returns the correct branch."
	actual_result="$(get_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name" "GitLab")"
	manual_assert_equal "$actual_result" "$gitlab_branch_name"
		
	# 5.5 TODO: Check whether the GitLab branch already contains this
	# GitHub commit sha in its commit messages. (skip branch if yes)
	# 5.6 TODO: Verify whether the build status of this repository, branch, commit is not yet
	# known. (skip branch if yes)
	
	# 5.7 Copy the files from the GitHub branch into the GitLab branch.
	printf "\n4.x.6.6 Verify if the content between the local GitHub and GitLab branch is identical."
	branch_content_identical_between_github_and_gitlab_output="$(copy_files_from_github_to_gitlab_branch "$github_repo_name" "$github_branch_name" "$gitlab_repo_name" "$gitlab_branch_name")"
	# TODO: change this method to ommit getting last line!
	#printf "RESULTRESULT=$result"
	#last_line_result=$(get_last_line_of_set_of_lines_without_evaluation_of_arg "${result}")
	#manual_assert_equal "$last_line_result" "IDENTICAL"
	branch_content_identical_between_github_and_gitlab=$(assert_ends_in_identical ${branch_content_identical_between_github_and_gitlab_output})
	if [ "$branch_content_identical_between_github_and_gitlab" == "TRUE" ]; then
	
		# 5.8 Commit the changes to GitLab.
		printf "\n4.x.6.7 Commit the content of the GitHub branch, that is copied to the GitLab branch, to GitLab."
		manual_assert_not_equal "" "$github_commit_sha"
		commit_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
		# TODO: verify the changes are committed correctly

		# 5.8. Push the results to GitLab, with the commit message of the GitHub commit sha.
		# Perform the Push function.
		printf "\n4.x.6.8 Push the commit to GitLab."
		
		push_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
		# TODO: verify the changes are pushed correctly
		printf "\n4.x.6.9 DONE PUSHING, getting commit sha"

		# Get last commit of GitLab repo.
		printf "\n4.x.6.10 Push the commit to GitLab."
		gitlab_commit_sha=$(get_commit_sha_of_branch "$github_branch_name" "$github_repo_name" "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL")
		gitlab_commit_sha=$(echo "$gitlab_commit_sha" | tr -d '"') # removes double quotes at start and end.
		#echo "gitlab_commit_sha=$gitlab_commit_sha"

		# 6. Get the GitLab CI build status for that GitLab commit.
		#read -p "STARTING MANAGE"
		#build_status="$(manage_get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")"
		
		# Remove build status output file if it exists.
		#delete_file_if_it_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH
		# assert status file is deleted
		#manual_assert_file_does_not_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH

		manage_get_gitlab_ci_build_status $github_repo_name $github_branch_name $gitlab_commit_sha
		#read -p "Got Build status, check what it is in file. MANAGE"
		if [ "$(file_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH)" == "FOUND" ]; then
		
			# yes: read status into variable
			local build_status=$(cat $TMP_GITLAB_BUILD_STATUS_FILEPATH)
			delete_file_if_it_exists $TMP_GITLAB_BUILD_STATUS_FILEPATH
		else
			echo "ERROR, the $TMP_GITLAB_BUILD_STATUS_FILEPATH file is neither found nor not found."
			exit 4
		fi
		
		#read -p "build_status=$build_status.end"
		printf "\n4.x.6.11 DONE MANAGE build_status=$build_status"
		#last_line_gitlab_ci_build_status=$(get_last_line_of_set_of_lines_without_evaluation_of_arg "${build_status}")
		#echo "last_line_gitlab_ci_build_status=$last_line_gitlab_ci_build_status"



		# 7. Once the build status is found, use github personal access token to
		# set the build status in the GitHub commit.
		printf "\n4.x.6.12 \n\n\n Set the build status of the GitHub commit using GitHub personal access token."
		# TODO: ensure personal access token is created automatically to set build status.
		#output=$(set_build_status_of_github_commit_using_github_pat "$github_username" "$github_repo_name" "$github_commit_sha" "$gitlab_website_url" "$last_line_gitlab_ci_build_status")
		output=$(set_build_status_of_github_commit_using_github_pat "$github_username" "$github_repo_name" "$github_commit_sha" "$gitlab_website_url" "$build_status")
		printf "\n4.x.6.13 output=$output"

		# 8. Copy the commit build status from GitLab into the GitHub build status repo.
		printf "\n4.x.6.14 copy_commit_build_status_to_github_status_repot"
		printf  "github_username=$github_username and github_repo_name=$github_repo_name and github_branch_name=$github_branch_name and github_commit_sha=$github_commit_sha and build_status=$build_status and organisation=$organisation end."
		copy_commit_build_status_to_github_status_repo "$github_username" "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$build_status" "$organisation"

		## 9. Push the commit build status to the GitHub build status repo. 
		#printf "\n4.x.6.16 push_commit_build_status_in_github_status_repo_to_github"
		#push_commit_build_status_in_github_status_repo_to_github "$github_username"
		
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
	
	# Set default built status to unknown for starters
	echo "unknown" > "$TMP_GITLAB_BUILD_STATUS_FILEPATH"

	# Get raw build status from GitLab
	# TODO: THIS METHOD HANGS!
	parsed_github_build_status="$(rebuild_get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")"
	#parsed_github_build_status=$(some_func_to_get_build_status_response)
	echo "$parsed_github_build_status" > "$TMP_GITLAB_BUILD_STATUS_FILEPATH"
	#printf "\n\n initiate while loop that checks if github build status is desirable. "
	sleep 20
	#read -p "parsed_github_build_status=$parsed_github_build_status.end"
	# wait 11 * 10 = 110 seconds to get build satus, otherwise it will be stored at pending. 
	#for i in {0..$WAIT_ON_CI_TO_FINISH..1}; do
	#for ((i=1;i<=WAIT_ON_CI_TO_FINISH;i++)); do
	END=$WAIT_ON_CI_TO_FINISH
	for ((i=1;i<=END;i++)); do
		# Pause for 10 seconds before trying to get the build status again.
		sleep 10

		# Get updated parsed_github_build_status from GitLab. 
		parsed_github_build_status="$(rebuild_get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")"
		if [ "$parsed_github_build_status" != "" ]; then
			echo "$parsed_github_build_status" > "$TMP_GITLAB_BUILD_STATUS_FILEPATH"
		fi

		# If the code is already done, break for loop and move on.
		if [ "$(is_desirable_github_build_status_excluding_pending $parsed_github_build_status)" == "FOUND" ]; then
			break
		fi
		echo "in loop parsed_github_build_status=$parsed_github_build_status"
	done
}

some_func_to_get_build_status_response() {
	printf "IN OTHER FUNCTION!"
	echo "hi"
}

rebuild_get_gitlab_ci_build_status() {
	local github_repo_name="$1"
	local github_branch_name="$2"
	local gitlab_commit_sha="$3"

	# Assume identical repository and branch names:
	local gitlab_repo_name="$github_repo_name"
	local gitlab_branch_name="$github_branch_name"

	
	#printf "\n\n getting pipelines via curl and gitlab pac. "
	# curl --header "PRIVATE-TOKEN: <your_access_token>" "http://127.0.0.1/api/v4/projects/1/pipelines"
	pipelines=$(curl --header "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" "http://127.0.0.1/api/v4/projects/$GITLAB_SERVER_ACCOUNT_GLOBAL%2F$gitlab_repo_name/pipelines")
	#printf "pipelines=$pipelines"
	# get build status from pipelines
	#printf "\n\n get job from pipeline json using jq "
	job=$(echo "$pipelines" | jq -r 'map(select(.sha == "'"$gitlab_commit_sha"'"))')
	#printf "job=$job"
	#gitlab_ci_status="$(echo "$job" | jq ".[].status")" | tr -d '"')
	#printf "\n\n get gitlab_ci_status from job json from jq.  "
	gitlab_ci_status=$(echo "$(echo $job | jq ".[].status")" | tr -d '"')
	#printf "gitlab_ci_status=$gitlab_ci_status"
	#printf "\n\n get parsed github status unparsed gitlab_ci_status=$gitlab_ci_status.  "
	parsed_github_status="$(parse_gitlab_ci_status_to_github_build_status "$gitlab_ci_status")"
	#printf "\n\n get parsed_github_status $parsed_github_status.  "
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

	
	#echo "github_username=$github_username"
	#echo "github_repo_name=$github_repo_name"
	#echo "github_commit_sha=$github_commit_sha"
	#echo "commit_build_status=$commit_build_status"
	#echo "redirect_to_ci_url=$redirect_to_ci_url"
	
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
	# TODO: replace second $commit_build_status with the actual build output or error message.
	# shellcheck disable=SC2059
	json_string=$(printf "$JSON_FMT" "$commit_build_status" "$commit_build_status" "$redirect_to_ci_url")
	
	# Set the build status
	setting_output=$(curl -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" --request POST --data "$json_string" https://api.github.com/repos/"$github_username"/"$github_repo_name"/statuses/"$github_commit_sha")
	
	# Check if output is valid
	#echo "setting_output=$setting_output"
	if [ "$(lines_contain_string '"message": "Bad credentials"' "${setting_output}")" == "FOUND" ]; then
		# Remove the current GitHub personal access token from the $PERSONAL_CREDENTIALS_PATH file.
		remove_line_from_file_if_contains_substring "$PERSONAL_CREDENTIALS_PATH" "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL"

		## Assert $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL is not in personal_creds
		if [ "$(file_contains_string "GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$PERSONAL_CREDENTIALS_PATH")" == "FOUND" ]; then
			echo "Error, the GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL is still in the PERSONAL_CREDENTIALS_PATH file."
			exit 116
		fi

		echo "ERROR, the github personal access token is not valid. Please make a new one. See https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token and ensure you tick. $setting_output"
		exit 117
	elif [ "$(lines_contain_string '"documentation_url": "https://docs.github.com/rest' "${setting_output}")" == "FOUND" ]; then
		echo "ERROR: $setting_output"
		exit 118
	fi
	
	# Verify the build status is set correctly
	getting_output_json=$(GET https://api.github.com/repos/"$github_username"/"$github_repo_name"/commits/"$github_commit_sha"/statuses)
	urls_in_json="$(echo "${getting_output_json[0]}" | jq ".[].url")"
	
	expected_url="https://api.github.com/repos/$github_username/$github_repo_name/statuses/$github_commit_sha"
	expected_state="\"state\":\"$commit_build_status\","
	
	
	found_urls="$(string_in_lines "$expected_url" "${urls_in_json}")"
	found_state="$(string_in_lines "$expected_state" "${getting_output_json}")"

	if [ "$found_urls" == "NOTFOUND" ]; then
		# shellcheck disable=SC2059
		printf "Error, the status of the repo did not contain:$expected_url \n because the getting output was: $getting_output"
		exit 119
	elif [ "$found_state" == "NOTFOUND" ]; then
		echo "Error, the status of the repo did not contain:$expected_state"
		exit 120
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
	local organisation="$6"
	local ran_per_commit="$7"

	# 9. Verify the Build status repository is cloned.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	
	# Check to see if the commit that is evaluated, is the latest commit of the branch.
	# Such that the build icon can be exported if it is.
	head_commit_sha=$(locally_get_head_commit_sha_of_branch "$github_repo_name" "$github_branch_name")
	# read -p "head_commit_sha=$head_commit_sha"
	# read -p "github_commit_sha=$github_commit_sha"
	# read -p "status=$status.end"


	if [ "$github_commit_sha" == "$head_commit_sha" ]; then
		build_status_icon_output_dir="$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$organisation/$github_repo_name/$github_branch_name"
		mkdir -p "$build_status_icon_output_dir"

	
		# TODO: 11. Include the build status and link to the GitHub commit in the repository in the SVG file.

		# When the code is ran per commit, the old commit build statuses would 
		# overwrite the latest build status icons, so only export the build status
		# icon when this function is called from run_ci_on_github_repo.sh.
		#if [ "$ran_per_commit" != "FALSE" ]; then
		if [  "$status" == "success" ]; then
			cp "src/svgs/passed.svg" "$build_status_icon_output_dir""/build_status.svg"
		elif [  "$status" == "failure" ]; then
			cp "src/svgs/failed.svg" "$build_status_icon_output_dir""/build_status.svg"
		elif [  "$status" == "error" ]; then
			cp "src/svgs/error.svg" "$build_status_icon_output_dir""/build_status.svg"
		elif [  "$status" == "unknown" ]; then
			cp "src/svgs/unknown.svg" "$build_status_icon_output_dir""/build_status.svg"
		# TODO: change to pending badge.
		elif [  "$status" == "pending" ]; then
			cp "src/svgs/unknown.svg" "$build_status_icon_output_dir""/build_status.svg"
		fi

		# Assert svg file is created correctly
		manual_assert_equal "$(file_exists "$build_status_icon_output_dir""/build_status.svg")" "FOUND"
		#fi
	else
		echo "The head github_commit_sha=$github_commit_sha does not equal: head_commit_sha=$head_commit_sha"
	fi


	# Explicitly store build status per commit per branch per repo.
	echo "$status" > "$build_status_icon_output_dir""/$github_commit_sha.txt"

	# manual_assert GitHub commit build status txt file is created correctly
	manual_assert_equal "$(file_exists "$build_status_icon_output_dir""/$github_commit_sha.txt")" "FOUND"

	# manual_assert GitHub commit build status txt file contains the right data.
	manual_assert_equal "$(cat "$build_status_icon_output_dir""/$github_commit_sha.txt")" "$status"
	
}

# bash -c "source src/import.sh && push_commit_build_status_in_github_status_repo_to_github a-t-0"
push_commit_build_status_in_github_status_repo_to_github() {
	
	# Verify the Build status repository is cloned.
	printf "\n Cloning $GITHUB_STATUS_WEBSITE_GLOBAL repo"
	repo_was_cloned=$(verify_github_repository_is_cloned "$GITHUB_STATUS_WEBSITE_GLOBAL" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL")
	manual_assert_equal "$repo_was_cloned" "FOUND"
	printf "\n $GITHUB_STATUS_WEBSITE_GLOBAL repo was cloned"

	# 12. Verify there have been changes made. Only push if changes are added."
	printf "\n has changes=$(git_has_changes $MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL)"
	if [[ "$(git_has_changes "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL")" == "FOUND" ]]; then
		printf "\n commit_changes from: $MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL."
		commit_changes "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL" "New_build_status."
		
		# Verify ssh-access
		#has_access="$(check_quick_ssh_access_to_repo "$github_username" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
		
		# 13. Push the changes to the GitHub build status repository.
		#push_to_github_repository "$github_username" "$has_access" "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
		printf "\n push_to_github_repository_with_ssh from: $MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL."
		push_to_github_repository_with_ssh "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	fi
	
	printf "DONE PUSHING"
	# TODO 14. Verify the changes are pushed to the GitHub build status repository.
}