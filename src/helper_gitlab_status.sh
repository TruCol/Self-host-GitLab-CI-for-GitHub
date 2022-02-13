#!/bin/bash

#######################################
# Creates a Bash array that can be used by other functions in this script.
# The array is named github_branches and it contains the names of the
# GitHub branches in the repository that is passed as an argument.
# Local variables:
#  github_repo
# Globals:
#  None.
# Arguments:
#   Name of the GitHub repository for which the array with branches is created.
# Returns:
#  0 if funciton was evaluated succesfull.
#  7 if the repository was not found.
# Outputs:
#  None.
# TODO(a-t-0): Create consistency in local var naming of github_repo and 
# github_repo_name. Change it to github_repo. Apply repository wide.
#######################################
# TODO(a-t-0): Capitalise github_branches as it is a global variable.
initialise_github_branches_array() {
	github_repo=$1
	get_git_branches github_branches "GitHub" "$github_repo"      # call function to populate the array
	# shellcheck disable=SC2154
	declare -p github_branches
}


#######################################
# Creates a Bash array that can be used by other functions in this script.
# The array is named gitlab_branches and it contains the names of the
# GitLab branches in the repository that is passed as an argument.
# Local variables:
#  gitlab_repo
# Globals:
#  None.
# Arguments:
#   Name of the GitLab repository for which the array with branches is created.
# Returns:
#  0 if funciton was evaluated succesfull.
#  7 if the repository was not found.
# Outputs:
#  None.
# TODO(a-t-0): Create consistency in local var naming of github_repo and 
# github_repo_name. Change it to github_repo. Apply repository wide.
# TODO(a-t-0): Capitalise gitlab_branches as it is a global variable.
#######################################
# 6.a  Make a list of the branches in the gitlab repository
initialise_gitlab_branches_array() {
	gitlab_repo=$1
	get_git_branches gitlab_branches "GitLab" "$gitlab_repo"      # call function to populate the array
	# shellcheck disable=SC2154
	declare -p gitlab_branches
}


#######################################
# Echo's the names of all the branches in the github_branches array.
# Local variables:
#  github_branch
# Globals:
#  github_branches.
# Arguments:
#   None.
# Returns:
#  0 if funciton was evaluated succesfull.
# Outputs:
#  The list of branches in the repository that was
# TODO: make sure this function calls the function that populates the branches 
# array, such that this function indeed loops through the branches in that 
# repository, and not another, if it is changed inbetween. (TODO: verify if 
# this function is used before fixing todo).
# TODO: (a-t-0): Determine how to define github_branch as a local variable
# within the for loop.
# TODO: (a-t-0) capitalise the global variable: github_branches.
#######################################
loop_through_github_branches() {
	local github_branch
	for github_branch in "${github_branches[@]}"; do
		echo "$github_branch"
	done
}


#######################################
# Echo's list of THE FIRST 1000 repositories in a GitLab server.
# Local variables:
#  repo_arr
#  repositories
# Globals:
#  github_branches.
# Arguments:
#   None.
# Returns:
#  0 if funciton was evaluated succesfull.
# Outputs:
#   None.
# TODO: (a-t-0) Determine whether the repo_arr should indeed be local, or
# Global.
# TODO: (a-t-0) Determine whether it indeed outputs nothing or if it outputs
# the array with repositories.
# TODO: (a-t-0) Generalise this method to work beyond the first 1000 repositories
# in a GitLab server.
#######################################
get_project_list(){
	# TODO: (a-t-0) Determine whether the repo_arr should indeed be local, or Global.
	# shellcheck disable=2034
	local -n repo_arr="$1"     # use nameref for indirection

    # Get a list of the repositories in your own local GitLab server (that runs the GitLab runner CI).
	local repositories=$(curl --header "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" "$GITLAB_SERVER_HTTP_URL/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
	
	# Verify the machine has access to the repositories.
	no_authorisation='{"message":"401 Unauthorized"}'
	if [ "$repositories" == "$no_authorisation" ]; then
		read -p "Error, the GitLab personal access token:$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL did not grant access to: $GITLAB_SERVER_HTTP_URL/api/v4/projects/?simple=yes&private=true&per_page=1000&p age=1"
		exit 3
	fi
	
	# TODO: identify why the response of the repositories command is inconsistent.
	# shellcheck disable=2034
	# TODO: silence this in the terminal output
	readarray -t repo_arr <  <(echo "$repositories" | jq ".[].path")
	#echo "repo_arr=$repo_arr"
}


#######################################
# Echo's if a repository is found in a GitLab server.
# Local variables:
#  searched_repo
# Globals:
#  github_branches
# Arguments:
#  The repository of which one wants to know if it is in the GitLab server.
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  FOUND if the searched repository exists in the GitLab server
#  NOTFOUND if the searched repository does not exists in the first 1000 
#  repositories of the GitLab server.
# TODO(a-t-0): Remove spaces around variables in quotations and verify it 
# still works.
#######################################
gitlab_mirror_repo_exists_in_gitlab() {
	local searched_repo="$1"
	# The repository array returned by GitLab API contains extra quotations 
	# around each repo. So these are added for similarity.
	searched_repo_with_quotations='"'"$searched_repo"'"' 
	
	local gitlab_repos
    get_project_list gitlab_repos       # call function to populate the array
    
	# TODO(a-t-0): Remove spaces around variables in quotations and verify it
    # still works.
	# shellcheck disable=SC2076
	if [[ " ${gitlab_repos[*]} " =~ " ${searched_repo} " ]]; then
		echo "FOUND"
	# TODO(a-t-0): Remove spaces around variables in quotations and verify it
    # still works.
	elif [[ " ${gitlab_repos[*]} " =~ " ${searched_repo_with_quotations} " ]]; then
		echo "FOUND"
	else
		echo "NOTFOUND"
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
# Structure:gitlab_status
# TODO: find way to test this function (e.g. copy sponsor repo into GitLab as example.
gitlab_branch_exists() {
	local gitlab_repo_name="$1"
	local gitlab_branch_name="$2"
	
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



#######################################
# Outputs the output of the gitlab-runner status command.
# Local variables:
# status
# Globals:
#  None.
# Arguments:
#  None.
# Returns:
#  0 if the status was retrieved and echoed succesfully.
# Outputs:
#  The status of the GitLab runner.
#######################################
check_gitlab_runner_status() {
	local status=$(sudo gitlab-runner status)
	echo "$status"
}


#######################################
# Returns the state of the GitLab server. Assumes Docker is installed.
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if the code was executed succesfully

# Outputs:
#  The state of the GitLab server
#######################################
#sudo docker exec -i 79751949c099 bash -c "gitlab-rails status"
#sudo docker exec -i 79751949c099 bash -c "gitlab-ctl status"
# run with: source src/import.sh && check_gitlab_server_status
check_gitlab_server_status() {
	
	container_id=$(get_docker_container_id_of_gitlab_server)
	#echo "container_id=$container_id"
	status=$(sudo docker exec -i "$container_id" bash -c "gitlab-ctl status")
	echo "$status"
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
# Structure:gitlab_status
gitlab_server_is_running() {
	
	
	if [ $(safely_check_if_program_is_installed "docker") == "FOUND" ]; then
		if [ $(docker_is_running) == "FOUND" ]; then
			actual_result=$(check_gitlab_server_status)
			#echo "actual_result=$actual_result"
			if
			[  "$(lines_contain_string 'run: alertmanager: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: gitaly: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: gitlab-exporter: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: gitlab-workhorse: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: grafana: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: logrotate: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: nginx: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: postgres-exporter: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: postgresql: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: prometheus: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: puma: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: redis: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: redis-exporter: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: sidekiq: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$(lines_contain_string 'run: sshd: (pid ' "${actual_result}")" == "FOUND" ] &&
			[  "$actual_result" != "" ]
			then
				echo "RUNNING"
			else
				echo "NOTRUNNING"
			fi
		else
			echo "NOTRUNNING"
		fi
	else
		echo "NOTRUNNING"
	fi
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
# Structure:gitlab_status
# Echo's "RUNNING" if the GitLab runner service is running, "NOTRUNNING" otherwise.
gitlab_runner_is_running() {
	actual_result=$(check_gitlab_runner_status)
	EXPECTED_OUTPUT="gitlab-runner: Service is running"
	if [ "$actual_result" == "$EXPECTED_OUTPUT" ]; then
		echo "RUNNING"
	else
		echo "NOTRUNNING"
	fi
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
# Runs for $duration [seconds] and checks whether the GitLab server status is: RUNNING.
# Throws an error and terminates the code if the GitLab server status is not found to be
# running within $duration [seconds]
check_for_n_seconds_if_gitlab_server_is_running() {
	duration=$1
	running="false"
	end=$(("$SECONDS" + "$duration"))
	while [ $SECONDS -lt $end ]; do
		if [ "$(gitlab_server_is_running | tail -1)" == "RUNNING" ]; then
			running="true"
			echo "RUNNING"; break;
		fi
	done
	if [ "$running" == "false" ]; then
		echo "ERROR, did not find the GitLab server running within $duration seconds!"
		#exit 1
	fi
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
# Structure:gitlab_status
#source src/helper.sh && get_build_status
get_build_status() {
	# load personal_access_token, gitlab username, repository name
	personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
	# shellcheck disable=SC2154
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	repo_name=$SOURCE_FOLDERNAME
	
	sleep 30
	
	# curl build status
	output=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/pipelines")
	
	#echo "gitlab_username=$gitlab_username"
	#echo "output=$output"
	#echo "repo_name=$repo_name"
	
	# Parse output to get build status
	
	allowed_substring='"status":"pending"'
	while [  "$(lines_contain_string "$allowed_substring" "${output}")" == "FOUND" ]; do
		sleep 3
		output=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/pipelines")
	done
	
	allowed_substring='"status":"running"'
	while [  "$(lines_contain_string "$allowed_substring" "${output}")" == "FOUND" ]; do
		sleep 3
		output=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/pipelines")
	done
	
	# check if status has error: all build statusses are returned, so need to check the 
	# first one, which represents the latest build.
	# TODO: parse the highest id from output, and find the accompanying latest build status
	failed_build='"status":"failed"'
	if [  "$(lines_contain_string "$failed_build" "${output}")" == "FOUND" ]; then
		echo "NOTFOUND"
	else
		expected_substring='"status":"success"'
		actual_result=$(lines_contain_string "$expected_substring" "${output}")
		echo "$actual_result"
	fi
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
# Structure:gitlab_status
# 6.f.1.helper0
# Verifies the current branch equals the incoming branch, throws an error otherwise.
################################## TODO: test function
assert_current_gitlab_branch() {
	gitlab_repo_name="$1"
	gitlab_branch_name="$2"
	company="GitLab"
	
	actual_result="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	if [ "$actual_result" != "$gitlab_branch_name" ]; then
		echo "The current Gitlab branch does not match the expected Gitlab branch:$gitlab_branch_name"
		exit 172
	fi
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
# Structure:gitlab_status
# 6.f.1.helper1
# TODO: test
get_current_gitlab_branch() {
	local gitlab_repo_name="$1"
	local gitlab_branch_name="$2"
	local company="$3"
	
	if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

		# Verify the branch exists
		branch_check_result="$(gitlab_branch_exists "$gitlab_repo_name" "$gitlab_branch_name")"
		read -p " in error: branch_check_result=$branch_check_result"
		last_line_branch_check_result=$(get_last_line_of_set_of_lines_without_evaluation_of_arg "${branch_check_result}")
		read -p " in error: last_line_branch_check_result=$last_line_branch_check_result"
		if [ "$last_line_branch_check_result" == "FOUND" ]; then
			# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Checkout the branch inside the repository.
			current_branch=$(cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git rev-parse --abbrev-ref HEAD)
			pwd_after="$PWD"
			# Verify the current path is the same as it was when this function started.
			path_before_equals_path_after_command "$pwd_before" "$pwd_after"
			echo "$current_branch"
		else
			
			# If the branch is newly created, but no commits are entered yet (=unborn branch), 
			# then it will not be found, because the git branch -all command, will not recognize
			# branches yet. So in this case, one can check if one is in the newly created branch
			# by evaluating the output of git status.
			current_branch="$(get_current_unborn_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name" "$company")"
			read -p "current_branch=$current_branch"
			if [ "$current_branch" == "$gitlab_branch_name" ]; then
				echo "$current_branch"
			else
				echo "Error, the Gitlab branch does not exist locally."
				exit 71
			fi
		fi
	else
		echo "ERROR, the Gitlab repository does not exist locally."
		exit 72
	fi
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
# Structure:gitlab_status
# 6.f.1.helper2
# Uses git status to get 1the current branch name. 
# This is used in case a new branch is created (unborn=no commits) 
#with checkout -b ...  to get the current GitLab branch name.
get_current_unborn_gitlab_branch() {
	local gitlab_repo_name="$1"
	local gitlab_branch_name="$2"
	local company="$3"
	
	if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
		# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Checkout the branch inside the repository.
			git_status_output=$(cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git status)
			pwd_after="$PWD"
			path_before_equals_path_after_command "$pwd_before" "$pwd_after"
			
			#current_unborn_gitlab_branch=$(parse_git_status_to_get_gitlab_branch "$git_status_output")
			current_unborn_gitlab_branch=$(parse_git_status_to_get_gitlab_branch "${git_status_output}")
			
			echo "$current_unborn_gitlab_branch"
	else 
		echo "ERROR, the Gitlab repository does not exist locally."
		exit 72
	fi
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
# Structure:gitlab_status
# 6.f.1.helper3
parse_git_status_to_get_gitlab_branch() {
	#eval lines="$1"
	local lines="$1"

	# get first line
	local line_nr=1 # lines start at index 1
	read -p "line_nr=$line_nr"
	
	local first_line=$(get_line_by_nr_from_variable "$line_nr" "${lines}")
	read -p "first_line=$first_line"

	if [ "${first_line:0:10}" == "On branch " ]; then
		# TODO: get remainder of first line
		# TODO: check if the line contains a space or newline character at the end.
		# shellcheck disable=SC2034
		len=${#first_line}
		echo "${first_line:10:${#first_line}}"
	else
		echo "ERROR, git status respons in the gitlab branch does not start with:On branch ."
		exit 72
	fi
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
# Structure:gitlab_status
# Echo's "NO" if the GitLab Runner is not installed, "YES" otherwise.
#+ TODO: Write test for this function in "modular-test_runner.bats".
#+ TODO: Verify the YES command is returned correctly when the GitLab runner is installed.
gitlab_runner_service_is_installed() {
	gitlab_runner_service_status=$( { sudo gitlab-runner status; } 2>&1 )
	if [  "$(lines_contain_string "gitlab-runner: the service is not installed" "${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "NO"
	elif [  "$(lines_contain_string "gitlab-runner: service in failed state" "${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "FAILED_STATE"
	elif [  "$(lines_contain_string "gitlab-runner: service is installed" "${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "YES"
	else
		printf "ERROR, the \n sudo gitlab-runner status\n was not as expected. Please run that command to see what its output is."
	fi
}