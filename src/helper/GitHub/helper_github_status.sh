#!/bin/bash


# Structure:github_status
github_repo_exists_locally(){
	github_repo="$1"
	if test -d "$MIRROR_LOCATION/GitHub/$github_repo"; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}

# Structure:Github_status
# check if repo is private
# TODO: delete this function and replace it with:
# Verify the mirror location exists
# manual_assert_not_equal "$MIRROR_LOCATION" ""
# manual_assert_dir_exists "$MIRROR_LOCATION"
# manual_assert_dir_exists "$MIRROR_LOCATION/GitHub"
# 
# # Verify the Build status repository is cloned.
# manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
verify_github_repository_is_cloned() {
	
	if [[ "$1" != "" ]] && [[ "$2" != "" ]]; then
		github_repository="$1"
		target_directory="$2"
	else
		echo "Error, arguments are empty"
		exit 10
	fi
	
	local found_repo=$(dir_exists "$target_directory")
	if [ "$found_repo" == "NOTFOUND" ]; then
		# shellcheck disable=SC2059
		printf "The following GitHub repository: $github_repository \n was not cloned correctly into the path:$MIRROR_LOCATION/GitHub/$github_repository"
		exit 11
	elif [ "$found_repo" == "FOUND" ]; then
		echo "FOUND"
	else
		echo "An unknown error occured."
		exit 12
	fi
}

# Structure:Github_status (?or?)
# Structure:git_neutral
# Clone GitHub repository to folder src/mirror/GITHUB
####clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo"
####verify_github_repository_is_cloned "$github_repo" "$MIRROR_LOCATION/GitHub/$github_repository"
get_git_branches() {
    local -n arr=$1             # use nameref for indirection
	local company=$2
	local git_repository=$3
	arr=() # innitialise array with branches
	
	local theoutput=$(cd "$MIRROR_LOCATION/$company/$git_repository" && git branch --all)
	#read -p  "IN GET PWD=$PWD"
	#read -p  "MIRROR_LOCATION=$MIRROR_LOCATION"
	#read -p  "company=$company"
	#read -p  "git_repository=$git_repository"
	#read -p  "theoutput=$theoutput"
	
	# Parse branches from branch list response
	while IFS= read -r line; do
		number_of_lines=$(echo "$theoutput" | wc -l)
		if [ "$number_of_lines" -eq 1 ]; then
			arr+=("${line:2}")
		# Only parse remote branches.
		elif [ "${line:0:17}" == "  remotes/origin/" ]; then
			
			# Remove the substring that identifies a remote branch to get the actual branch name up to the first space.
			# Assumes branch names can't contain spaces
			branch=$(get_rhs_of_line_till_character "${line:17}" " ")
			
			# Filter out the HEAD branch duplicate, by filtering on a substring that indicates the duplicate.
			if [ "${branch:0:10}" != "-> origin/" ]; then
				
				# Filter out git theoutput artifacts of that do not start with a letter or number.
				# Assumes branch names always start with a letter or number.
				# TODO: make this check silent.
				if grep '^[-0-9a-zA-Z]*$' <<<"${branch:0:1}" ;then 
					
					# Append the branch name to the array of branches
					#echo "branch=$branch"
					arr+=("$branch")
				fi			
			fi
		fi
	# List branches and feed them into a line by line parser
	done <<< "$theoutput"
}




# Structure:github_status
# 6.j Get commit sha from GitHub.
# Structure:Gitlab_status
# TODO: remove above 20 lines with this fucntion
get_commit_sha_of_branch() {
	local desired_branch=$1
	local repository_name=$2
	local gitlab_username=$3
	local personal_access_token=$4
	
	# Get the branches of the GitLab CI resositories, and their latest commit.
	# TODO: switch server name
	branches=$(curl --silent --header "PRIVATE-TOKEN: $personal_access_token" "https://127.0.0.1/api/v4/projects/$gitlab_username%2F$repository_name/repository/branches")
	
	# Get two parallel arrays of branches and their latest commits
	readarray -t branch_names_arr <  <(echo "$branches" | jq ".[].name")
	readarray -t branch_commits_arr <  <(echo "$branches" | jq ".[].commit.id")
	#echo "branch_names_arr=${branch_names_arr[@]}"
	#echo "branch_commits_arr=${branch_commits_arr[@]}"

	# Loop through branches using a mutual index i.
	for i in "${!branch_names_arr[@]}"; do
	
		# Only export the desired branch build status
		if [  "${branch_names_arr[i]}" == '"'"$desired_branch"'"' ]; then
			####### TODO: test this function!
			found=true
			# TODO: include boolean, and check at end that throws error if branch is not found.
			# Get the GitLab build statusses and export them to the GitHub build status website.
			echo "${branch_commits_arr[i]}"
		fi
	done
	if [ "$found" != "true" ]; then
		echo "ERROR, the expected branch was not found."
		exit 13
	fi
}


# Structure:github_status
# 6.f.1.helper
# TODO: test
get_current_github_branch() {
	github_repo_name="$1"
	github_branch_name="$2"
	company="$3"
	
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

		# Verify the branch exists
		github_branch_exists_output="$(github_branch_exists "$github_repo_name" "$github_branch_name")"
		github_branch_is_found=$(assert_ends_in_found_and_not_in_notfound ${github_branch_exists_output})
		
		if [ "$github_branch_is_found" == "TRUE" ]; then
		
			# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Checkout the branch inside the repository.
			current_branch=$(cd "$MIRROR_LOCATION/$company/$github_repo_name" && git rev-parse --abbrev-ref HEAD)
			pwd_after="$PWD"
			
			echo "$current_branch"
			
			# Verify the current path is the same as it was when this function started.
			if [ "$pwd_before" != "$pwd_after" ]; then
				echo "The current path is not returned to what it originally was."
				exit 14
			fi
		else 
			echo "Error, the GitHub branch does not exist locally."
			exit 15
		fi
	else 
		echo "ERROR, the GitHub repository does not exist locally."
		exit 16
	fi
}

# Structure:github_status
# 6.f.1.helper
# TODO: test
get_current_github_branch_commit() {
	local github_repo_name="$1"
	local github_branch_name="$2"
	local company="$3"
	
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

		# Verify the branch exists
		github_branch_exists_output="$(github_branch_exists "$github_repo_name" "$github_branch_name")"
		github_branch_is_found=$(assert_ends_in_found_and_not_in_notfound ${github_branch_exists_output})
		if [ "$github_branch_is_found" == "TRUE" ]; then
		
			# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Checkout the branch inside the repository.
			current_branch_commit=$(cd "$MIRROR_LOCATION/$company/$github_repo_name" && git rev-parse HEAD)
			pwd_after="$PWD"
			
			echo "$current_branch_commit"
			
			# Verify the current path is the same as it was when this function started.
			if [ "$pwd_before" != "$pwd_after" ]; then
				echo "The current path is not returned to what it originally was."
				exit 171
			fi
		else 
			echo "Error, the GitHub branch does not exist locally."
			exit 18
		fi
	else 
		echo "ERROR, the GitHub repository does not exist locally."
		exit 19
	fi
}

is_desirable_github_build_status() {
	status="$1"
	if [[ "$status" == "failure" ]]; then
		echo "FOUND"
	elif [[ "$status" == "success" ]]; then
		echo "FOUND"
	elif [[ "$status" == "error" ]]; then
		echo "FOUND"
	elif [[ "$status" == "unknown" ]]; then
		echo "FOUND"
	elif [[ "$status" == "pending" ]]; then
		echo "FOUND"
	else 
		echo "NOTFOUND"
	fi
}

is_desirable_github_build_status_excluding_pending() {
	status="$1"
	if [[ "$status" == "failure" ]]; then
		echo "FOUND"
	elif [[ "$status" == "success" ]]; then
		echo "FOUND"
	elif [[ "$status" == "error" ]]; then
		echo "FOUND"
	elif [[ "$status" == "unknown" ]]; then
		echo "FOUND"
	else 
		echo "NOTFOUND"
	fi
}

# Structure:gitlab_status
# 6.g.0 Verify the GitHub mirror repository branch contains a gitlab yaml file.
verify_github_branch_contains_gitlab_yaml() {
	local github_repo_name="$1"
	local github_branch_name="$2"
	local company="$3"
	
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

		# Verify the branch exists.
		# shellcheck disable=SC2034
		local github_branch_exists_output="$(github_branch_exists "$github_repo_name" "$github_branch_name")"
		local github_branch_is_found=$(assert_ends_in_found_and_not_in_notfound ${github_branch_exists_output})
		if [ "$github_branch_is_found" == "TRUE" ]; then
		
			# Test if GitHub branch contains a GitLab yaml file.
			local filepath="$MIRROR_LOCATION/$company/$github_repo_name/.gitlab-ci.yml"
			if [ "$(file_exists "$filepath")" == "FOUND" ]; then
				echo "FOUND"
			else
				echo "NOTFOUND"
			fi
		else 
			echo "ERROR, the GitHub branch does not exist locally."
			exit 18
		fi
	else 
		echo "ERROR, the GitHub repository does not exist locally."
		exit 19
	fi
}

verify_github_commit_contains_gitlab_yaml() {
	local github_repo_name="$1"
	local company="$2"
	
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

		
			# Test if GitHub branch contains a GitLab yaml file.
			local filepath="$MIRROR_LOCATION/$company/$github_repo_name/.gitlab-ci.yml"
			local partial_capitalised_filepath="$MIRROR_LOCATION/$company/$github_repo_name/.GitLab-ci.yml"
			local capitalised_filepath="$MIRROR_LOCATION/$company/$github_repo_name/.GitLab-CI.yml"
			if [ "$(file_exists "$filepath")" == "FOUND" ]; then
				echo "FOUND"
			elif [ "$(file_exists "$partial_capitalised_filepath")" == "FOUND" ]; then
				echo "FOUND"
			elif [ "$(file_exists "$capitalised_filepath")" == "FOUND" ]; then
				echo "FOUND"
			else
				echo "NOTFOUND"
			fi
	else 
		echo "ERROR, the GitHub repository does not exist locally."
		exit 19
	fi
}

# source src/import.sh src/helper/GitHub/helper_github_status.sh && get_org_repos "hiveminds"
# source src/import.sh src/helper/GitHub/helper_github_status.sh && get_org_repos "a-t-0"
get_org_repos() {
	# shellcheck disable=SC2178
	local -n arr=$1 # use nameref for indirection
	local github_organisation_or_username="$2"
	
	arr=() # innitialise array with branches
	
	# get GitHub personal access token or verify ssh access to support private repositories.
	local github_personal_access_code=$(echo "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')

	# Getting the first 100 repositories of a GitHub user.
	local first_hundred_reponames=$(curl --silent -H "Authorization: token $github_personal_access_code" https://api.github.com/users/"$github_organisation_or_username"/repos?per_page=100 | jq -r '.[] | .name')
	
	# Parse branches from branch list response
	while IFS= read -r line; do
		
		# Append the branch name to the array of branches
		arr+=("$line")
		
	# List repositories and feed them into a line by line parser
	done <<< "$first_hundred_reponames"
}



#######################################
# Verifies the current branch equals the incoming branch, throws an error otherwise.
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
# TODO(a-t-0): TODO: test function
#######################################
assert_current_github_branch() {
	github_repo_name="$1"
	github_branch_name="$2"
	company="GitHub"
	
	actual_result="$(get_current_github_branch "$github_repo_name" "$github_branch_name" $company)"
	if [ "$actual_result" != "$github_branch_name" ]; then
		echo "The current GitHub branch does not match the expected GitHub branch:$github_branch_name"
		exit 171
	fi 
	manual_assert_equal "$actual_result" "$github_branch_name"
}


#######################################
# Verifies a public GitHub repository exists.
# Local variables:
#  github_username
#  github_repo_name
# Globals:
#  None.
# Arguments:
#  github_username
#  github_repo_name
# Returns:
#  0 if the function is completed succesfully.
# Outputs:
#  FOUND if the GitHub repository exists and is public.
#  NOTFOUND if the GitHub repository does not exists or is private.
# TODO(a-t-0): Write test for function.
#######################################
# run with:
#source src/helper/GitHub/helper_github_status.sh && check_public_github_repository_exists_with_api "a-t-0" "some_non_existing_repository"
#source src/helper/GitHub/helper_github_status.sh && check_public_github_repository_exists_with_api "a-t-0" "gitlab-ci-build-statuses"
#source src/helper/GitHub/helper_github_status.sh && check_public_github_repository_exists_with_api "ocaml" "ocaml"
check_public_github_repository_exists_with_api() {
	local github_username="$1"
	local github_repo_name="$2"

	if [[ "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" == "" ]]; then
		check_public_github_repository_exists_without_api $github_username $github_repo_name
	else
		local request_output
		request_output=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/${github_username}/${github_repo_name})
		local full_repo_name
		full_repo_name=$(echo "$request_output" | jq -r '.full_name')
		if [[ "$request_output" == "curl: (22) The requested URL returned error: 403" ]]; then
			read -p "You asked GitHub for information too often, GitHub says no."
			exit 5
		elif [[ "$full_repo_name" == "${github_username}/${github_repo_name}" ]]; then
			echo "FOUND"
		else
			echo "NOTFOUND"
		fi
	fi
}


# run with:
#source src/helper/GitHub/helper_github_status.sh && check_public_github_repository_exists_without_api "a-t-0" "some_non_existing_repository"
#source src/helper/GitHub/helper_github_status.sh && check_public_github_repository_exists_without_api "a-t-0" "gitlab-ci-build-statuses"
#source src/helper/GitHub/helper_github_status.sh && check_public_github_repository_exists_without_api "ocaml" "ocaml"
check_public_github_repository_exists_without_api() {
	local github_username
	github_username="$1"
	local github_repo
	github_repo="$2"

	local url
	url="https://github.com/$github_username/$github_repo"
	
	# Get website head(er) content
	local website_head_content
	website_head_content="$(curl -s --head $url)"
	
	# Get the first line of the website head(er) content.
	local first_line=`echo "${website_head_content}" | head -1`
	
	# Remove trailing characters with xargs
	local website_status=$(echo "$first_line" | xargs)
	
	if [[ "$website_status" == "HTTP/2 200" ]]; then
		echo "FOUND"
	elif [[ "$website_status" == "HTTP/2 404" ]]; then
		echo "NOTFOUND"
	else
		echo "Error, unexpected website status response: $website_status for: $url"
		exit 1
  	fi
}

#######################################
# Asserts a public GitHub repository exists. Throws error otherwise.
# Local variables:
#  github_username
#  github_repo_name
# Globals:
#  None.
# Arguments:
#  github_username
#  github_repo_name
# Returns:
#  0 if the GitHub repository is found.
#  5 if the GitHub repository is private or if it does not exist.
# Outputs:
#  None.
# TODO(a-t-0): Write test for function.
#######################################
# run with:
#source src/helper/GitHub/helper_github_status.sh && assert_public_github_repository_exists "a-t-0" "some_non_existing_repository"
#source src/helper/GitHub/helper_github_status.sh && assert_public_github_repository_exists "a-t-0" "gitlab-ci-build-statuses"
assert_public_github_repository_exists() {
	local github_username="$1"
	local github_repo_name="$2"

	if [[ $(check_public_github_repository_exists_with_api "$github_username" "$github_repo_name") != "FOUND" ]]; then
		echo "The repository www.github.com/${github_username}/${github_repo_name} is not a public GitHub repository/doesn't exist. Please create it/make it public, and try again."
		exit 5
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
# TODO(a-t-0): refactor repository wide to download_repository_using_https.
# TODO(a-t-0): write tests for method.
#######################################
# Downloads a repository into the root directory of this repository if the
#+ destination folder does yet exist
#+ TODO: write test for method
download_repository() {
	git_username=$1
	reponame=$2
	repo_url="https://github.com/"$git_username"/"$reponame".git"
	#echo "repo_url=$repo_url"
	if [ ! -d "$reponame" ]; then
		git clone $repo_url &&
		set +e
	fi
}


#######################################
# Downloads a repository using ssh deploy key.
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
# TODO(a-t-0): write tests for method.
#######################################
# bash -c 'source src/import.sh && download_and_overwrite_repository_using_ssh "a-t-0" "gitlab-ci-build-statuses"'
download_and_overwrite_repository_using_ssh() {
	local git_username="$1"
	local reponame="$2"
	local target_directory="$3"

	local repo_url="git@github.com:"$git_username"/"$reponame".git"
	
	# Delete target directory if it exists.
	remove_dir "$target_directory"
	manual_assert_dir_not_exists "$target_directory"
	# Delete repo directory if it exists.
	remove_dir "$reponame"
	manual_assert_dir_not_exists "$reponame"
	

	if [ "$target_directory" != "" ]; then
		git clone $repo_url $target_directory > /dev/null 2>&1 &&
		set +e 
		manual_assert_dir_exists "$target_directory/$repo_name"
	else
		git clone $repo_url > /dev/null 2>&1 &&
		set +e
		manual_assert_dir_exists "$reponame"
	fi
}



get_remote_github_list_of_repo_branches(){
	local github_user="a-t-0"
#	curl https://api.github.com/repos/joomla/joomla-cms/branches
#	curl https://api.github.com/repos/joomla/repositories
#	curl "https://api.github.com/users/$github_user/repos?per_page=100" | grep -o 'git@[^"]*'
#	curl "https://api.github.com/users/a-t-0/repos?per_page=100" | grep -o 'git@[^"]*'
#	curl "https://api.github.com/users/a-t-0/repos
#	git for-each-ref --format='%(committerdate) %09 %(authoremail) %09 %(refname)' | sort -k5n -k2M -k3n -k4n | grep <author-email>
#	https://github.com/:owner/:repo/commits.atom
#	https://github.com/a-t-0/sponsor_example/commits.atom
#	https://github.com/a-t-0/sponsor_example/branches.atom
#	https://rsshub.app/github/repos/yanglr
#	https://rsshub.app/github/repos/a-t-0
#
#
#	# Source: https://www.maxivanov.io/make-graphql-requests-with-curl/
#curl 'https://countries.trevorblades.com/' \
 # -X POST \
 # -H 'content-type: application/json' \
 # --data '{
 #   "query": "{ continents { code name } }"
 # }'	
#curl -i -H 'Content-Type: application/json' -H "Authorization: bearer myGithubAccessToken" -X POST -d '{"query": "query {repository(owner: \"wso2\", name: \"product-is\") {description}}"}' https://api.github.com/graphql
#curl -i -H 'Content-Type: application/json' -H -X POST -d '{"query": "query {repository(owner: \"wso2\", name: \"product-is\") {description}}"}' https://api.github.com/graphql
#curl -i -H 'Content-Type: application/json' -H -X POST -d '{"query": "query {repository(owner: \"a-t-0\") {description}}"}' https://api.github.com/graphql
#	
}
