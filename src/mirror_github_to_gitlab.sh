#!/bin/bash

#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github" "root" "filler_gitlab"

# Hardcoded data:
echo "MIRROR_LOCATION=$MIRROR_LOCATION"
# Get github username.
github_username=$1
echo "github_username=$github_username"
# Get github repository name.
github_repo=$2
echo "github_repo=$github_repo"
# OPTIONAL: get GitHub personal access token or verify ssh access to support private repositories.
github_personal_access_code=$3
echo "github_personal_access_code=$github_personal_access_code"
# Get gitlab username.
gitlab_username=$4
echo "gitlab_username=$gitlab_username"
# Get gitlab personal access token.
gitlab_personal_access_goken=$4
echo "gitlab_personal_access_goken=$gitlab_personal_access_goken"

source src/helper.sh
source src/hardcoded_variables.txt
source src/get_gitlab_server_runner_token.sh

# Ensure mirrors directory is created.
$(create_dir "$MIRROR_LOCATION")
#assert_equal "$(dir_exists "$MIRROR_LOCATION")" "FOUND" 

# Activates/enables the ssh for 
activate_ssh_account() {
	git_username=$1
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/"$git_username"
}

# Check ssh-access to github repo.
check_ssh_access_to_repo() {
	github_username=$1
	github_repository=$2
	retry=$3
	
	my_service_status=$(git ls-remote git@github.com:$github_username/$github_repository.git 2>&1)
	found_error_in_ssh_command=$(lines_contain_string "ERROR" "\${my_service_status}")
	
	if [ "$found_error_in_ssh_command" == "NOTFOUND" ]; then
		echo "HASACCESS"
	elif [ "$found_error_in_ssh_command" == "FOUND" ]; then
		if [ "$retry" == "YES" ]; then
			echo "NOACCESS"
			# TODO: Throw error
			#(A public repository should grant ssh access even if no ssh credentials for that GitHub user is given.)
		else
			activate_ssh_account "$github_username"
			check_ssh_access_to_repo "$github_username" "$github_repository" "YES"
		fi
	fi
}

has_access=$(check_ssh_access_to_repo "$github_username" "$github_repo")
echo "has_access$has_access"

# check if repo is private
# skip

verify_github_repository_is_cloned() {
	github_repository=$1
	found_repo=$(dir_exists "$MIRROR_LOCATION/$github_repository")
	if [ "$found_repo" == "NOTFOUND" ]; then
		read -p "The following GitHub repository: $github_repository \n was not cloned correctly into the path:$MIRROR_LOCATION/$github_repository"
		exit 125
	fi
}

clone_github_repository() {
	github_username=$1
	github_repository=$2
	has_access=$3
	if [ "$has_access"=="HASACCESS" ]; then
		git clone git@github.com:"$github_username"/"$github_repository" "$MIRROR_LOCATION/$github_repository"
	else
		$(git clone https://github.com/"$github_username"/"$github_repository".git "$MIRROR_LOCATION/$github_repository")
		echo "Did not get ssh_access, downloaded using https, assumed it was a public repository."
		# TODO: support asking for GitHub username and pw to allow cloning private repositories over HTTPS.
		# TODO: support asking for GitHub personal access token to allow cloning private repositories over HTTPS.
	fi
}

# Clone GitHub repository to folder src/mirroring/
clone_github_repository "$github_username" "$github_repo" "$has_access"
verify_github_repository_is_cloned "$github_repo"


get_github_branches() {
    local -n arr=$1             # use nameref for indirection
	github_repository=$2
	arr=() # innitialise array with branches
	
	# Parse branches from branch list response
	while IFS= read -r line; do
		
		# Only parse remote branches.
		if [ "${line:0:17}" == "  remotes/origin/" ]; then
			
			# Remove the substring that identifies a remote branch to get the actual branch name up to the first space.
			# Assumes branch names can't contain spaces
			branch=$(get_rhs_of_line_till_character "${line:17}" " ")
			
			# Filter out the HEAD branch duplicate, by filtering on a substring that indicates the duplicate.
			if [ "${branch:0:10}" != "-> origin/" ]; then
				
				# Filter out git output artifacts of that do not start with a letter or number.
				# Assumes branch names always start with a letter or number.
				if grep '^[-0-9a-zA-Z]*$' <<<"${branch:0:1}" ;then 
					
					# Append the branch name to the array of branches
					echo "branch=$branch"
					arr+=("$branch")
				fi			
			fi
		fi
	# List branches and feed them into a line by line parser
	done <<< $(cd "$MIRROR_LOCATION/$github_repository" && git branch --all)
}


# Make a list of the branches in the GitHub repository
get_github_branches branches "$github_repo"      # call function to populate the array
declare -p branches

# Check if the mirror repository exists in GitLab
# If the GItHub branch already exists in the GItLab mirror repository does not yet exist, create it. 


# Loop through the GitHub repository branches.
# If the GitHub branch does not yet exist in the GitLab repository, create it. 

# Get the latest GitHub branch commit.

# Get the latest GitLab mirror branch commit.

# Check the commit in GitHub already exists in its GitLab mirror branch.
# If not, copy the files from the GitHub branch into the GitLab branch and push the commit with the same sha.
# TODO: write check to see if adding the files make a difference that can be committed.


############
# Run the GitLab CI on that commit of that branch.

# Wait until the Gitlab runner CI is finished for that commit.

# Once the GitLab runner CI is finished for that commit, push the build status to the build status website.