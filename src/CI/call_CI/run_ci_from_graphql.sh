#!/bin/bash

#######################################
# Performs a GraphQL API call to get a json with the first 100 public GitHub 
# repositories in a GitHub organisation. That Json also contains the first 100
# branches per repository as well as the first 100 commits per branch. Then it 
# loops over each of these commits, and runs the GitLab CI on that commit. If 
# the GitLab CI result is returned in time, the commit build status will be set
# accordingly in GitHub. Additionally, a GitHub build status badge for that 
# GitHub branch is exported to GitHub, if the GitHub commit is the most recent
# commit in that branch.
# Local variables:
#  github_organisation
# graphql_filepath
# graphql_query
# Globals:
# GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL 
# Arguments:
#  github_organisation - The GitHub username or organisation on which the query is performed.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0): Separate getting the query from running the GitLab CI on the 
# json.
# TODO(a-t-0): Ideally, get a list of repositories with that contain a list of 
# branches, that contain a list of commits, before running the CI on that 
# object. This can be resolved by creating a list with comma separated values
# of format <repo><branch><commit>, and looping through that list.
# TODO(a-t-0): Change this repo to return that list in format 
# <repo><branch><commit> and run tests on it using a testing repository.
#######################################
# bash -c "source src/import.sh && get_query_results"
get_query_results() {
	local github_organisation="trucol"
	local graphql_filepath="src/helper/queries/examplequery14.gql"
	
	if [ ! -f $graphql_filepath ];then
	    echo "usage of this script is incorrect."
	    exit 1
	fi
	

	# Form query JSON
	graphql_query=$(jq -n \
	           --arg q "$(cat $graphql_filepath | tr -d '\n')" \
	           '{ query: $q }')

	
	json=$(curl -s -X POST \
	  -H "Content-Type: application/json" \
	  -H "Authorization: bearer $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" \
	  --data "$graphql_query" \
	  https://api.github.com/graphql)
	
	echo "json=$json"
	loop_through_repos_in_api_query_json "$github_organisation" "$json"

	# Push gitlab build status
	push_commit_build_status_in_github_status_repo_to_github

	# Remove mirror directory with all downloaded repositories.
	remove_mirror_directories
	
}


#######################################
# Extracts the repositories from the incoming json that was formed by the GraphQL
# query. Then it removes irrelevant segments from the json before passing it on
# to the next function that gets the branch, which then gets the commit.
# Local variables:
#  github_organisation
#  json
#  max_repos
# Globals:
#  None.
# Arguments:
#  github_organisation - The GitHub username or organisation on which the query is performed.
#  json - The raw json that was formed by the GitHub GraphQL query.
# Returns:
#  0 if T.B.D.
# Outputs:
#  None.
# TODO(a-t-0): Implement method to allow looping beyond 100 repositories, using the
# cursor that is given to the last repository. Optionally include a counter to not run on the 
# query again if less then 100 repositroies were returned. (Perhaps also check
# if the query can indicate if there are exactly 100 or more.)
#######################################
loop_through_repos_in_api_query_json() {
	local github_organisation="$1"
	local json="$2"

	# Specify max nr of repos in a query response.
	local max_repos=100
	local max_branches=100
	local max_commits=100
	
	if [ "$json" == "" ]; then
		# Load json to variable.
		read -p "JSON EMPTY"
		local filepath="src/eg_query14.json"
		local json=$(cat $filepath)
	fi

	# Get the GitHub build status repository.
	get_build_status_repository_from_github


	# Remove unneeded json wrapper
	local eaten_wrapper="$(echo "$json" | jq ".[][][][]")"
	#echo "eaten_wrapper=$eaten_wrapper"
	# Loop 0 to 100 (including 100)
	local i=-1
	while [ $max_repos -ge $i ]
	do
		local i=$(($i+1))
		# Store the output of the json parsing function
		local some_value=$(evaluate_repo "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")
		local repo_cursor=$(get_repo_cursor "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")
		local repo_name=$(get_repo_name "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")
		repo_name_without_quotations=$(echo "$repo_name" | tr -d '"')
		echo "repo_name_without_quotations=$repo_name_without_quotations"
		if [ "$repo_name_without_quotations" == "checkstyle-for-bash" ]; then
			# TODO: verify the GitHub repo exists
			# TODO: change this method to download with https?
			# Download the GitHub repo on which to run the GitLab CI:
			printf "\n Download the GitHub repository on which to run GitLab CI."
			download_github_repo_on_which_to_run_ci "$github_organisation" "$repo_name_without_quotations"
			printf "Downloaded GitHub repo on which to run GitLab CI for:$repo_name_without_quotations"
	
			# Loop through branches.
			# TODO: modify function to work without quotations or be consistent in it.
			local branches=$(loop_through_branches_in_repo_json "$github_organisation" "$repo_name" "$max_branches" "$max_commits" "$(echo "$eaten_wrapper" | jq ".[$i]")")
			echo "branches=$branches"
			printf "Got branches=$branches Now evaluate repo"
			# Loop through commits
			#local commits=$(loop_through_commits_in_repo_json "$max_commits" "$(echo "$eaten_wrapper" | jq ".[$i]")")
	
			# Determine whether the entry was null or not.
			evaluate_repo "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")"
			printf "evaluated repo"
			local res=$? # Get the return value of the function.
			echo "i=$i, repo_cursor=$repo_cursor"
			echo "i=$i, repo_name=$repo_name"
	
			# Check if the JSON contained null or if the next entry may still 
			# contain repository data.
			if [ $res -ge $max_repos ]; then
				# Ensure while loop is broken numerically.
				printf "i=$i"
				echo "i=$i"
				local i=$(( $max_repos + $max_repos ))
			fi
			
			# TODO (now): Delete the GitHub repo on which CI is ran	
		fi
	done
	# push build status icons to GitHub build status repository.
	printf "Push commit."
	push_commit_build_status_in_github_status_repo_to_github

	echo "repo_cursor=$repo_cursor"
}


#######################################
# Not quite clear what purpose this function serves. It appears to perform a 
# check to see if the json remainder still contains a repository, or whether
# all repositories in the JSON have been evaluated.
# Local variables:
#  max_repos
#  repo_json
# Globals:
#  None.
# Arguments:
#  max_repos - The maximum number of repositories that the query returns.
#  repo_json - The json that contains the query results with repositories.
# Returns:
#  $max_repos If the json does not contain any more repositories.
#  1 if there still is a repository that can be evaluated, in the JSON string.
# Outputs:
#  None.
# TODO(a-t-0): Determine what the exact purpose is of this function and 
# document it.
#######################################
evaluate_repo() {
	local max_repos="$1"
	local repo_json="$2"
	
	# Check if the repo json still contains a repository or not.
	if [ "$repo_json" == "null" ]; then
		# Return the maximum nr of repos, such that the for loop can be
		# terminated in the (parent) function that calls this function.
		return $max_repos
	else
		# The JSON still contains some repository that can be evaluated.
		return 1
	fi
}


#######################################
# Gets the cursor=some identifier string that refers to a repository. This 
# cursor can later be used to run the GraphQL query on the next 100 repos.
# Local variables:
#  max_repos
#  repo_json
# Globals:
#  None.
# Arguments:
#  max_repos - The maximum number of repositories that the query returns.
#  repo_json - The json that contains the query results with repositories.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_repo_cursor() {
	local max_repos="$1"
	local repo_json="$2"
	#echo "repo_json=$repo_json"
	if [ "$repo_json" == "null" ]; then
		return $max_repos
	else
		echo "$(echo "$repo_json" | jq ".cursor")"
		return 1
	fi
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  max_repos - The maximum number of repositories that the query returns.
#  repo_json - The json that contains the query results with repositories.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_repo_name() {
	local max_repos="$1"
	local repo_json="$2"
	if [ "$repo_json" == "null" ]; then
		return $max_repos
	else
		echo "$(echo "$repo_json" | jq ".node.name")"
		return 1
	fi
}


#######################################
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
# TODO(a-t-0):
#######################################
loop_through_branches_in_repo_json() {
	local github_organisation="$1"
	local repo_name="$2"
	local max_branches="$3"
	local max_commits="$4"
	local branches_json="$5"
	
	if [ "$branches_json" != "null" ]; then
		# Remove unneeded json wrapper
		local eaten_branch_wrapper="$(echo "$branches_json" | jq ".node.refs.edges")"

		local j=-1
		while [ $max_branches -ge $j ]
		do
			local j=$(($j+1))

			# Store the output of the json parsing function
			local some_value=$(evaluate_branch "$max_branches" "$(echo "$eaten_branch_wrapper" | jq ".[$j]")")
			
			local branch_cursor=$(get_branch_cursor "$max_branches" "$(echo "$eaten_branch_wrapper" | jq ".[$j]")")
			local branch_name=$(get_branch_name "$max_branches" "$(echo "$eaten_branch_wrapper" | jq ".[$j]")")
			loop_through_commits_in_repo_json "$github_organisation" "$repo_name" "$branch_name" "$max_commits" "$(echo "$eaten_branch_wrapper" | jq ".[$j]")"

			if [ "$branch_cursor" != "" ]; then
				echo "branch_cursor=$branch_cursor"
				echo "branch_name=$branch_name"
			fi
			
			# Determine whether the entry was null or not.
			evaluate_branch "$max_branches" "$(echo "$eaten_branch_wrapper" | jq ".[$j]")"
			local resj=$? # Get the return value of the function.
			
#			# Check if the JSON contained null or if the next entry may still 
			# contain repository data.
			if [ $resj -ge $max_branches ]; then
				# Ensure while loop is broken numerically.
				local j=$(( $max_branches + $max_branches ))
			fi
		done
	else
		echo "ERROR null incoming"
		exit 4
	fi
	echo "branch_cursor=$branch_cursor"
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  max_branches - The maximum number of branches that the query returns.
#  branches_json - The json that contains the query results with branches of 
#  the repositories.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
evaluate_branch() {
	local max_branches="$1"
	local branch_json="$2"
	if [ "$branch_json" == "null" ]; then
		return $max_branches
	else
		#echo "branch_json=$branch_json"
		return 1
	fi
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  max_branches - The maximum number of branches that the query returns.
#  branches_json - The json that contains the query results with branches of 
#  the repositories.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_branch_cursor() {
	local max_branches="$1"
	local branch_json="$2"
	#echo "branch_json=$branch_json"
	if [ "$branch_json" == "null" ]; then
		return $max_branches
	else
		echo "$(echo "$branch_json" | jq ".cursor")"
		return 1
	fi
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  max_branches - The maximum number of branches that the query returns.
#  branches_json - The json that contains the query results with branches of 
#  the repositories.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_branch_name() {
	local max_branches="$1"
	local branch_json="$2"
	
	if [ "$branch_json" == "null" ]; then
		return $max_branches
	else
		branch_name="$(echo "$branch_json" | jq ".node.name")"
		echo "$branch_name"
		return 1
	fi
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  max_commits - The maximum number of commits that the query returns.
#  commits_json - The json that contains the query results with commits of 
#  the branch of the repository.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
loop_through_commits_in_repo_json() {
	local with_quotations_github_organisation="$1"
	local with_quotations_repo_name="$2"
	local with_quotations_branch_name="$3"
	local max_commits="$4"
	local commits_json="$5"

	github_organisation=$(echo "$with_quotations_github_organisation" | tr -d '"')
	repo_name=$(echo "$with_quotations_repo_name" | tr -d '"')
	branch_name=$(echo "$with_quotations_branch_name" | tr -d '"')
	
	#read -p "github_organisation=$github_organisation"
	#read -p "repo_name=$repo_name"
	#read -p "branch_name=$branch_name"
	#read -p "max_commits=$max_commits"
	#read -p "commits_json=$commits_json"
	
	if [ "$commits_json" != "null" ]; then
		# Remove unneeded json wrapper
		local eaten_commit_wrapper="$(echo "$commits_json" | jq ".node.target.history.edges")"
		#echo "repo_name=$repo_name, branch_name=$branch_name eaten_commit_wrapper=$eaten_commit_wrapper"
		local j=-1
		while [ $max_commits -ge $j ]
		do
			local j=$(($j+1))
#			# Store the output of the json parsing function
			#local some_value=$(evaluate_commit "$max_commits" "$(echo "$eaten_commit_wrapper" | jq ".[$j]")")
			local commit_cursor=$(get_commit_cursor "$max_commits" "$(echo "$eaten_commit_wrapper" | jq ".[$j]")")
			local with_quotations_commit_name=$(get_commit_name "$max_commits" "$(echo "$eaten_commit_wrapper" | jq ".[$j]")")
			commit_name=$(echo "$with_quotations_commit_name" | tr -d '"')
			if [ "$commit_cursor" != "" ]; then
				echo "repo_name=$repo_name, branch_name=$branch_name  commit_name=$commit_name"
				echo "repo_name=$repo_name, branch_name=$branch_name commit_cursor=$commit_cursor"
				
				# Don't run ci on $GITHUB_STATUS_WEBSITE_GLOBAL because that will create commits
				# stating an evaluation of a commit has occured, which in turn results in commits
				# for the next run etc. Which keeps on going, + it does not contain any CI yaml.
				if [ "$repo_name" != "$GITHUB_STATUS_WEBSITE_GLOBAL" ]; then

					# TODO: allow cli args to run on specific repo from cli
					if [ "$repo_name" == "checkstyle-for-bash" ]; then
						#read -p "Starting copy."
						# Run GitLab CI on GitHub commit and push results to GitHub
						# TODO: allow cli args to run on specific commit sha from cli.
						#if [ "$commit_name" == "65c7f754a2774f2a37a680dc84bddc9e53c0a85e" ]; then
							copy_github_commits_with_yaml_to_gitlab_repo $github_organisation $repo_name $branch_name $commit_name $github_organisation
						#fi
					fi
				fi
			fi
			
			# Determine whether the entry was null or not.
			evaluate_commit "$max_commits" "$(echo "$eaten_commit_wrapper" | jq ".[$j]")"
			local resj=$? # Get the return value of the function.
			
#			# Check if the JSON contained null or if the next entry may still 
			# contain repository data.
			if [ $resj -ge $max_commits ]; then
				# Ensure while loop is broken numerically.
				local j=$(( $max_commits + $max_commits ))
			fi
		done
	else
		echo "ERROR null incoming"
		exit 4
	fi
	echo "commit_cursor=$commit_cursor"
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  max_commits - The maximum number of commits that the query returns.
#  commits_json - The json that contains the query results with commits of 
#  the branch of the repository.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
evaluate_commit() {
	local max_commits="$1"
	local commit_json="$2"
	#echo "commit_json=$commit_json"
	if [ "$commit_json" == "null" ]; then
		return $max_commits
	else
		#echo "commit_json=$commit_json"
		return 1
	fi
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  max_commits - The maximum number of commits that the query returns.
#  commits_json - The json that contains the query results with commits of 
#  the branch of the repository.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_commit_cursor() {
	local max_commits="$1"
	local commit_json="$2"
	#echo "commit_json=$commit_json"
	if [ "$commit_json" == "null" ]; then
		return $max_commits
	else
		echo "$(echo "$commit_json" | jq ".cursor")"
		return 1
	fi
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  max_commits - The maximum number of commits that the query returns.
#  commits_json - The json that contains the query results with commits of 
#  the branch of the repository.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
get_commit_name() {
	local max_commits="$1"
	local commit_json="$2"
	#echo "commit_json=$commit_json"
	if [ "$commit_json" == "null" ]; then
		return $max_commits
	else
		commit_name="$(echo "$commit_json" | jq ".node.oid")"
		echo "$commit_name"
		return 1
	fi
}