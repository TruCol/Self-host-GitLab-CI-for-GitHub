#!/bin/bash



# Hardcoded data:

# Get GitHub username.
github_username=$1

# Get GitHub repository name.
github_repo=$2



verbose=$3

# get GitHub personal access token or verify ssh access to support private repositories.
github_personal_access_code=$(echo "$GITHUB_PERSONAL_ACCESS_TOKEN" | tr -d '\r')

# Get GitLab username.
gitlab_username=$(echo "$gitlab_server_account" | tr -d '\r')

# Get GitLab user password.
gitlab_server_password=$(echo "$gitlab_server_password" | tr -d '\r')

# Get GitLab personal access token from hardcoded file.
gitlab_personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN" | tr -d '\r')

# Specify GitLab mirror repository name.
gitlab_repo="$github_repo"

if [ "$verbose" == "TRUE" ]; then
	echo "MIRROR_LOCATION=$MIRROR_LOCATION"
	echo "github_username=$github_username"
	echo "github_repo=$github_repo"
	echo "github_personal_access_code=$github_personal_access_code"
	echo "gitlab_username=$gitlab_username"
	echo "gitlab_server_password=$gitlab_server_password"
	echo "gitlab_personal_access_token=$gitlab_personal_access_token"
	echo "gitlab_repo=$gitlab_repo"
fi

# run with:
# source src/import.sh src/run_ci_on_github_repo.sh && create_and_run_ci_job "a-t-0" "sponsor_example"
#source src/run_ci_job.sh && receipe
create_and_run_ci_job_on_github_repo() {
	github_username="$1"
	github_repo_name="$2"
	
	# 0. Check access to GitHub repository
	
	# 1. Clone the GitHub repo.
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	###assert_not_equal "$MIRROR_LOCATION" ""
	###assert_file_not_exist "$MIRROR_LOCATION"
	###assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	###assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	# TODO: replace asserts with functions
	###assert_not_equal "$MIRROR_LOCATION" ""
	###assert_file_exist "$MIRROR_LOCATION"
	###assert_file_exist "$MIRROR_LOCATION/GitHub"
	###assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$github_username" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$github_username" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	
	
	# 2. Verify the GitHub repo is cloned.
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	
	
}

loop_over_github_branches() {
	github_username="$1"
	github_repo_name="$2"
	
	# 2. Verify the GitHub repo is cloned.
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"

	# 3. Get the GitHub branches
	get_git_branches github_branches "GitHub" "$github_repo_name"      # call function to populate the array
	declare -p github_branches
	
	#assert_equal ""${github_branches[0]}"" "attack_in_new_file"
	#assert_equal ""${github_branches[1]}"" "attack_unit_test"
	#assert_equal ""${github_branches[2]}"" "main"
	#assert_equal ""${github_branches[3]}"" "no_attack_in_filecontent"
	#assert_equal ""${github_branches[4]}"" "no_attack_in_new_file"
	
	# 4. Loop over the GitHub branches by checking each branch out.
	for i in "${!github_branches[@]}"; do
		echo "${github_branches[i]}"
		
		# Check if branch is found in local GitHub repo.
		actual_result="$(checkout_branch_in_github_repo $github_repo_name ${github_branches[i]} "GitHub")"
		assert_success
		
		# Get SHA of commit of local GitHub branch.
		commit=$(get_current_github_branch_commit $github_repo_name ${github_branches[i]} "GitHub")
	
		# For each branch, assert the correct commit is returned.
		if [ $i -eq 0 ]; then
			assert_equal ""${github_branches[$i]}"" "attack_in_new_file"
			assert_equal ""$commit"" "00c16a620847faae3a6b7b1dcc5d4d458f2c7986"
		elif [ $i -eq 1 ]; then
			assert_equal ""${github_branches[$i]}"" "attack_unit_test"
			assert_equal ""$commit"" "2bd88d1551a835b12c31d8a392f2ee0bf0977c65"
		elif [ $i -eq 2 ]; then
			assert_equal ""${github_branches[$i]}"" "main"
			assert_equal ""$commit"" "85ad4b39fe9c9af893b4d7b35a76a595a8e680d5"
		elif [ $i -eq 3 ]; then
			assert_equal ""${github_branches[$i]}"" "no_attack_in_filecontent"
			assert_equal ""$commit"" "4d78ba9b04d26cfb95296c0cee0a7cc6a3897d44"
		elif [ $i -eq 4 ]; then
			assert_equal ""${github_branches[$i]}"" "no_attack_in_new_file"
			assert_equal ""$commit"" "d8e518b97cc1a528f49a01081890931403361561"
		else
			assert_equal "" "Another branch was found that was not expected."
		fi
		
		# 5. If the branch contains a gitlab yaml file then
		# TODO: change to return a list of branches that contain GitLab 
		# yaml files, such that this function can get tested, instead 
		# of diving a method deeper.
		branch_contains_yaml="$(verify_github_branch_contains_gitlab_yaml $github_repo_name "${github_branches[i]}" "GitHub")"
		if [[ "$branch_contains_yaml" == "FOUND" ]]; then
			copy_github_branches_with_yaml_to_gitlab_repo "$github_username" "$github_repo_name" "${github_branches[i]}" "$commit"
		fi
	done
	
}


copy_github_branches_with_yaml_to_gitlab_repo() {
	github_username="$1"
	github_repo_name="$2"
	github_branch_name="$3"
	github_commit_sha="$4"
	
	# Assume identical repository and branch names:
	gitlab_repo_name="$github_repo_name"
	gitlab_branch_name="$github_branch_name"
	
	# Get GitLab username.
	gitlab_username=$(echo "$gitlab_server_account" | tr -d '\r')
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(verify_github_branch_contains_gitlab_yaml $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "FOUND"
	
	# 5.1 Create the empty GitLab repo.
	# Create the empty GitLab repository (deletes any existing GitLab repos with same name).
	create_empty_repository_v0 "$gitlab_repo_name" "$gitlab_username"
	
	# 5.2 Clone the empty Gitlab repo from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$gitlab_server_account" "$gitlab_repo_name"
	
	# 5.3 Check if the GitLab branch exists, if not, create it.
	# 5.4 Check out the GitLab branch
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name "GitLab")"
	assert_success
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	actual_result="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	assert_equal "$actual_result" "$gitlab_branch_name"
	
	# 5.5 TODO: Check whether the GitLab branch already contains this
	# GitHub commit sha in its commit messages. (skip branch if yes)
	# 5.6 TODO: Verify whether the build status of this repository, branch, commit is not yet
	# known. (skip branch if yes)
	
	# 5.7 Copy the files from the GitHub branch into the GitLab branch.
	result="$(copy_files_from_github_to_gitlab_branch $github_repo_name $github_branch_name $gitlab_repo_name $gitlab_branch_name)"
	last_line_result=$(get_last_line_of_set_of_lines "\${result}")
	assert_equal "$last_line_result" "IDENTICAL"
	
	
	# 5.8 Commit the changes to GitLab.
	assert_not_equal "" "$github_commit_sha"
	commit_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
	# TODO: verify the changes are committed correctly
	
	# 5.8. Push the results to GitLab, with the commit message of the GitHub commit sha.
	# Perform the Push function.
	push_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
	# TODO: verify the changes are pushed correctly
}

# TODO: 5.9 Verify the CI is running for this commit.

# 6. Get the GitLab CI build status for that GitLab commit.
get_gitlab_ci_build_status() {
	github_repo_name="$1"
	github_branch_name="$2"
	gitlab_commit_sha="$3"
	count="$4"
	
	# specify timeout counter
	if [[ "$count" == "" ]]; then
		count=0
	fi

	# Assume identical repository and branch names:
	gitlab_repo_name="$github_repo_name"
	gitlab_branch_name="$github_branch_name"
	
	# Get GitLab username.
	gitlab_username=$(echo "$gitlab_server_account" | tr -d '\r')

	
	
	# curl --header "PRIVATE-TOKEN: <your_access_token>" "http://127.0.0.1/api/v4/projects/1/pipelines"
	pipelines=$(curl --header "PRIVATE-TOKEN: $gitlab_personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$gitlab_repo_name/pipelines")
	#echo "pipelines=$pipelines"
	
	# get build status from pipelines
	job=$(echo $pipelines | jq -r 'map(select(.sha == "'"$gitlab_commit_sha"'"))')
	#echo "job=$job"
	status=$(echo "$(echo $job | jq ".[].status")" | tr -d '"')	
	
	
	#while [[ "$status" == "" ] || [ "$status" == "pending" ] || [ "$status" == "paused" ]]
	while [[ "$status" == "" || "$status" == "pending" || "$status" == "paused" ]]; do
		
		# 5.10 (Sub-optimal) Wait until the GitLab CI is done with the branch. (Set a timeout limit of 8x10 seconds).
		sleep 10
		if [[ "$i" -gt 8 ]]; then
			echo "Waiting on the GitLab CI build status took too long. Raising error. The last known status was:$status"
			exit 111
		else
			# Perform recursive call to this function to retry getting build status.
			new_status=$(get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha" "$count")
		fi
	done
	# If the right status was found without entering the while loop, the new_status will be void.
	# That implies the status still needs to be echo'd. If the new_status was found in the recursive
	# call, then it has already been echoed, hence no more echo would be needed if new_status is not "".
	if [[ "$new_status" == "" ]]; then
		echo "$status"
	fi
	
	# TODO: verify the job status is within acceptable values, e.g. succes, failed, pauzed etc. Throw error otherwise.
	# Allowed values:
	###failure
	###success
	###error
	###pending
}

# 7. Once the build status is found, use github personal access token to
# set the build status in the GitHub commit.
set_build_status_of_github_commit() {
	github_username="$1"
	github_repo_name="$2"
	github_commit_sha="$3"
	github_personal_access_code="$4"
	gitlab_website_url="$5"
	commit_build_status="$6"
	
	# Check if arguments are valid.
	if [[ "$github_commit_sha" == "" ]]; then
		echo "ERROR, the github commit sha is empty, whereas it shouldn't be."
		exit 112
	elif [[ "$github_personal_access_code" == "" ]]; then
		echo "ERROR, the github personal access token is empty, whereas it shouldn't be."
		exit 113
	elif [[ "$commit_build_status" == "" ]]; then
		echo "ERROR, the GitLab build status is empty, whereas it shouldn't be."
		exit 114
	elif [[ "$gitlab_website_url" == "" ]]; then
		echo "ERROR, the GitLab server website url is empty, whereas it shouldn't be."
		exit 115
	fi
	
	echo "gitlab_website_url=$gitlab_website_url"
	echo "commit_build_status=$commit_build_status"
	
	# Create message in JSON format
	JSON_FMT='{"state":"%s","description":"%s","target_url":"%s"}\n'
	json_string=$(printf "$JSON_FMT" "$commit_build_status" "$commit_build_status" "$gitlab_website_url")
	echo "json_string=$json_string"
	
	# Set the build status
	setting_output=$(curl -H "Authorization: token $github_personal_access_code" --request POST --data "$json_string" https://api.github.com/repos/$github_username/$github_repo_name/statuses/$github_commit_sha)
	
	# Check if output is valid
	echo "setting_output=$setting_output"
	if [ "$(lines_contain_string '"message": "Bad credentials"' "\${setting_output}")" == "FOUND" ]; then
		# TODO: specify which checkboxes in the `repository` checkbox are required.
		echo "ERROR, the github personal access token is not valid. Please make a new one. See https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token and ensure you tick. $setting_output"
		exit 115
	elif [ "$(lines_contain_string '"documentation_url": "https://docs.github.com/rest' "\${setting_output}")" == "FOUND" ]; then
		echo "ERROR: $setting_output"
		read -p "ERROR: $setting_output"
		#exit 116
	fi
	
	# Verify the build status is set correctly
	getting_output=$(GET https://api.github.com/repos/$github_username/$github_repo_name/commits/$github_commit_sha/statuses)
	echo "getting_output=$getting_output"
}

	
	# 8. Clone the GitHub build statusses repository.
	# 9. Verify the Build status repository is cloned.
	# 10. Copy the GitLab CI Build status icon to the build status repository.
	# 11. Include the build status and link to the GitHub commit in the repository.
	# 12. Push the changes to the GitHub build status repository.
	# 13. Verify the changes are pushed to the GitHub build status repository.