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