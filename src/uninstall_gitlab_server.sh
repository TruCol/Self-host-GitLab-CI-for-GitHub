#!/bin/bash
# Get port to run on
# Check if GitLab server is already running on that port. # If yes:
	# Echo already running.
# If no:
	# Check if GitLab is already installed. # If yes:
		# Run command to host GitLab server
	# If no:
		# Install GitLab
		# Run command to host GitLab server

source src/helper.sh
source src/hardcoded_variables.txt

uninstall_gitlab_server() {
	is_hard_uninstall=$1
	is_docker_uninstall=$2
	
	# Get which GitLab package is used based on the machine architecture
	gitlab_package=$(get_gitlab_package)
	
	# Start stopping, removing and uninstalling GitLab server.
	stop_docker
	stop_gitlab_package_docker $gitlab_package
	remove_gitlab_package_docker $gitlab_package
	remove_gitlab_docker_containers
	
	# Uninstall docker if an explicit argument for uninstallation is passed. 
	if [ "$is_docker_uninstall" == true ]; then
		$(uninstall_docker)
		$(uninstall_docker_compose)
	fi
	stop_apache_service
	stop_nginx_service
	#stop_nginx
	if [ "$is_hard_uninstall" == true ]; then
		delete_gitlab_folder
	fi
}


# Install docker:
uninstall_docker() {
	output=$(yes | sudo apt remove docker)
	echo "$output"
}

uninstall_docker_compose() {
	output=$(yes | sudo apt remove docker-compose)
	echo "$output"
}


delete_gitlab_folder() {
	sudo rm -r $GITLAB_HOME
}
## Trouble shooting
# If it returns:
#Error response from daemon: driver failed programming external connectivity on endpoint gitlab (<somelongcode>): Error starting userland proxy: listen tcp4 0.0.0.0:22: bind: address already in use.
# run:
#sudo lsof -i -P -n | grep 22
# identify which process nrs are running on port 22, e.g.:
#sshd      1234     root    3u  IPv4  23423      0t0  TCP *:22 (LISTEN)
# then kill all those processes
#sudo kill 1234
# then run this script again.

# You can check how long it takes before the gitlab server is completed running with:
#sudo docker logs -f gitlab