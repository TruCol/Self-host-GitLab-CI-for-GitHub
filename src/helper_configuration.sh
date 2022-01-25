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
# error.
# Source: https://github.com/Simple-Setup/Self-host-GitLab-Server-and-Runner-CI/issues/13
# run with: source src/import.sh && remove_sshd
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
remove_sshd() {
	local response_lines=$(sudo lsof -i -P -n | grep *:22)
	
	# Assert the first 4 characters of the response are:sshd
	echo "${response_lines:0:4}"
	
	if [ "${response_lines:0:4}" == "sshd" ]; then
		IFS="$(sudo whoami)"
		set $response_lines
		left_of_root_user=$1
		echo "left_of_root_user=$left_of_root_user"
		if [ "${left_of_root_user:0:4}" == "sshd" ]; then
			local port_str=$(stringStripNCharsFromStart "$left_of_root_user" 4)
			echo "port_str=$port_str"
			local port_nr=$(echo "$prt_nr" | tr -dc '0-9')
			echo "port_nr=$port_nr"
			sudo kill "$port_nr"
		else
			echo "The response to the lsof command does not start with:sshd"
			#exit 7
		fi
	elif [ "$response_lines" == "" ]; then
			echo "sshd process already killed."	
	else
		echo "The response to the lsof command does not start with:sshd"
		#exit 7
	fi
	
	# Assert the process is not running anymore
	assert_sshd_process_is_not_running_anymore
}

assert_sshd_process_is_not_running_anymore() {
	local response_lines=$(sudo lsof -i -P -n | grep *:22)
	if [ "$response_lines" != "" ]; then
		echo "The sshd process should be killed but it is still running."
		#exit 7
	fi
}





