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
# Kills the sshd process to prevent the:
# Error starting userland proxy: listen tcp4 0.0.0.0:23 bind: address already 
# in use.
# error. This error also occurs on port 443 on the docker-pr service.
# Source: https://github.com/Simple-Setup/Self-host-GitLab-Server-and-Runner-CI/issues/13
# run with: source src/import.sh && remove_sshd 22
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
#   
#######################################
# TODO: loop through numbers *:22 and *:443 (TODO: get the list of numbers from
# *:* command, and seeking which programs start with sshd and/or docker-pr) 
# untill all processes on these ports have been killed, and then assert they
# are indeed killed.
remove_sshd() {
	local target_port=$1
	local response_lines=$(sudo lsof -i -P -n | grep *:$target_port)
	
	
	#if [ "${response_lines:0:4}" == "sshd" ]; then
	if [ "${response_lines:0:4}" == "sshd" ]; then
		kill_a_program_with_program_nr "sshd"
	elif [ "${response_lines:0:9}" == "docker-pr" ]; then
		kill_a_program_with_program_nr "docker-pr"
	elif [ "$response_lines" == "" ]; then
			echo "sshd process:$target_port already killed."	
	else
		echo "The response to the lsof command does not start with:sshd"
		exit 7
	fi
	
	# TODO: ensure it works.
	assert_sshd_process_is_not_running_anymore
}


#######################################
# Gets the program number from the lsof command output (program description).
# Then kills that program using its program number.
# Local variables:
#  program_description
#  len_program_description
#  first_line
# Globals:
#  None.
# Arguments:
#   The detected architecture of the device on which this code is running.
# Returns:
#  0 if funciton was evaluated succesfull.
#  7 if the sshd service is still running.
# Outputs:
#  None.
#######################################
kill_a_program_with_program_nr() {
	local program_description="$1"
	local len_program_description=${#program_description} 

	local response_lines=$(sudo lsof -i -P -n | grep *:$target_port)
	
	# Ensure first line with docker program is evaluated.
	local line_nr=1 # lines start at index 1
	
	# Get the first line of the lsof output.
	local first_line=$(get_line_by_nr_from_variable "$line_nr" "${response_lines}")
	read -p "first_line=$first_line"
	
	# Get the string starting with the program number from first line.
	local prog_nr_str=$(stringStripNCharsFromStart "$first_line" $len_program_description)
	read -p "prog_nr_str=$prog_nr_str"
	
	# Get the first digits representing the number of the program.
	prog_nr=$(echo "$prog_nr_str" | cut -d' ' -f1)
	read -p "prog_nr=$prog_nr"

	# Kill the program through its program number.
	sudo kill "$prog_nr"
}

#######################################
# Asserts the sshd process is terminated. trows error if it is not terminated.
# Local variables:
#  response_lines
# Globals:
#  None.
# Arguments:
#   The detected architecture of the device on which this code is running.
# Returns:
#  0 if funciton was evaluated succesfull.
#  7 if the sshd service is still running.
# Outputs:
#  None.
#######################################
assert_sshd_process_is_not_running_anymore() {
	local response_lines=$(sudo lsof -i -P -n | grep *:22)
	if [ "$response_lines" != "" ]; then
		echo "The sshd process should be killed but it is still running."
		exit 7
	fi
}