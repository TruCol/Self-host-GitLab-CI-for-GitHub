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
install_and_run_gitlab_server() {
	local gitlab_pwd="$1"

	# Get the name of the GitLab release depending on the architecture of this
	# device.
	gitlab_package=$(get_gitlab_package)
	
	# Check if the GitLab server is already running.
	gitlab_server_is_running="$(gitlab_server_is_running "$gitlab_package")"
	#read -p "gitlab_server_is_running=$gitlab_server_is_running"
	
	if [ "$gitlab_server_is_running" == "NOTRUNNING" ]; then

		# This ensures the docker containers are not running on the used gitlab ports.
		remove_port_processes
		
		# Ensures docker is installed
		install_docker
		echo "install_docker"
		create_log_folder
		echo "create_log_folder"
		create_gitlab_folder
		echo "create_gitlab_folder"
		install_docker
		echo "install_docker"
		install_docker_compose
		echo "install_docker_compose"
		stop_docker
		echo "stop_docker"
		start_docker
		echo "start_docker"
		list_all_docker_containers
		echo "list_all_docker_containers"
		stop_gitlab_package_docker "$gitlab_package"
		echo "stop_gitlab_package_docker"
		remove_gitlab_package_docker "$gitlab_package"
		echo "remove_gitlab_package_docker"
		remove_gitlab_docker_containers
		echo "remove_gitlab_docker_containers"
		stop_apache_service
		echo "stop_apache_service"
		stop_nginx_service
		echo "stop_nginx_service"
		#stop_nginx
		run_gitlab_server_in_docker_container "$gitlab_pwd"
		echo "run_gitlab_server_in_docker_container"
		verify_gitlab_server_status "$SERVER_STARTUP_TIME_LIMIT"
		echo "Done: verify_gitlab_server_status"
		# Also create personal access token
		echo "SETTING PERSONAL ACCESS TOKEN, check if it does not already exist."
		ensure_new_gitlab_personal_access_token_works
		echo "Done setting PERSONAL ACCESS TOKEN."
		printf "\n Verifying the GitHub and GitLab personal access tokens are in the $PERSONAL_CREDENTIALS_PATH file."
		verify_gitlab_pac_exists_in_persional_creds_txt
	elif [ "$gitlab_server_is_running" == "RUNNING" ]; then
		echo "The GitLab server is already running."
	else
		echo "An error occured, the GitLab server status was neither RUNNING, nor NOTRUNNING."
		exit 123
	fi
}

# Runs for $duration [seconds] and checks whether the GitLab server status is: RUNNING.
# Throws an error and terminates the code if the GitLab server status is not found to be
# running within $duration [seconds]
#TODO remove this duplicate, use helper check_for_n_seconds_if_gitlab_server_is_running
verify_gitlab_server_status() {
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
		exit 1
	fi
}

create_log_folder() {
	mkdir -p "$LOG_LOCATION"
}

create_gitlab_folder() {
	mkdir -p "$GITLAB_HOME"
}


# Run docker installation command of gitlab
run_gitlab_server_in_docker_container() {
	local gitlab_pwd="$1"
	
	gitlab_package=$(get_gitlab_package)
	
	local output
	output=$(sudo docker run --detach \
	  --hostname "$GITLAB_SERVER" \
	  --publish "$GITLAB_PORT_1" \
	  --publish "$GITLAB_PORT_2" \
	  --publish "$GITLAB_PORT_3" \
	  --publish "$GITLAB_PORT_4" \
	  --name "$GITLAB_NAME" \
	  --restart always \
	  --volume "$GITLAB_HOME"/config:/etc/gitlab \
	  --volume "$GITLAB_HOME"/logs:/var/log/gitlab \
	  --volume "$GITLAB_HOME"/data:/var/opt/gitlab \
	  -e GITLAB_ROOT_EMAIL="$GITLAB_ROOT_EMAIL_GLOBAL" \
	  -e GITLAB_ROOT_PASSWORD="$gitlab_pwd" \
	  -e EXTERNAL_URL="\"$HTTPS_EXTERNAL_URL\"" \
	  "$gitlab_package")
	echo "$output"
}

# You can check how long it takes before the gitlab server is completed running with:
#sudo docker logs -f gitlab
