#!/bin/bash

#######################################
# Returns the architecture of the machine on which this service is ran.
# Source: https://askubuntu.com/questions/189640/how-to-find-architecture-of-my-pc-and-ubuntu
# Local variables:
#  architecture
# mapped_architecture
# Globals:
#  None.
# Arguments:
#   The detected architecture of the device on which this code is running.
# Returns:
#  0 if funciton was evaluated succesfull.
#  14 if the code is ran on an architecture that is not (yet) supported.
# Outputs:
#  A string that represents the architecture on which this code is running. 
# The code that detects the architecture on the device returns something
# diffent (x86_64) than the identifier that GitLab uses to indicate which 
# architecture is used (amd64). That is why the detected architecture is 
# mapped. 
#######################################
# Structure: configuration/hardware
get_architecture() {
	local architecture=$(uname -m)
	# TODO: replace with: dpkg --print-architecture and remove if condition
	
	# Parse architecture to what is available for GitLab Runner
	# Source: https://stackoverflow.com/questions/65450286/how-to-install-gitlab-runner-to-centos-fedora
	if [ "$architecture" == "x86_64" ]; then
		local mapped_architecture=amd64
	else
		error "ERROR, did not yet find GitLab installation package and GitLab runner installation package for this architecture:$architecture"
		exit 14
	fi
	
	echo $mapped_architecture
}


#######################################
# Checks whether the md5 checkum of the file specified with the incoming filepath
# matches that of an expected md5 filepath that is incoming.
# Local variables:
# expected_md5sum
# relative_filepath
# actual_md5sum
# actual_md5sum_head
# Globals:
#  None.
# Arguments:
#  expected_md5sum - the md5sum that is expected to be found at some file/dir.
#  relative_filepath - Filepath to file/dir whose md5sum is computed, seen from 
#  the root directory of this repository.
# Returns:
#  0 at all times, unless an unexpected error is thrown by e.g. md5sum.
# Outputs:
#  "EQUAL" if the the expected md5sum equals the measured md5sum.
# "NOTEQUAL" otherwise.
# TODO(a-t-0): rename the method to "check if md5sum is as expected.
# TODO(a-t-0): Create a duplicate named "assert.." that throws an error if the
# md5sum of the dir/file that is being inspected, is different than expected.
#######################################
# Structure:Verification
check_md5_sum() {
	local expected_md5sum=$1
	local relative_filepath=$2
	
	# Read out the md5 checksum of the downloaded social package.
	local actual_md5sum=$(sudo md5sum "$relative_filepath")
	
	# Extract actual md5 checksum from the md5 command response.
	local actual_md5sum_head=${actual_md5sum:0:32}
	
	# Assert the measured md5 checksum equals the hardcoded md5 checksum of the expected file.
	#manual_assert_equal "$md5_of_social_package_head" "$TWRP_MD5"
	if [ "$actual_md5sum_head" == "$expected_md5sum" ]; then
		echo "EQUAL"
	else
		echo "NOTEQUAL"
	fi
}

#######################################
# Calls the function that computes the md5sum of the GitLab installation file 
# that is being downloaded for the architecture that's detected in this system.
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
# TODO(a-t-0): Make this function call a hardcoded list/swtich case of expected
# md5sums from eg hardcoded variables.txt, and make it automatically 
# compute the md5sum of the respective architecture.
# TODO(a-t-0):  Run the "has supported architecture check before running the 
# md5 check.
#######################################
# Structure:Verification
# 
# 
get_expected_md5sum_of_gitlab_runner_installer_for_architecture() {
	local mapped_architecture=$1
	if [ "$mapped_architecture" == "amd64" ]; then
		# shellcheck disable=SC2154
		echo $x86_64_runner_checksum
	else
		echo "ERROR, this architecture:$mapped_architecture is not yet supported by this repository, meaning we did not yet find a GitLab runner package for this architecture. So there is no md5sum available for verification of the md5 checksum of such a downloaded package."
		exit 15
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
# Structure:Configuration
# Returns the GitLab installation package name that matches the architecture of the device 
# on which it is installed. Not every package/GitLab source repository works on each computer/architecture.
# Currently working GitLab installation packages have only been found for the amd64 architecture and 
# the RaspberryPi 4b architectures have been verified.
get_gitlab_package() {
	architecture=$(dpkg --print-architecture)
	if [ "$architecture" == "amd64" ]; then
		echo "$GITLAB_DEFAULT_PACKAGE"
	elif [ "$architecture" == "armhf" ]; then
		echo "$GITLAB_RASPBERRY_PACKAGE"
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
# Structure:html
# Downloads the source code of an incoming website into a file.
# TODO: ensure/verify curl is installed before calling this method.
downoad_website_source() {
	site=$1
	output_path=$2
	
	output=$(curl "$site" > "$output_path")
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
# Structure:Configuration
visudo_contains() {
	line=$1
	#echo "line=$line"
	visudo_content=$(sudo cat /etc/sudoers)
	#echo $visudo_content
	
	actual_result=$(lines_contain_string "$line" "\"${visudo_content}")
	echo "$actual_result"
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
# gitlab runner status:
check_gitlab_runner_status() {
	status=$(sudo gitlab-runner status)
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
#sudo docker exec -i 79751949c099 bash -c "gitlab-rails status"
#sudo docker exec -i 79751949c099 bash -c "gitlab-ctl status"
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
	actual_result=$(check_gitlab_server_status)
	if
	[  "$(lines_contain_string 'run: alertmanager: (pid ' "\${actual_result}")" == "FOUND" ] &&
	[  "$(lines_contain_string 'run: gitaly: (pid ' "\${actual_result}")" == "FOUND" ] &&
	[  "$(lines_contain_string 'run: gitlab-exporter: (pid ' "\${actual_result}")" == "FOUND" ] &&
	[  "$(lines_contain_string 'run: gitlab-workhorse: (pid ' "\${actual_result}")" == "FOUND" ] &&
	[  "$(lines_contain_string 'run: grafana: (pid ' "\${actual_result}")" == "FOUND" ] &&
	[  "$(lines_contain_string 'run: logrotate: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: nginx: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: postgres-exporter: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: postgresql: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: prometheus: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: puma: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: redis: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: redis-exporter: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: sidekiq: (pid ' "\${actual_result}")" == "FOUND" ] &&
    [  "$(lines_contain_string 'run: sshd: (pid ' "\${actual_result}")" == "FOUND" ]
	then
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
# Structure:status
# Returns "FOUND" if the service is found, NOTFOUND otherwise
# TODO: write test for case when apache2 is actually running.
apache2_is_running() {
	status=$(sudo service apache2 --status-all)
	#cmd="$(lines_contain_string "unrecognized service" "\${status}")"
	#"$(lines_contain_string "unrecognized service" "\${status}")"
	lines_contain_string "unrecognized service" "\${status}"
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
# Structure:status
# Returns "FOUND" if the service is found, NOTFOUND otherwise
# TODO: write test for case when nginx is actually running.
nginx_is_running() {

	status=$(sudo service nginx --status-all)
	#cmd="$(lines_contain_string "unrecognized service" "\${status}")"
	lines_contain_string "unrecognized service" "\${status}"
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
# Structure:status
# stop ngix service
stop_apache_service() {
	
	if [ "$(apache2_is_running)" == "FOUND" ]; then
		output=$(sudo service apache2 stop)
		echo "$output"
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
# TODO(a-t-0): include throwing warning if nginx was not found (but removed).
#######################################
# Structure:status
#source src/helper.sh && stop_nginx_service
stop_nginx_service() {
	local services_list=$(systemctl list-units --type=service)
	if [  "$(lines_contain_string "nginx" "${services_list}")" == "FOUND" ]; then
		output=$(sudo service nginx stop)
		echo "$output"
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
	if [  "$(lines_contain_string "gitlab-runner: the service is not installed" "\"${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "NO"
	elif [  "$(lines_contain_string "gitlab-runner: service in failed state" "\"${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "FAILED_STATE"
	elif [  "$(lines_contain_string "gitlab-runner: service is installed" "\"${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "YES"
	else
		printf "ERROR, the \n sudo gitlab-runner status\n was not as expected. Please run that command to see what its output is."
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
	while [  "$(lines_contain_string "$allowed_substring" "\${output}")" == "FOUND" ]; do
		sleep 3
		output=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/pipelines")
	done
	
	allowed_substring='"status":"running"'
	while [  "$(lines_contain_string "$allowed_substring" "\${output}")" == "FOUND" ]; do
		sleep 3
		output=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/pipelines")
	done
	
	# check if status has error: all build statusses are returned, so need to check the 
	# first one, which represents the latest build.
	# TODO: parse the highest id from output, and find the accompanying latest build status
	failed_build='"status":"failed"'
	if [  "$(lines_contain_string "$failed_build" "\${output}")" == "FOUND" ]; then
		echo "NOTFOUND"
	else
		expected_substring='"status":"success"'
		actual_result=$(lines_contain_string "$expected_substring" "\${output}")
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
# Structure:Parsing
get_array() {
	json=$1
	identifier=$2
	# shellcheck disable=SC2034
	nr_of_elements=$(echo "$json" | jq 'length')
	
	readarray -t commit_array <  <(echo "$json" | jq ".[].$identifier")
	# loop through elements
	#for i in {0.."$nr_of_elements"}
	#do
	#	echo "Welcome $i times"
	#	sleep 1
	#done
	#echo "$commit_array"
	echo  "${commit_array[@]}"
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
	gitlab_repo_name="$1"
	gitlab_branch_name="$2"
	company="$3"
	
	if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

		# Verify the branch exists
		branch_check_result="$(gitlab_branch_exists "$gitlab_repo_name" "$gitlab_branch_name")"
		#echo "branch_check_result=$branch_check_result"
		last_line_branch_check_result=$(get_last_line_of_set_of_lines "\"${branch_check_result}")
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
	gitlab_repo_name="$1"
	gitlab_branch_name="$2"
	company="$3"
	
	if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
		# Get the path before executing the command (to verify it is restored correctly after).
			pwd_before="$PWD"
			
			# Checkout the branch inside the repository.
			git_status_output=$(cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git status)
			pwd_after="$PWD"
			path_before_equals_path_after_command "$pwd_before" "$pwd_after"
			
			#current_unborn_gitlab_branch=$(parse_git_status_to_get_gitlab_branch "$git_status_output")
			current_unborn_gitlab_branch=$(parse_git_status_to_get_gitlab_branch "\"${git_status_output}")
			
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
	eval lines="$1"
		
	# get first line
	line_nr=1 # lines start at index 1
	first_line=$(get_line_by_nr_from_variable "$line_nr" "\${lines}")
	
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
# Verifies the current branch equals the incoming branch, throws an error otherwise.
################################## TODO: test function
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
delete_all_gitlab_files() {
	source_dir="$1"
	
	for f in $source_dir
	do
	if [ -f "$f" ]; then
		echo "File DELETE $f"
		rm "$f"
	fi
	done
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
delete_all_gitlab_folders() {
	source_dir="$1"
	
	for f in $source_dir
	do
	if [ -d "$f" ]; then
		if [[ "${f: -2}" != "/." && "${f: -3}" != "/.." && "${f: -5}" != "/.git" ]]; then
			echo "Dir Delete $f"
			rm -r "$f"
		else
			echo "Dir EXCLUDE FROM DELETE $f"
		fi
	fi
	done
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
copy_all_gitlab_files() {
	source_dir="$1"
	target_dir="$2"
	
	for f in $source_dir
	do
	if [ -f "$f" ]; then
		echo "File Copy $f"
		cp -r "$f" "$target_dir"
	fi
	done
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
copy_all_gitlab_folders() {
	source_dir="$1"
	target_dir="$2"
	
	for f in $source_dir
	do
	if [ -d "$f" ]; then
		if [[ "${f: -2}" != "/." && "${f: -3}" != "/.." && "${f: -5}" != "/.git" ]]; then
			echo "Dir Copy $f to $target_dir"
			cp -r "$f" "$target_dir"
			#cp "$f" "$target_dir"
		else
			echo "Dir EXCLUDE FROM COPY $f"
		fi
	fi
	done
}