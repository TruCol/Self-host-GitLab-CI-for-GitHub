#!/bin/bash
# run with:
#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github"

###source src/helper_dir_edit.sh
###source src/helper_github_modify.sh
###source src/helper_github_status.sh
###source src/helper_gitlab_modify.sh
###source src/helper_gitlab_status.sh
####source src/helper_git_neutral.sh
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


# Structure:git_neutral
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

# Structure:git_neutral
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

# Structure:git_neutral
# 6.i If there are differences in files, and if the GitHub branch contains a GitLab yaml file:
# copy the content from GitHub to GitLab (except for the .git folder).
copy_files_from_github_to_gitlab_branch() {
	github_repo_name="$1"
	github_branch_name="$2"
	gitlab_repo_name="$3"
	gitlab_branch_name="$4"
	
	# If the GitHub repository exists
	if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

		# If the GitHub branch exists
		github_branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
		last_line_github_branch_check_result=$(get_last_line_of_set_of_lines "\${github_branch_check_result}")
		if [ "$last_line_github_branch_check_result" == "FOUND" ]; then
		
			# If the GitHub branch contains a gitlab yaml file
			filepath="$MIRROR_LOCATION/GitHub/$github_repo_name/.gitlab-ci.yml"
			if [ "$(file_exists $filepath)" == "FOUND" ]; then
				
				# If the GitLab repository exists
				if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
					
					# If the GitLab branch exists
					found_branch_name="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name "GitLab")"
					if [ "$found_branch_name" == "$gitlab_branch_name" ]; then
					
						# If there exist differences in the files or folders in the branch (excluding the .git directory)
						echo "CheckingDifference"
						
						# Then copy the files and folders from the GitHub branch into the GitLab branch (excluding the .git directory)
						# That also deletes the files that exist in the GitLab branch that do not exist in the GitHub branch (excluding the .git directory)
						copy_github_files_and_folders_to_gitlab "$MIRROR_LOCATION/GitHub/$github_repo_name" "$MIRROR_LOCATION/GitLab/$github_repo_name"
						
						# Then verify the checksum of the files and folders in the branches are identical (excluding the .git directory)
						comparison_result="$(two_folders_are_identical_excluding_subdir $MIRROR_LOCATION/GitHub/$github_repo_name $MIRROR_LOCATION/GitLab/$github_repo_name .git)"
						
						if [ "$comparison_result" == "IDENTICAL" ]; then
							echo "IDENTICAL"
						else
							echo "ERROR, the content in the GitHub branch is not exactly copied into the GitLab branch, even when excluding the .git directory."
							exit 11
						fi
						
					else
						echo "ERROR, the GitLab branch does not exist locally."
						exit 12
					fi
				else
					echo "ERROR, the GitLab repository does not exist locally."
					exit 13
				fi
			else
				echo "ERROR, the GitHub branch does contain a yaml file."
				exit 14
			fi
		else 
			echo "ERROR, the GitHub branch does not exist locally."
			exit 24
		fi
	else 
		echo "ERROR, the GitHub repository does not exist locally."
		exit 25
	fi
}


# Structure:gitlab_status
# 6.i.0
#source src/helper_git_neutral.sh && copy_github_files_and_folders_to_gitlab "src/mirrors/GitHub/sponsor_example" "src/mirrors/GitLab/sponsor_example"
copy_github_files_and_folders_to_gitlab() {
	github_dir="$1"
	gitlab_dir="$2"
	
	if [ "$gitlab_dir" == "" ]; then
		echo "Error, the GitLab directory is not specified."
		exit 18
	fi
	
	# Delete all GitLab files and folders except for ., .., .git.
	delete_all_gitlab_files "$gitlab_dir/.*"
	delete_all_gitlab_files "$gitlab_dir/*" 
	delete_all_gitlab_folders "$gitlab_dir/.*" 
	delete_all_gitlab_folders "$gitlab_dir/*"
	
	# Copy all GitHub folders to GitLab
	copy_all_gitlab_files "$github_dir/.*" "$gitlab_dir"
	copy_all_gitlab_files "$github_dir/*" "$gitlab_dir"
	
	# Copy all GitHub files to GitLab.
	copy_all_gitlab_folders "$github_dir/.*" "$gitlab_dir"
	copy_all_gitlab_folders "$github_dir/*" "$gitlab_dir"
	
}

# Structure:git_neutral
export_repo() {
	# check if target folder already exists
	
	# delete target folder if it already exists
	#$(delete_target_folder)
	cp -r "$SOURCE_FOLDERPATH" ../
	# create target folder
	# copy source folder to target
}

# Structure:git_neutral
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