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

	gitlab_package=$(get_gitlab_package)
	# TODO: verify if architecture is supported, raise error if not
	# TODO: Mention that support for the architecture can be gained by
	# downloading the right GitLab Runner installation package and adding
	# its verified md5sum into hardcoded_variables.txt (possibly adding an if statement 
	# to get_architecture().)
	gitlab_server_is_running="$(gitlab_server_is_running "$gitlab_package")"
	echo "gitlab_server_is_running=$gitlab_server_is_running"
	if [ "$gitlab_server_is_running" == "NOTRUNNING" ]; then
		remove_sshd
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
		run_gitlab_docker "$gitlab_pwd"
		verify_gitlab_server_status "$SERVER_STARTUP_TIME_LIMIT"
		# Also create personal access token
		read -p "SETTING PERSONAL ACCESS TOKEN, check if it does not already exist."
		ensure_new_gitlab_personal_access_token_works
		read -p "Done setting PERSONAL ACCESS TOKEN."
		printf "\n\n\n Verifying the GitHub and GitLab personal access tokens are in the $PERSONAL_CREDENTIALS_PATH file."
		verify_personal_creds_txt_contain_pacs
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
run_gitlab_docker() {
	local gitlab_pwd="$1"
	gitlab_package=$(get_gitlab_package)
	#read -p "Create command." >&2
	# shellcheck disable=SC2154
	command="sudo docker run --detach --hostname $GITLAB_SERVER --publish $GITLAB_PORT_1 --publish $GITLAB_PORT_2 --publish $GITLAB_PORT_3 --name $GITLAB_NAME --restart always --volume $GITLAB_HOME/config:/etc/gitlab --volume $GITLAB_HOME/logs:/var/log/gitlab --volume $GITLAB_HOME/data:/var/opt/gitlab -e GITLAB_ROOT_EMAIL=$GITLAB_ROOT_EMAIL_GLOBAL -e GITLAB_ROOT_PASSWORD=$GITLAB_SERVER_PASSWORD_GLOBAL $gitlab_package"
	#read -p "Created command." >&2
	echo "command=$command" > "$LOG_LOCATION""run_gitlab.txt"
	#read -p "Exportedcommand." >&2
#	output=$(sudo docker run --detach \
#	  --hostname $GITLAB_SERVER \
#	  --publish $GITLAB_PORT_1 --publish $GITLAB_PORT_2 --publish $GITLAB_PORT_3 \
#	  --name $GITLAB_NAME \
#	  --restart always \
#	  --volume $GITLAB_HOME/config:/etc/gitlab \
#	  --volume $GITLAB_HOME/logs:/var/log/gitlab \
#	  --volume $GITLAB_HOME/data:/var/opt/gitlab \
#	  -e GITLAB_ROOT_EMAIL=$GITLAB_ROOT_EMAIL_GLOBAL -e GITLAB_ROOT_PASSWORD=$GITLAB_SERVER_PASSWORD_GLOBAL \
#	  $gitlab_package)
	  
	  # Works for both root and for some_email@protonmail.com
#	  output=$(sudo docker run --detach \
#	  --hostname $GITLAB_SERVER \
#	  --publish $GITLAB_PORT_1 --publish $GITLAB_PORT_2 --publish $GITLAB_PORT_3 \
#	  --name $GITLAB_NAME \
#	  --restart always \
#	  --volume $GITLAB_HOME/config:/etc/gitlab \
#	  --volume $GITLAB_HOME/logs:/var/log/gitlab \
#	  --volume $GITLAB_HOME/data:/var/opt/gitlab \
#	  -e GITLAB_ROOT_EMAIL="some_email@protonmail.com" -e GITLAB_ROOT_PASSWORD="gitlab_root_password" -e EXTERNAL_URL="http://127.0.0.1" \
#	  $gitlab_package)
	  
	  output=$(sudo docker run --detach \
	  --hostname "$GITLAB_SERVER" \
	  --publish "$GITLAB_PORT_1" --publish "$GITLAB_PORT_2" --publish "$GITLAB_PORT_3" \
	  --name "$GITLAB_NAME" \
	  --restart always \
	  --volume "$GITLAB_HOME"/config:/etc/gitlab \
	  --volume "$GITLAB_HOME"/logs:/var/log/gitlab \
	  --volume "$GITLAB_HOME"/data:/var/opt/gitlab \
	  -e GITLAB_ROOT_EMAIL="$GITLAB_ROOT_EMAIL_GLOBAL" -e GITLAB_ROOT_PASSWORD="$gitlab_pwd" -e EXTERNAL_URL="http://127.0.0.1" \
	  "$gitlab_package")
	  #read -p "Ran command." >&2
	  echo "$output"
	  #-e GITLAB_ROOT_EMAIL="some_email@protonmail.com" -e GITLAB_ROOT_PASSWORD="$GITLAB_SERVER_PASSWORD_GLOBAL" -e EXTERNAL_URL="http://127.0.0.1" \
	  #-e GITLAB_ROOT_EMAIL="some_email@protonmail.com" -e GITLAB_ROOT_PASSWORD=$GITLAB_SERVER_PASSWORD_GLOBAL -e EXTERNAL_URL="http://127.0.0.1" \
	  #-e GITLAB_ROOT_EMAIL=$GITLAB_ROOT_EMAIL_GLOBAL -e GITLAB_ROOT_PASSWORD=yoursecretpassword -e EXTERNAL_URL="http://127.0.0.1" \
	  #-e GITLAB_ROOT_EMAIL="$GITLAB_ROOT_EMAIL_GLOBAL" -e GITLAB_ROOT_PASSWORD="yoursecretpassword" -e EXTERNAL_URL="http://127.0.0.1" \ # Works
}

# TODO: 
# go to:
# localhost
# set password
# login with account name:
#root
# and the password you just set.
 
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
