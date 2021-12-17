#!/bin/bash



# Hardcoded data:

# Get GitHub username.
github_username=$1

# Get GitHub repository name.
github_repo=$2

# OPTIONAL: get GitHub personal access token or verify ssh access to support private repositories.
github_personal_access_code=$3

verbose=$4

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
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(verify_github_branch_contains_gitlab_yaml $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "FOUND"
	
	# 5.1 Create the empty GitLab repo.
	# 5.2 Clone the empty Gitlab repo git
	# 5.3 Check if the GitLab branch exists, if not, create it.
	# 5.4 Check out the GitLab branch
	# 5.5 Verify whether the GitLab branch already contains this
	# GitHub commit sha in its commit messages.
	# 5.6 Verify whether the build status of this repository, branch, commit is not yet
	# known.
	# 5.7 Copy the files from the GitHub branch into the GitLab branch.
	# 5.8. Push the results to GitLab, with the commit message of the GitHub commit sha.
	# 5.9 (Sub-optimal) Wait until the GitLab CI is done with the branch. (Set a timeout limit of 20 minutes).
	# 6. Get the GitLab CI build status for that GitLab commit.
	# 7. Clone the Build status repository.
	# 8. Verify the Build status repository is cloned.
	# 9. Copy the GitLab CI Build status icon to the build status repository.
	# 10. Include the build status and link to the GitHub commit in the repository.
	# 11. Push the changes to the GitHub build status repository.
	# 12. Verify the changes are pushed to the GitHub build status repository.
}

	#### Checkout GitHub branch, if branch is found in local GitHub repo.
	###actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	###assert_success
	###
	#### Verify the get_current_github_branch function returns the correct branch.
	###actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	###assert_equal "$actual_result" "$github_branch_name"
	###
	#### Check if branch is found in local GitHub repo.
	###actual_result="$(github_branch_exists $github_repo_name $github_branch_name)"
	###last_line=$(get_last_line_of_set_of_lines "\${actual_result}")
	###assert_equal "$last_line" "FOUND"