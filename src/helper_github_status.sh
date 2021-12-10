#!/bin/bash
# run with:
#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github"

###source src/helper_dir_edit.sh
###source src/helper_github_modify.sh
####source src/helper_github_status.sh
###source src/helper_gitlab_modify.sh
###source src/helper_gitlab_status.sh
###source src/helper_git_neutral.sh
###source src/helper_ssh.sh
###source src/hardcoded_variables.txt
###source src/creds.txt
###source src/get_gitlab_server_runner_token.sh
###source src/push_repo_to_gitlab.sh

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
# skip
verify_github_repository_is_cloned() {
	
	if [[ "$1" != "" ]] && [[ "$2" != "" ]]; then
		github_repository="$1"
		target_directory="$2"
	fi
	
	found_repo=$(dir_exists "$target_directory")
	if [ "$found_repo" == "NOTFOUND" ]; then
		echo "The following GitHub repository: $github_repository \n was not cloned correctly into the path:$MIRROR_LOCATION/GitHub/$github_repository"
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
####clone_github_repository "$github_username" "$github_repo" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo"
####verify_github_repository_is_cloned "$github_repo" "$MIRROR_LOCATION/GitHub/$github_repository"
get_git_branches() {
    local -n arr=$1             # use nameref for indirection
	company=$2
	git_repository=$3
	arr=() # innitialise array with branches
	
	theoutput=$(cd "$MIRROR_LOCATION/$company/$git_repository" && git branch --all)
	#read -p  "IN GET PWD=$PWD"
	#read -p  "MIRROR_LOCATION=$MIRROR_LOCATION"
	#read -p  "company=$company"
	#read -p  "git_repository=$git_repository"
	#read -p  "theoutput=$theoutput"
	
	# Parse branches from branch list response
	while IFS= read -r line; do
		number_of_lines=$(echo "$theoutput" | wc -l)
		if [ "$number_of_lines" -eq 1 ]; then
			echo "number_of_lines=$number_of_lines"
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
	desired_branch=$1
	repository_name=$2
	gitlab_username=$3
	personal_access_token=$4
	
	# Get the branches of the GitLab CI resositories, and their latest commit.
	# TODO: switch server name
	branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repository_name/repository/branches")
	
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
		branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
		last_line_branch_check_result=$(get_last_line_of_set_of_lines "\${branch_check_result}")
		if [ "$last_line_branch_check_result" == "FOUND" ]; then
		
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
	github_repo_name="$1"
	github_branch_name="$2"
	company="$3"
	
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

		# Verify the branch exists
		branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
		last_line_branch_check_result=$(get_last_line_of_set_of_lines "\${branch_check_result}")
		if [ "$last_line_branch_check_result" == "FOUND" ]; then
		
			# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Checkout the branch inside the repository.
			current_branch_commit=$(cd "$MIRROR_LOCATION/$company/$github_repo_name" && git rev-parse HEAD)
			pwd_after="$PWD"
			
			echo "$current_branch_commit"
			
			# Verify the current path is the same as it was when this function started.
			if [ "$pwd_before" != "$pwd_after" ]; then
				echo "The current path is not returned to what it originally was."
				exit 17
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