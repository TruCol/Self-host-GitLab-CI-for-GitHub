#!/bin/bash
# run with:
#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github"

source src/helper.sh
source src/hardcoded_variables.txt
source src/creds.txt
source src/get_gitlab_server_runner_token.sh
source src/push_repo_to_gitlab.sh

# Hardcoded data:

# Get GitHub username.
github_username=$1

# Get GitHub repository name.
github_repo=$2

# OPTIONAL: get GitHub personal access token or verify ssh access to support private repositories.
github_personal_access_code=$3

verbose=$4

# Get GitLab username.
gitlab_username=$(echo $gitlab_server_account | tr -d '\r')

# Get GitLab user password.
gitlab_server_password=$(echo $gitlab_server_password | tr -d '\r')

# Get GitLab personal access token from hardcoded file.
gitlab_personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')

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

# Ensure mirrors directory is created.
create_mirror_directories() {
	$(create_dir "$MIRROR_LOCATION")
	$(create_dir "$MIRROR_LOCATION/GitHub")
	$(create_dir "$MIRROR_LOCATION/GitLab")
}
#assert_equal "$(dir_exists "$MIRROR_LOCATION")" "FOUND" 
verify_mirror_directories_are_created() {
	if [ "$MIRROR_LOCATION" == "" ]; then
		echo "Mirror location is not created"
		exit 1
	elif test ! -d "$MIRROR_LOCATION"; then
		echo "Mirror location is not created"
		exit 2
	elif test ! -d "$MIRROR_LOCATION/GitLab"; then
		echo "Mirror location GitLab directory is not created"
		exit 3
	else
		echo "FOUND"
	fi
}

remove_mirror_directories() {
	$(remove_dir "$MIRROR_LOCATION")
	$(remove_dir "$MIRROR_LOCATION/GitHub")
	$(remove_dir "$MIRROR_LOCATION/GitLab")
}

# Activates/enables the ssh for 
activate_ssh_account() {
	git_username=$1
	#eval "$(ssh-agent -s)"
	#$(eval "$(ssh-agent -s)")
	#$("$(ssh-agent -s)")
	#$(ssh-add ~/.ssh/"$git_username")
	#ssh-add ~/.ssh/"$git_username"
	eval "$(ssh-agent -s 3>&-)"
    ssh-add ~/.ssh/"$git_username"
}

# Check ssh-access to GitHub repo.
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
			echo "Your ssh-account:$github_username does not have pull access to the repository:$github_repository"
			exit 4
			# TODO: Throw error
			#(A public repository should grant ssh access even if no ssh credentials for that GitHub user is given.)
		else
			#activate_ssh_account "$github_username"
			check_ssh_access_to_repo "$github_username" "$github_repository" "YES"
		fi
	fi
}

has_access() {
	echo $(check_ssh_access_to_repo "$github_username" "$github_repo")
}

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
		exit 5
	elif [ "$found_repo" == "FOUND" ]; then
		echo "FOUND"
	else
		echo "An unknown error occured."
		exit 6
	fi
}

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


create_new_branch() {
	branch_name=$1
	company=$2
	git_repository=$3
	
	# create_repo branch
	theoutput=$(cd "$MIRROR_LOCATION/$company/$git_repository" && git checkout -b $branch_name)
	
	# TODO: assert the branch is created
	
	# echo theoutput
	echo "$theoutput"
}


copy_files_from_github_to_gitlab_repo_branches() {
	git_repository=$1
	rsync -av --progress "$MIRROR_LOCATION/GitHub/$git_repository/" "$MIRROR_LOCATION/GitLab/$git_repository" --exclude .git
}


# Check if the branch is contained in GitHub branch array (to filter the difference containing a branch that is (still) in GitLab but not in GitHub)
github_branch_is_in_gitlab_branches() {
	#eval gitlab_branches=$2
	local github_branch="$1"
	shift
	gitlab_branches=("$@")
	
	#"${branch_names_arr[i]}"
	
	# loop through file list and store search_result_boolean
	#for looping_filepath in "${file_list[@]}"; do
	#for gitlab_branch in "${gitlab_branches[@]}"; do
	#	echo "gitlab_branch=$gitlab_branch"
	#done
	if [[ " ${gitlab_branches[*]} " =~ " ${github_branch} " ]]; then
		# whatever you want to do when array contains value
		echo "github_branch=$github_branch"
		echo "FOUND"
	fi
}

# 6.a  Make a list of the branches in the GitHub repository
initialise_github_branches_array() {
	github_repo=$1
	get_git_branches github_branches "GitHub" "$github_repo"      # call function to populate the array
	declare -p github_branches
}

# 6.a  Make a list of the branches in the gitlab repository
initialise_gitlab_branches_array() {
	gitlab_repo=$1
	get_git_branches gitlab_branches "GitLab" "$gitlab_repo"      # call function to populate the array
	declare -p gitlab_branches
}

# 6.b Loop through the GitHub mirror repository branches that are already in GitLab
loop_through_github_branches() {
	for github_branch in ${github_branches[@]}; do
		echo "$github_branch"
	done
}

# shellcheck disable=SC2120
get_project_list(){
	#echo "BeforeFAILURE=$1"
	local -n repo_arr="$1"     # use nameref for indirection
	#local -n repo_arr=$1     # use nameref for indirection
	#echo "AFTERFAILURE=$1"

    # Get a list of the repositories in your own local GitLab server (that runs the GitLab runner CI).
	repositories=$(curl --header "PRIVATE-TOKEN: $gitlab_personal_access_token" "$GITLAB_SERVER_HTTP_URL/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
	
	# TODO: identify why the response of the repositories command is inconsistent.
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
    #echo "gitlab_repos=${gitlab_repos[*]}"
	
	if [[ " ${gitlab_repos[*]} " =~ " ${searched_repo} " ]]; then
		echo "FOUND"
	elif [[ " ${gitlab_repos[*]} " =~ " ${searched_repo_with_quotations} " ]]; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}



#6.d.1 If the GItHub branch already exists in the GItLab mirror repository does not yet exist, create it.
create_repo_if_not_exists() {
	new_repo_name="$1"
	echo "gitlab_personal_access_token=$gitlab_personal_access_token"
	
	#command="curl --header \"PRIVATE-TOKEN: $gitlab_personal_access_token\" \"$GITLAB_SERVER_HTTP_URL/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1\""
	#echo "command=$command \n\n\n"
	#repositories=$(curl --header "PRIVATE-TOKEN: $gitlab_personal_access_token" "$GITLAB_SERVER_HTTP_URL/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
	#echo "repositories_in_func=$repositories"
	
	gitlab_mirror_is_found="$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")"
	#echo "new_repo_name=$new_repo_name"
	#echo "gitlab_mirror_is_found=$gitlab_mirror_is_found"
	if [ "$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")" == "FOUND" ]; then
		assert_equal "$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")" "FOUND"
		echo "gitlab_mirror_is_found_inside_if=$gitlab_mirror_is_found"
	else
		#create_repository $new_repo_name
		create_repository "$new_repo_name"
		sleep 5
		gitlab_mirror_is_found_after_creation="$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")"
		assert_equal "$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")" "FOUND"
		#echo "gitlab_mirror_is_found_after_creation=$gitlab_mirror_is_found_after_creation"
	fi
}

# TODO: move to helper.sh
delete_repo_if_it_exists() {
	new_repo_name="$1"
	
	if [ "$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")" == "NOTFOUND" ]; then
		assert_equal "$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")" "NOTFOUND"
	elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")" == "FOUND" ]; then
		#echo "CREATING"
		deletion_output=$(delete_existing_repository "$new_repo_name" "root")
		sleep 5
		deleted_repo_is_found="$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")"
		assert_equal "$deleted_repo_is_found" "NOTFOUND"
	else
		echo "The repository was not NOTFOUND, nor was it FOUND. "
		exit 7
	fi
}

# TODO: move to helper.sh
gitlab_repo_exists_locally(){
	gitlab_repo="$1"
	if test -d "$MIRROR_LOCATION/GitLab/$gitlab_repo"; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}

github_repo_exists_locally(){
	github_repo="$1"
	if test -d "$MIRROR_LOCATION/GitHub/$github_repo"; then
		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}

# 6.e.0 If the GitLab repository exists in Gitlab, if it does not exist locally clone it, otherwise do a git pull.
get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab() {
	gitlab_username="$1"
	gitlab_repo_name="$2"
	
	# Remove spaces at end of username and servername.
	gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
	gitlab_server_password=$(echo $gitlab_server_password | tr -d '\r')
	
	#read -p "gitlab_repo_name=$gitlab_repo_name"
	#read -p "gitlab_username=$gitlab_username"
	#read -p "gitlab_server_password=$gitlab_server_password"
	#read -p "GITLAB_SERVER=$GITLAB_SERVER"
	#read -p "MIRROR_LOCATION=$MIRROR_LOCATION"
	
	# TODO: verify local gitlab mirror repo directories are created
	create_mirror_directories
	
	if [ "$(verify_mirror_directories_are_created)" != "FOUND" ]; then
		#assert_not_equal "$MIRROR_LOCATION" ""
		#assert_file_exist "$MIRROR_LOCATION"
		#assert_file_exist "$MIRROR_LOCATION/GitLab"
		echo "ERROR, the GitLab repository was not found in the GitLab server."
		exit 8
	# TODO: verify the repository exists in GitLab, throw error otherwise.
	elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
		echo "ERROR, the GitLab repository was not found in the GitLab server."
		exit 9
	else
		if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "NOTFOUND" ]; then
			clone_repository "$gitlab_repo_name" "$gitlab_username" "$gitlab_server_password" "$GITLAB_SERVER" "$MIRROR_LOCATION/GitLab/"
			assert_equal "$(gitlab_repo_exists_locally "$gitlab_repo_name")" "FOUND"
			echo "FOUND"
		elif [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
			echo "FOUND"
			# TODO: do a gitlab pull to get the latest version.
		else
			echo "ERROR, the GitLab repository was not found locally and not cloned."
			exit 10
		fi
	fi
}

# TODO: move to helper.
git_pull_gitlab_repo() {
	gitlab_repo_name="$1"
	if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
		
		# Get the path before executing the command (to verify it is restored correctly after).
		pwd_before="$PWD"
		
		# Do a git pull inside the gitlab repository.
		cd "$MIRROR_LOCATION/GitLab/$gitlab_repo" && git pull
		cd ../../..
		
		# Get the path after executing the command (to verify it is restored correctly after).
		pwd_after="$PWD"
		
		# Verify the current path is the same as it was when this function started.
		if [ "$pwd_before" != "$pwd_after" ]; then
			echo "The current path is not returned to what it originally was."
			exit 11
		fi
	else 
		echo "ERROR, the GitLab repository does not exist locally."
		exit 12
	fi
}

# 6.e.0.helper TODO: move to helper
github_branch_exists() {
	github_repo_name="$1"
	github_branch_name="$2"
	
	# Check if Github repository exists locally
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then
	
		# Get a list of the GitHub branches in that repository
		initialise_github_branches_array "$github_repo_name"
		
		# Check if the local copy of the GitHub repository contains the branch.
		if [[ " ${github_branches[*]} " =~ " ${github_branch_name} " ]]; then
			echo "FOUND"
		else
			echo "NOTFOUND"
		fi
	else 
		echo "ERROR, the GitHub repository does not exist locally."
		exit 13
	fi
}

# 6.e.0.helper TODO: move to helper
# TODO: find way to test this function (e.g. copy sponsor repo into GitLab as example.
gitlab_branch_exists() {
	gitlab_repo_name="$1"
	gitlab_branch_name="$2"
	
	# Check if Gitlab repository exists locally
	if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
	
		# Get a list of the Gitlab branches in that repository
		initialise_gitlab_branches_array "$gitlab_repo_name"
		
		# Check if the local copy of the Gitlab repository contains the branch.
		if [[ " ${gitlab_branches[*]} " =~ " ${gitlab_branch_name} " ]]; then
			echo "FOUND"
		else
			echo "NOTFOUND"
		fi
	else 
		echo "ERROR, the Gitlab repository does not exist locally."
		exit 13
	fi
}

# 6.f.0 Checkout that branch in the local GitHub mirror repository.
checkout_branch_in_github_repo() {
	local github_repo_name="$1"
	local github_branch_name="$2"
	local company="$3"
	
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

		# Verify the branch exists
		branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
		last_line_branch_check_result=$(get_last_line_of_set_of_lines "\${branch_check_result}")
		if [ "$last_line_branch_check_result" == "FOUND" ]; then
		
			# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Checkout the branch inside the repository.
			cd "$MIRROR_LOCATION/$company/$github_repo_name" && git checkout "$github_branch_name"
			cd ../../../..
			# Get the path after executing the command (to verify it is restored correctly after).
			pwd_after="$PWD"
	
			# Test to verify the current branch in the GitHub repository is indeed checked out.
			# TODO: check if this passes
			assert_current_github_branch "$github_repo_name" "$github_branch_name"
			
			
			# Verify the current path is the same as it was when this function started.
			if [ "$pwd_before" != "$pwd_after" ]; then
				echo "The current path is not returned to what it originally was."
				#echo "pwd_before=$pwd_before"
				#echo "pwd_after=$pwd_after"
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

# 6.g.0 Verify the GitHub mirror repository branch contains a gitlab yaml file.
verify_github_branch_contains_gitlab_yaml() {
	github_repo_name="$1"
	github_branch_name="$2"
	company="$3"
	
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

		# Verify the branch exists
		branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
		last_line_branch_check_result=$(get_last_line_of_set_of_lines "\${branch_check_result}")
		if [ "$last_line_branch_check_result" == "FOUND" ]; then
		
			# Test if GitHub branch contains GitLab yaml file.
			filepath="$MIRROR_LOCATION/$company/$github_repo_name/.gitlab-ci.yml"
			if [ "$(file_exists $filepath)" == "FOUND" ]; then
				echo "FOUND"
			else
				echo "NOTFOUND"
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



# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# 6.h.1 Checkout that branch in the local GitLab mirror repository if it exists.
# 6.h.2 If the branch does not exist in the GitLab repo, create it.
# 6.h.0 Checkout that branch in the local GitLab mirror repository. (Assuming the GitHub branch contains a gitlab yaml file)
checkout_branch_in_gitlab_repo() {
	gitlab_repo_name="$1"
	gitlab_branch_name="$2"
	company="$3"
	
	if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

		# Verify the branch exists
		branch_check_result="$(gitlab_branch_exists $gitlab_repo_name $gitlab_branch_name)"
		last_line_branch_check_result=$(get_last_line_of_set_of_lines "\${branch_check_result}")
		if [ "$last_line_branch_check_result" == "FOUND" ]; then
		
			# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Checkout the branch inside the repository.
			cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git checkout "$gitlab_branch_name"
			cd ../../../..
			# Get the path after executing the command (to verify it is restored correctly after).
			pwd_after="$PWD"
	
			# TODO: write test to verify the current branch in the gitlab repository is indeed checked out.
			# e.g. using git status
			assert_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name"
			
			# Verify the current path is the same as it was when this function started.
			path_before_equals_path_after_command "$pwd_before" "$pwd_after"
		else 
			
			# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Create the branch.
			cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git checkout -b "$gitlab_branch_name"
			cd ../../../..
			# Get the path after executing the command (to verify it is restored correctly after).
			pwd_after="$PWD"
			
			# TODO: write test to verify the current branch in the gitlab repository is indeed checked out.
			# TODO: check if this passes
			assert_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name"
		fi
	else 
		echo "ERROR, the gitlab repository does not exist locally."
		exit 19
	fi
}


# 6.i If there are differences in files, and if the GitHub branch contains a GitLab yaml file:
# copy the content from GitHub to GitLab (except for the .git folder).
copy_files_from_github_to_gitlab_branch() {
	pass
}

# 6.j Get commit sha from GitHub.

# 6.k Commit the GitLab branch changes, with the sha from the GitHub branch.



# Clone the GitLab repository from the GitLab server into the mirror directory
####clone_repository "$github_repo" "$gitlab_username" "$gitlab_server_password" "$GITLAB_SERVER" "$MIRROR_LOCATION/GitLab/"

# Get a list of GitLab repository branches
####get_git_branches gitlab_branches "GitLab" "$github_repo"      # call function to populate the array
#get_github_branches gitlab_branches "GitLab" "$github_repo"      # call function to populate the array
####declare -p gitlab_branches

# Get list of missing branches in GitLab
####missing_branches_in_gitlab=(`echo ${github_branches[@]} ${gitlab_branches[@]} | tr ' ' '\n' | sort | uniq -u `)
####echo "missing_branches_in_gitlab=${missing_branches_in_gitlab[@]}"

# Loop through the GitHub mirror repository branches that are already in GitLab
####for github_branch in ${github_branches[@]}; do
####	
####	# check if the branch is contained in GitHub branch array (to filter the difference containing a branch that is (still) in GitLab but not in GitHub)
####	if [[ " ${gitlab_branches[*]} " =~ " ${github_branch} " ]]; then
####		# whatever you want to do when array contains value
####		echo "github_branch=$github_branch"
####		
####		# Checkout that branch in the local GitHub mirror repository.
####		checkout_branch "$github_branch" "GitHub" "$github_repo"
####		
####		# Check if the GitHub 	branch contains a .gitlab-ci.yml file.
####		if test -f "$MIRROR_LOCATION/GitHub/$github_repo/.gitlab-ci.yml"; then
####			
####			# Get the latest GitLab mirror repository branch commit.
####			gitlab_commit_name=$(cd "$MIRROR_LOCATION/GitHub/$git_repository" && git rev-parse HEAD)
####			echo "gitlab_commit_name=$gitlab_commit_name"
####			
####			# Get the latest GitLab mirror repository branch commit.
####			# TODO SERVER
####			gitlab_commit_name=$(get_commit_of_branch "$github_branch" "$gitlab_repo" "$gitlab_username" "$gitlab_personal_access_token")
####			echo "gitlab_commit_name=$gitlab_commit_name"
####			
####			# Checkout that branch in the local GitLab mirror repository.
####			checkout_branch "$github_branch" "GitLab" "$github_repo"
####			
####			# If the two commit sha's are not equal:
####			if [ "$github_commit_name" != "$gitlab_commit_name" ]; then
####				# Delete the files in the GitLab mirror repository branch
####				#rm -r "$MIRROR_LOCATION/GitLab/$git_repository" !"$MIRROR_LOCATION/GitLab/$git_repository/.git"
####				cd "$MIRROR_LOCATION/GitLab/$git_repository" && find . ! -name '.git' -type f -exec rm -f {} +
####				#cd "$MIRROR_LOCATION/GitLab/$git_repository" && find . ! -name .git -type f -exec rm -f {} +
####				#cd "$MIRROR_LOCATION/GitLab/$git_repository" && ls | grep -v .git | parallel rm
####				#cd "$MIRROR_LOCATION/GitLab/$git_repository" && { rm -rf *; tar -x; } <<< $(tar -c ".git")
####				echo "browse into=$MIRROR_LOCATION/GitLab/$git_repository"
####
####				# Copy the files from the GitHub mirror repository into those of the GitLab repository.
####				
####				
####				exit
####			fi
####		fi
####   fi
####done
#SKIP Check the commit in GitHub already exists in its GitLab mirror branch.
# SKIP If not, copy the files from the GitHub branch into the GitLab branch and push the commit with the same sha.
# TODO: write check to see if adding the files make a difference that can be committed.


# Loop through the GitHub mirror repository branches and copy their content to GitLab if they are not yet in the GitLab repository.
####for missing_branch_in_gitlab in ${missing_branches_in_gitlab[@]}; do
####   
####   # check if the branch is contained in GitHub branch array (to filter the difference containing a branch that is (still) in GitLab but not in GitHub)
####   if [[ " ${github_branches[*]} " =~ " ${missing_branch_in_gitlab} " ]]; then
####		# whatever you want to do when array contains value
####		echo "missing_branch_in_gitlab=$missing_branch_in_gitlab"
####		
####		# Checkout that branch in the local GitHub mirror repository.
####		checkout_branch "$missing_branch_in_gitlab" "GitHub" "$github_repo"
####		
####		# Check if the GitHub 	branch contains a .gitlab-ci.yml file.
####		if test -f "$MIRROR_LOCATION/GitHub/$github_repo/.gitlab-ci.yml"; then
####		
####			# Create new branch in GitLab
####			create_new_branch "$missing_branch_in_gitlab" "GitLab" "$github_repo"
####			
####			# Copy files from GitHub branch
####			copy_files_from_github_to_gitlab_repo_branches "$github_repo"
####			
####			# Commit files to GitLab branch.
####			commit_changes "$MIRROR_LOCATION/GitLab/$gitlab_repo"
####			
####			# Push committed files go GitLab.
####			#git push --set-upstream origin main
####			push_changes "$github_repo" "$gitlab_username" "$gitlab_personal_access_token" "$GITLAB_SERVER" "$MIRROR_LOCATION/GitLab/$gitlab_repo"
####				
####			# Trigger CI build (is done automatically if it contains a .gitlab-ci.yml file)
####			
####			# Export build status to GitHub build-status-website repository
####			src/./push_gitlab_build_status_to_github_website.sh "$github_username" "$github_repo" "$missing_branch_in_gitlab" "$has_access"
####		fi
####	fi
####done