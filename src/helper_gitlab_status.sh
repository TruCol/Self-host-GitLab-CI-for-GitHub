#!/bin/bash

# Structure:github_status
# 6.a  Make a list of the branches in the GitHub repository
initialise_github_branches_array() {
	github_repo=$1
	get_git_branches github_branches "GitHub" "$github_repo"      # call function to populate the array
	# shellcheck disable=SC2154
	declare -p github_branches
}

# Structure:gitlab_status
# 6.a  Make a list of the branches in the gitlab repository
initialise_gitlab_branches_array() {
	gitlab_repo=$1
	get_git_branches gitlab_branches "GitLab" "$gitlab_repo"      # call function to populate the array
	# shellcheck disable=SC2154
	declare -p gitlab_branches
}

# Structure:github_status
# 6.b Loop through the GitHub mirror repository branches that are already in GitLab
loop_through_github_branches() {
	for github_branch in "${github_branches[@]}"; do
		echo "$github_branch"
	done
}

# Structure:gitlab_status
get_project_list(){
	# shellcheck disable=2034
	local -n repo_arr="$1"     # use nameref for indirection

    # Get a list of the repositories in your own local GitLab server (that runs the GitLab runner CI).
	repositories=$(curl --header "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN" "$GITLAB_SERVER_HTTP_URL/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
	
	# TODO: identify why the response of the repositories command is inconsistent.
	# shellcheck disable=2034
	readarray -t repo_arr <  <(echo "$repositories" | jq ".[].path")
	#echo "repo_arr=$repo_arr"
}

# 6.d.0 Check if the mirror repository exists in GitLab
gitlab_mirror_repo_exists_in_gitlab() {
	searched_repo="$1"
	# The repository array returned by GitLab API contains extra quotations around each repo.
	searched_repo_with_quotations='"'"$searched_repo"'"' 
	
	local gitlab_repos
    get_project_list gitlab_repos       # call function to populate the array
    
	# TODO: remove spaces around variables in quotations
	# shellcheck disable=SC2076
	if [[ " ${gitlab_repos[*]} " =~ " ${searched_repo} " ]]; then
		echo "FOUND"
	# TODO: remove spaces around variables in quotations
	elif [[ " ${gitlab_repos[*]} " =~ " ${searched_repo_with_quotations} " ]]; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}




# Structure:gitlab_status
# 6.e.0.helper TODO: move to helper
# TODO: find way to test this function (e.g. copy sponsor repo into GitLab as example.
gitlab_branch_exists() {
	gitlab_repo_name="$1"
	gitlab_branch_name="$2"
	
	# Check if Gitlab repository exists locally.
	if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
	
		# Get a list of the Gitlab branches in that repository.
		initialise_gitlab_branches_array "$gitlab_repo_name"
		
		# Check if the local copy of the Gitlab repository contains the branch.
		# shellcheck disable=SC2076
		if [[ " ${gitlab_branches[*]} " =~ " ${gitlab_branch_name} " ]]; then
			echo "FOUND"
		else
		
			# TODO: Do git status evaluation.
			echo "NOTFOUND"
		fi
	else 
		echo "ERROR, the Gitlab repository does not exist locally."
		exit 14
	fi
}

