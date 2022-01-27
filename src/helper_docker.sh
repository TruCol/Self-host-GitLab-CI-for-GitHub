#!/bin/bash

#######################################
# Installs docker on the machine and verifies it is installed correctly.
# Run with: run bash -c "source src/import.sh && install_docker"
# Local variables:
# output
# Globals:
#  None.
# Arguments:
#   None
# Returns:
#  0 If the command was succesfull.
#  7 If the verification of the installation failed.
# Outputs:
#  The installation output.
#######################################
install_docker() {
	# If one gets warning: 
	#+  dpkg: warning: ignoring request to remove gitlab-runner_amd64 which isn't installed
	#+ it can be resolved by re-installing GitLab-runner. This can be done with:
	# sudo dpkg -i gitlab-runner.deb
	#+ Same if the sudo apt install docker-compose command throws an error saying
	#+ need gitlab runner to be re-installed but can't find the package.
	local output=$(yes | sudo apt install docker.io)
	echo "$output"
	
	# Verify the docker is indeed installed
	assert_docker_is_installed
	$(assert_docker_is_installed)
}

# run with: source src/helper_docker.sh && safely_check_if_program_is_installed docker
safely_check_if_program_is_installed() {
	program_name="$1"
	if ! foobar_loc="$(type -p "$program_name")" || [[ -z $foobar_loc ]]; then
		# install foobar here
		echo "NOTFOUND"
	else
		echo "FOUND"
	fi
}

sudo_safely_check_if_program_is_installed() {
	program_name="$1"
	if ! foobar_loc="$(sudo type -p "$program_name")" || [[ -z $foobar_loc ]]; then
		# install foobar here
		echo "NOTFOUND"
	else
		echo "FOUND"
	fi
}

#######################################
# Fully remove docker from the machine and verifies it is removed correctly.
# Note this does not delete docker compose. (/usr/local/bin/docker-compose)
# Source: https://askubuntu.com/a/1021506
# Run with: source src/import.sh && completely_remove_docker
# Local variables:
# output
# Globals:
#  None.
# Arguments:
#   None
# Returns:
#  0 If the command was succesfull.
#  7 If the verification of the installation failed.
# Outputs:
#  The installation output.
#######################################
completely_remove_docker() {
	
	safely_remove_docker
	
	# TODO: include checks to safely remove it (e.g. prevent docker-ce not found)

	# Identify which docker package is installed.
	dpkg -l | grep -i docker
	
	# Remove the installed docker programs.
	sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
	sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce
	
	
	sudo rm -rf /var/lib/docker /etc/docker
	sudo rm /etc/apparmor.d/docker
	sudo groupdel docker
	sudo rm -rf /var/run/docker.sock
	
	#
	sudo rm -r /etc/docker
}

# run with: source src/helper_docker.sh && safely_remove_docker
safely_remove_docker() {
	if [ $(safely_check_if_program_is_installed "docker") == "FOUND" ]; then
		remove_docker
	fi
}

safely_completely_remove_docker() {
	if [ $(safely_check_if_program_is_installed "docker") == "FOUND" ]; then
		# TODO: also make this function safe.
		completely_remove_docker
	fi
}

#######################################
# Removes docker on the machine and verifies it is removed correctly.
# Run with: source src/import.sh && remove_docker
# Local variables:
# output
# Globals:
#  None.
# Arguments:
#   None
# Returns:
#  0 If the command was succesfull.
#  7 If the verification of the installation failed.
# Outputs:
#  The installation output.
#######################################
remove_docker() {
	# If one gets warning: 
	#+  dpkg: warning: ignoring request to remove gitlab-runner_amd64 which isn't installed
	#+ it can be resolved by re-installing GitLab-runner. This can be done with:
	# sudo dpkg -i gitlab-runner.deb
	#+ Same if the sudo apt install docker-compose command throws an error saying
	#+ need gitlab runner to be re-installed but can't find the package.
	local output_one=$(yes | sudo apt remove docker)
	local output_two=$(yes | sudo apt remove docker.io)
	echo "$output_one"
	echo "$output_two"
	
	#assert_docker_is_installed
	# TODO: assert docker is removed.
	
}



#######################################
# Verifies docker is installed correctly, throws error otherwise.
# Run with: source src/import.sh && install_docker
# Local variables:
# docker_version_response
# Globals:
#  None.
# Arguments:
#   None
# Returns:
#  0 If the command was succesfull.
#  7 If the verification of the docker installation failed.
# Outputs:
#  None
#######################################
assert_docker_is_installed() {

	# Get the docker version response to see if it is installed.
	docker_version_response=$(get_docker_version)
	#echo "docker_version_response=$docker_version_response"
	
	
	# Verify docker is installed by parsing the version response.
	if [  "$(lines_contain_string "Docker version 2" "\${docker_version_response}")" == "NOTFOUND" ] || [ "$docker_version_response" == "" ]; then
		echo "Docker is not correctly installed on this system. The docker --version response was:$docker_version_response"
		exit 112
	fi
}

#######################################
# Gets the version response of the docker command.
# Local variables:
# output
# Globals:
#  None.
# Arguments:
#   None
# Returns:
#  0 If the command was succesfull.
# Outputs:
#  The response to the docker version command.
#######################################
get_docker_version() {
	#docker --version
	#docker --version
	local output=$(docker --version)
	echo "$output"
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
# Structure:gitlab_docker
docker_image_exists() {
	# shellcheck disable=SC2034
	image_name=$1
	docker_image_identifier=$(get_docker_image_identifier "$gitlab_package")
	
	if [ "$(sudo docker ps -q -f name="$docker_image_identifier")" ]; then
		echo "YES"
	elif [ ! "$(sudo docker ps -q -f name="$docker_image_identifier")" ]; then
		echo "NO"
	else
		echo "ERROR, the docker image was not not found, nor found."
		exit 26
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
# Structure:gitlab_docker
install_docker_compose() {
	output=$(yes | sudo apt install docker-compose)
	echo "$output"
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
# Structure:gitlab_docker
# Returns FOUND if the container is running, returns NOTFOUND if it is not running
container_is_running() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# check if the Docker container exists
	container_exists=$(docker_image_exists "$docker_image_name")
	
	if [ "$container_exists" == "NO" ]; then
		echo "NOTFOUND"
	elif [ "$container_exists" == "YES" ]; then
		# Check if the container is running
		running_containers_output=$(sudo docker ps --filter status=running)
		cmd "$(lines_contain_string "$docker_container_id" "\"${running_containers_output}")"
	else
		echo "NOTFOUND"
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
# Structure:gitlab_docker
get_docker_container_id_of_gitlab_server() {
	# echo's the Docker container id if it is found, silent otherwise.
	space=" "
	log_filepath=$LOG_LOCATION"docker_container.txt"
	gitlab_package=$(get_gitlab_package)
	
	# TODO: select gitlab_package substring rhs up to / (the sed command does not handle this well)
	# TODO: OR replace / with \/ (that works)
	identification_str=$(get_rhs_of_line_till_character "$gitlab_package" "/")
	
	# write output to file
	output=$(sudo docker ps -a | sudo tee "$log_filepath")
	# Get line with "gitlab/gitlab-ce:latest" (package name depending on architecture).
	line=$(get_first_line_containing_substring "$log_filepath" "\${identification_str}")
	#echo "line=$line"
	
	
	# Get container id of the line containing the id.
	container_id=$(get_lhs_of_line_till_character "$line" "$space")
	#read -p "CONFIRM BELOW in, container_id=$container_id"

	# delete the file as cleanup if it exist
	if [ -f "$log_filepath" ] ; then
	    sudo rm "$log_filepath"
	fi
	
	echo "$container_id"
}
# Structure:gitlab_docker
get_docker_image_identifier() {
	docker_image_name=$1
	echo "$(get_lhs_of_line_till_character "$docker_image_name" "/")"
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
# Structure:gitlab_docker
docker_image_exists() {
	# shellcheck disable=SC2034
	image_name=$1
	docker_image_identifier=$(get_docker_image_identifier "$gitlab_package")
	
	if [ "$(sudo docker ps -q -f name="$docker_image_identifier")" ]; then
		echo "YES"
	elif [ ! "$(sudo docker ps -q -f name="$docker_image_identifier")" ]; then
		echo "NO"
	else
		echo "ERROR, the docker image was not not found, nor found."
		exit 26
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
# Structure:gitlab_docker
# Returns FOUND if the container is running, returns NOTFOUND if it is not running
container_is_running() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# check if the Docker container exists
	container_exists=$(docker_image_exists "$docker_image_name")
	
	if [ "$container_exists" == "NO" ]; then
		echo "NOTFOUND"
	elif [ "$container_exists" == "YES" ]; then
		# Check if the container is running
		running_containers_output=$(sudo docker ps --filter status=running)
		echo "$(lines_contain_string "$docker_container_id" "\"${running_containers_output}")"
	else
		echo "NOTFOUND"
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
# Structure:gitlab_docker
# Stop docker
stop_docker() {
	output=$(sudo systemctl stop docker)
	echo "$output"
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
# Structure:gitlab_docker
# start docker
start_docker() {
	output=$(sudo systemctl start docker)
	#output=$(systemctl reset-failed docker.service)
	echo "$output"
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
# Structure:gitlab_docker
# Delete all existing gitlab containers
# 0. First clear all relevant containres using their NAMES:
list_all_docker_containers() {
	output=$(sudo docker ps -a)
	echo "$output"
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
# Structure:gitlab_docker
stop_gitlab_package_docker() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then		
		# Stop Gitlab Docker container
		# shellcheck disable=SC2034
		stopped=$(sudo docker stop "$docker_container_id")
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
# Structure:gitlab_docker
remove_gitlab_package_docker() {
	
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
		
		# stop the container id if it is running
		stop_gitlab_package_docker
		
		# Remove_gitlab_package_docker "$docker_container_id"
		# shellcheck disable=SC2034
		removed=$(sudo docker rm "$docker_container_id")
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
# Structure:gitlab_docker
# Remove all containers
remove_gitlab_docker_containers() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
	
		output=$(sudo docker rm -f "$docker_container_id")
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
# Structure:dir_edit
sudo_create_dir() {
	abs_dir=$1
	if [ "$(sudo_dir_exists "$abs_dir")" == "NOTFOUND" ]; then
		sudo mkdir "$abs_dir"
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
# Structure:dir_edit
docker_sudo_create_dir(){
	abs_dir=$1
	docker_container_id=$2
	dir_exists=$(sudo docker exec -i "$docker_container_id" bash -c "if test -d $abs_dir; then echo 'FOUND'; fi ")
	echo "dir_exists=$dir_exists"
	echo "docker_container_id=$docker_container_id"
	echo "abs_dir=$abs_dir"
	if [ "$dir_exists" != "FOUND" ]; then
		echo "Creating dir"
		sudo docker exec -i "$docker_container_id" bash -c "mkdir $abs_dir"
	fi
}