#!/bin/bash
source src/hardcoded_variables.txt
source src/creds.txt

# Determine architecture of the machine on which this service is ran.
# Source: https://askubuntu.com/questions/189640/how-to-find-architecture-of-my-pc-and-ubuntu
get_architecture() {
	architecture=$(uname -m)
	# TODO: replace with: dpkg --print-architecture and remove if condition
	
	# Parse architecture to what is available for GitLab Runner
	# Source: https://stackoverflow.com/questions/65450286/how-to-install-gitlab-runner-to-centos-fedora
	if [ "$architecture"=="x86_64" ]; then
		architecture=amd64
	else
		read -p "ERROR, did not yet find GitLab installation package and GitLab runner installation package for this architecture:$architecture"
	fi
	
	echo $architecture
}

# Checks whether the md5 checkum of the file specified with the incoming filepath
# matches that of an expected md5 filepath that is incoming.
# echo's "EQUAL" if the the expected md5sum equals the measured md5sum
# returns "NOTEQUAL" otherwise.
check_md5_sum() {
	expected_md5=$1
	REL_FILEPATH=$2
	
	# Read out the md5 checksum of the downloaded social package.
	md5sum=$(sudo md5sum "$REL_FILEPATH")
	
	# Extract actual md5 checksum from the md5 command response.
	md5sum_head=${md5sum:0:32}
	
	# Assert the measured md5 checksum equals the hardcoded md5 checksum of the expected file.
	#assert_equal "$md5_of_social_package_head" "$TWRP_MD5"
	if [ "$md5sum_head" == "$expected_md5" ]; then
		echo "EQUAL"
	else
		echo "NOTEQUAL"
	fi
}


# Computes the md5sum of the GitLab installation file that is being downloaded
# with respect to the expected md5sum of that file. (For safety).
# 
get_expected_md5sum_of_gitlab_runner_installer_for_architecture() {
	arch=$1
	if [ "$arch" == "amd64" ]; then
		echo $x86_64_runner_checksum
	else
		read -p "ERROR, this architecture:$arch is not yet supported by this repository, meaning we did not yet find a GitLab runner package for this architecture. So there is no md5sum available for verification of the md5 checksum of such a downloaded package."
		#exit 1
	fi
}


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


# Downloads the source code of an incoming website into a file.
# TODO: ensure/verify curl is installed before calling this method.
downoad_website_source() {
	site=$1
	output_path=$2
	
	output=$(curl "$site" > "$output_path")
}


get_last_n_lines_without_spaces() {
	number=$1
	REL_FILEPATH=$2
	
	# get last number lines of file
	last_number_of_lines=$(sudo tail -n "$number" "$REL_FILEPATH")
	
	# Output true or false to pass the equality test result to parent function
	echo $last_number_of_lines
}

# allows a string with spaces, hence allows a line
file_contains_string() {
	STRING=$1
	REL_FILEPATH=$2
	
	if [[ ! -z $(grep "$STRING" "$REL_FILEPATH") ]]; then 
		echo "FOUND"; 
	else
		echo "NOTFOUND";
	fi
}

lines_contain_string() {
	STRING=$1
	eval lines=$2
	if [[ $lines =~ "$STRING" ]]; then
		echo "FOUND"; 
	else
		echo "NOTFOUND";
	fi
}


get_line_nr() {
	eval STRING="$1"
	REL_FILEPATH=$2
	line_nr=$(awk "/$STRING/{ print NR; exit }" $REL_FILEPATH)
	echo $line_nr
}

get_line_by_nr() {
	number=$1
	REL_FILEPATH=$2
	#read -p "number=$number"
	#read -p "REL_FILEPATH=$REL_FILEPATH"
	the_line=$(sed "${number}q;d" $REL_FILEPATH)
	echo $the_line
}

get_line_by_nr_from_variable() {
	number=$1
	eval lines=$2
	
	count=0
	while IFS= read -r line; do
		count=$((count+1))
		if [ "$count" -eq "$number" ]; then
			echo "$line"
		fi
	done <<< "$lines"
}

get_first_line_containing_substring() {
	# Returns the first line in a file that contains a substring, silent otherwise.
	eval REL_FILEPATH="$1"
	eval identification_str="$2"
	
	# Get line containing <code id="registration_token">
	if [ "$(file_contains_string "$identification_str" "$REL_FILEPATH")" == "FOUND" ]; then
		line_nr=$(get_line_nr "\${identification_str}" $REL_FILEPATH)
		if [ "$line_nr" != "" ]; then
			#read -p "ABOVE and line_nr=$line_nr"
			line=$(get_line_by_nr $line_nr $REL_FILEPATH)
			#read -p "BELOW"
			echo "$line"
		else
			#read -p "ERROR, did find the string in the file but did not find the line number, identification str =\${identification_str} And filecontent=$(cat $REL_FILEPATH)"
			#exit 1
			true #equivalent of Python pass
		fi
	else
		#read -p "ERROR, did not find the string in the file identification str =\${identification_str} And filecontent=$(cat $REL_FILEPATH)"
		#exit 1
		true #equivalent of Python pass
	fi
}


get_lhs_of_line_till_character() {
	line=$1
	character=$2
	
	# TODO: implement
	#lhs=${line%$character*}
	#read -p "line=$line"
	#read -p "character=$character"

	lhs=$(cut -d "$character" -f1 <<< "$line")
	echo $lhs
}

get_rhs_of_line_till_character() {
	# TODO: include space right after character, e.g. return " with" instead of "width" on ": with".
	line=$1
	character=$2
	
	rhs=$(cut -d "$character" -f2- <<< "$line")
	echo $rhs
}


get_docker_container_id_of_gitlab_server() {
	# echo's the Docker container id if it is found, silent otherwise.
	space=" "
	log_filepath=$LOG_LOCATION"docker_container.txt"
	gitlab_package=$(get_gitlab_package)
	
	# TODO: select gitlab_package substring rhs up to / (the sed command does not handle this well)
	# TODO: OR replace / with \/ (that works)
	identification_str=$(get_rhs_of_line_till_character "$gitlab_package" "/")
	
	# write output to file
	output=$(sudo docker ps -a > $log_filepath)
	# Get line with "gitlab/gitlab-ce:latest" (package name depending on architecture).
	line=$(get_first_line_containing_substring "$log_filepath" "\${identification_str}")
	#echo "line=$line"
	
	
	# Get container id of the line containing the id.
	container_id=$(get_lhs_of_line_till_character "$line" "$space")
	#read -p "CONFIRM BELOW in, container_id=$container_id"

	# delete the file as cleanup if it exist
	if [ -f "$log_filepath" ] ; then
	    rm "$log_filepath"
	fi
	
	echo $container_id
}

get_docker_image_identifier() {
	docker_image_name=$1
	echo $(get_lhs_of_line_till_character "$docker_image_name" "/")
}

visudo_contains() {
	line=$1
	#echo "line=$line"
	visudo_content=$(sudo cat /etc/sudoers)
	#echo $visudo_content
	
	actual_result=$(lines_contain_string "$line" "\${visudo_content}")
	echo $actual_result
}


# gitlab runner status:
check_gitlab_runner_status() {
	status=$(sudo gitlab-runner status)
	echo "$status"
}

# gitlab server status:
#sudo docker exec -i 79751949c099 bash -c "gitlab-rails status"
#sudo docker exec -i 79751949c099 bash -c "gitlab-ctl status"
check_gitlab_server_status() {
	##read -p "CONFIRM ABOVE check"
	container_id=$(get_docker_container_id_of_gitlab_server)
	#read -p "CONFIRM BELOW check and container_id=$container_id"
	#echo "container_id=$container_id"
	status=$(sudo docker exec -i "$container_id" bash -c "gitlab-ctl status")
	echo "$status"
}

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

# reconfigure:
#sudo docker exec -i 4544ce711468 bash -c "gitlab-ctl reconfigure"

# Runs for $duration [seconds] and checks whether the GitLab server status is: RUNNING.
# Throws an error and terminates the code if the GitLab server status is not found to be
# running within $duration [seconds]
check_for_n_seconds_if_gitlab_server_is_running() {
	duration=$1
	running="false"
	end=$(("$SECONDS" + "$duration"))
	while [ $SECONDS -lt $end ]; do
		if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
			running="true"
			echo "RUNNING"; break;
		fi
	done
	if [ "$running" == "false" ]; then
		echo "ERROR, did not find the GitLab server running within $duration seconds!"
		#exit 1
	fi
}

get_nr_of_lines_in_var() {
	eval lines=$1
	echo "$lines" | wc -l
}

get_last_line_of_set_of_lines() {
	eval lines=$1
	set -f # disable glob (wildcard) expansion
	IFS=$'\n' # let's make sure we split on newline chars
	var=(${lines}) # parse the lines into a variable that is countable
	nr_of_lines=${#var[@]}
	last_line=$(get_line_by_nr_from_variable "$nr_of_lines" "\${lines}")
	echo "$last_line"
}

docker_image_exists() {
	image_name=$1
	docker_image_identifier=$(get_docker_image_identifier "$gitlab_package")
	
	if [ "$(sudo docker ps -q -f name=$docker_image_identifier)" ]; then
		echo "YES"
	elif [ ! "$(sudo docker ps -q -f name=$docker_image_identifier)" ]; then
		echo "NO"
	else
		echo "ERROR, the docker image was not not found, nor found."
		exit 1
	fi
}


# Returns FOUND if the container is running, returns NOTFOUND if it is not running
container_is_running() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# check if the Docker container exists
	container_exists=$(docker_image_exists $docker_image_name)
	
	if [ "$container_exists" == "NO" ]; then
		echo "NOTFOUND"
	elif [ "$container_exists" == "YES" ]; then
		# Check if the container is running
		running_containers_output=$(sudo docker ps --filter status=running)
		echo $(lines_contain_string "$docker_container_id" "\${running_containers_output}")
	else
		echo "NOTFOUND"
	fi
}

# Returns "FOUND" if the service is found, NOTFOUND otherwise
# TODO: write test for case when apache2 is actually running.
apache2_is_running() {
	status=$(sudo service apache2 --status-all)
	echo $(lines_contain_string "unrecognized service" "\${status}")
}


# Returns "FOUND" if the service is found, NOTFOUND otherwise
# TODO: write test for case when nginx is actually running.
nginx_is_running() {

	status=$(sudo service nginx --status-all)
	echo $(lines_contain_string "unrecognized service" "\${status}")
}





####### STOP START SERVICES
# Install docker:
install_docker() {
	# If one gets warning: 
	#+  dpkg: warning: ignoring request to remove gitlab-runner_amd64 which isn't installed
	#+ it can be resolved by re-installing GitLab-runner. This can be done with:
	# sudo dpkg -i gitlab-runner.deb
	#+ Same if the sudo apt install docker-compose command throws an error saying
	#+ need gitlab runner to be re-installed but can't find the package.
	output=$(yes | sudo apt install docker)
	echo "$output"
}

install_docker_compose() {
	output=$(yes | sudo apt install docker-compose)
	echo "$output"
}

# Stop docker
stop_docker() {
	output=$(sudo systemctl stop docker)
	echo "$output"
}

# start docker
start_docker() {
	output=$(sudo systemctl start docker)
	#output=$(systemctl reset-failed docker.service)
	echo "$output"
}

# Delete all existing gitlab containers
# 0. First clear all relevant containres using their NAMES:
list_all_docker_containers() {
	output=$(sudo docker ps -a)
	echo "$output"
}

stop_gitlab_package_docker() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then		
		# Stop Gitlab Docker container
		stopped=$(sudo docker stop "$docker_container_id")
	fi
}

remove_gitlab_package_docker() {
	
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
		
		# stop the container id if it is running
		stop_gitlab_package_docker
		
		# Remove_gitlab_package_docker "$docker_container_id"
		removed=$(sudo docker rm $docker_container_id)
	fi
}

# Remove all containers
remove_gitlab_docker_containers() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
	
		output=$(sudo docker rm -f $docker_container_id)
		echo "$output"
	fi
}


# stop ngix service
stop_apache_service() {
	
	if [ "$(apache2_is_running)" == "FOUND" ]; then
		output=$(sudo service apache2 stop)
		echo "$output"
	fi
}

#source src/helper.sh && stop_nginx_service
stop_nginx_service() {
	services_list=$(systemctl list-units --type=service)
	if [  "$(lines_contain_string "nginx" "\${services_list}")" == "FOUND" ]; then
		output=$(sudo service nginx stop)
		echo "$output"
	fi

}

# TODO: verify if it can be ommitted
#stop_nginx() {
#	output=$(sudo nginx -s stop)
#	echo "$output"
#}

# Echo's "NO" if the GitLab Runner is not installed, "YES" otherwise.
#+ TODO: Write test for this function in "modular-test_runner.bats".
#+ TODO: Verify the YES command is returned correctly when the GitLab runner is installed.
gitlab_runner_service_is_installed() {
	gitlab_runner_service_status=$( { sudo gitlab-runner status; } 2>&1 )
	if [  "$(lines_contain_string "gitlab-runner: the service is not installed" "\${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "NO"
	elif [  "$(lines_contain_string "gitlab-runner: service in failed state" "\${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "FAILED_STATE"
	elif [  "$(lines_contain_string "gitlab-runner: service is installed" "\${gitlab_runner_service_status}")" == "FOUND" ]; then
		echo "YES"
	else
		echo "ERROR, the \n sudo gitlab-runner status\n was not as expected. Please run that command to see what its output is."
	fi
}

#source src/helper.sh && get_build_status
get_build_status() {
	# load personal_access_token, gitlab username, repository name
	personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
	gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
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
		echo $actual_result
	fi
}
