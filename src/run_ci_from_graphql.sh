#!/bin/bash

# bash -c "source src/import.sh && get_query_results"
get_query_results() {
	local github_organisation="hiveminds"
	local graphql_filepath="src/examplequery14.gql"
	
	if [ ! -f $graphql_filepath ];then
	    echo "usage of this script is incorrect."
	    exit 1
	fi
	

	# Form query JSON
	QUERY=$(jq -n \
	           --arg q "$(cat $graphql_filepath | tr -d '\n')" \
	           '{ query: $q }')

	
	json=$(curl -s -X POST \
	  -H "Content-Type: application/json" \
	  -H "Authorization: bearer $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" \
	  --data "$QUERY" \
	  https://api.github.com/graphql)
	
	echo "json=$json"
	loop_through_repos_in_api_query_json "$github_organisation" "$json"
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:Parsing
# Run with:
# bash -c "source src/import.sh && loop_through_repos_in_api_query_json"
loop_through_repos_in_api_query_json() {
	local github_organisation="$1"
	local json="$2"

	# Specify max nr of repos in a query response.
	local max_repos=100
	local max_branches=100
	local max_commits=100
	
	if [ "$json" == "" ]; then
		# Load json to variable.
		local filepath="src/eg_query2.json"
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
		# TODO: verify the GitHub repo exists
		# TODO: change this method to download with https?
		# Download the GitHub repo on which to run the GitLab CI:
		printf "\n\n\n Download the GitHub repository on which to run GitLab CI."
		download_github_repo_on_which_to_run_ci "$github_organisation" "$repo_name_without_quotations"
		printf "Downloaded GitHub repo on which to run GitLab CI for:$repo_name_without_quotations"

		# Loop through branches.
		# TODO: modify function to work without quotations or be consistent in it.
		local branches=$(loop_through_branches_in_repo_json "$github_organisation" "$repo_name" "$max_branches" "$max_commits" "$(echo "$eaten_wrapper" | jq ".[$i]")")
		echo "branches=$branches"
		
		# Loop through commits
		#local commits=$(loop_through_commits_in_repo_json "$max_commits" "$(echo "$eaten_wrapper" | jq ".[$i]")")

		# Determine whether the entry was null or not.
		evaluate_repo "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")"
		local res=$? # Get the return value of the function.
		echo "i=$i, repo_cursor=$repo_cursor"
		echo "i=$i, repo_name=$repo_name"

		# Check if the JSON contained null or if the next entry may still 
		# contain repository data.
		if [ $res -ge $max_repos ]; then
			# Ensure while loop is broken numerically.
			echo "i=$i"
			local i=$(( $max_repos + $max_repos ))
		fi
		
		# TODO (now): Delete the GitHub repo on which CI is ran	
	done
	# push build status icons to GitHub build status repository.
	push_commit_build_status_in_github_status_repo_to_github "$github_organisation"
}


#	# TODO: change this method to download with https?
#	# Download the GitHub repo on which to run the GitLab CI:
#	if [ "$(dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name")" == "NOTFOUND" ]; then
#		printf "\n\n\n Download the GitHub repository on which to run GitLab CI."
#		download_github_repo_on_which_to_run_ci "$github_username" "$github_repo_name"
#		manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
#	fi
#}

evaluate_repo() {
	local max_repos="$1"
	local repo_json="$2"
	if [ "$repo_json" == "null" ]; then
		return $max_repos
	else
		#echo "repo_json=$repo_json"
		return 1
	fi
}

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
}

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

get_branch_name() {
	local max_branches="$1"
	local branch_json="$2"
	#echo "branch_json=$branch_json"
	if [ "$branch_json" == "null" ]; then
		return $max_branches
	else
		branch_name="$(echo "$branch_json" | jq ".node.name")"
		echo "$branch_name"
		return 1
	fi
}


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
		echo "repo_name=$repo_name, branch_name=$branch_name eaten_commit_wrapper=$eaten_commit_wrapper"
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
				
				# Run GitLab CI on GitHub commit and push results to GitHub
				copy_github_commits_with_yaml_to_gitlab_repo $github_organisation $repo_name $branch_name $commit_name $github_organisation
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
}

evaluate_commit() {
	local max_commits="$1"
	local commit_json="$2"
	echo "commit_json=$commit_json"
	if [ "$commit_json" == "null" ]; then
		return $max_commits
	else
		#echo "commit_json=$commit_json"
		return 1
	fi
}

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
