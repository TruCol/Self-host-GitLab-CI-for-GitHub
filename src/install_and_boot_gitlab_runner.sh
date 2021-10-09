#!/bin/bash
# Source: https://www.youtube.com/watch?v=G8ZONHOTAQk 
# Source: https://docs.gitlab.com/runner/install/
# Source: https://docs.gitlab.com/runner/install/linux-manually.html

source src/helper.sh
source src/hardcoded_variables.txt
source src/get_gitlab_server_runner_token.sh

# TODO: change to install and boot
install_and_run_gitlab_runner() {
	arch=$(get_architecture)
	# TODO: verify if architecture is supported, raise error if not
	# TODO: Mention that support for the architecture can be gained by
	# downloading the right GitLab Runner installation package and adding
	# its verified md5sum into hardcoded_variables.txt (possibly adding an if statement 
	# to get_architecture().)
	
	# Install GitLab Runner regardless of whether the runner service is already running or not.
		get_runner_package $arch
		install_package $arch
		register_gitlab_runner
		create_gitlab_ci_user
		install_gitlab_runner_service
		start_gitlab_runner_service
		run_gitlab_runner_service
		
	if [ $(gitlab_runner_is_running $arch) == "NOTRUNNING" ]; then
		echo "The gitlab runner is not yet running"
	else
		echo "The gitlab runner is already running"
	fi
	echo "COMPLETED RUNNER INSTALLATION."
}


# Download the gitlab runner package
# Available architectures: https://gitlab-runner-downloads.s3.amazonaws.com/latest/index.html
get_runner_package() {
	arch=$1
	
	# Get the hardcoded/expected checksum and verify if the file already is downloaded.
	expected_checksum=$(get_expected_md5sum_of_gitlab_runner_installer_for_architecture $arch)
	
	# Download GitLab runner installer package if it is not yet found
	if [ $(check_md5_sum "$expected_checksum" "gitlab-runner_${arch}.deb") != "EQUAL" ]; then
		# install curl
		install_curl=$(yes | sudo apt install curl)
		
		left="https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_"
		right=".deb"
		url="$left$arch$right"
		
		curl_command=$(curl -LJO "$url")
		
		# Optional: if x86_64 curl from:
		#https://archlinux.org/packages/community/x86_64/gitlab-runner/download
	fi
	
	# Verify the downloaded package is retrieved
	if [ $(check_md5_sum "$expected_checksum" "gitlab-runner_${arch}.deb") != "EQUAL" ]; then
		echo "ERROR, the md5 checksum of the downloaded GitLab installer package does not match the expected md5 checksum, perhaps the download was interrupted."
		exit 1
	fi
	
	# make it executable
	$(sudo chmod +x "gitlab-runner_${arch}.deb")
}


# Install GitLab runner (=not install GitLab runner as a service)
install_package() {
	arch=$1
	filename="gitlab-runner_"$arch".deb"
	echo "filename=$filename"
	install=$(sudo dpkg -i "$filename")
	#install=$(dpkg -i "$filename")
	echo "install=$install"
}
#TODO: reverse installation


# source src/install_and_boot_gitlab_runner.sh && register_gitlab_runner
# Register GitLab Runner
register_gitlab_runner() {

	# TODO: (doubt) goto: http://127.0.0.1/admin/application_settings/ci_cd#js-ci-cd-settings
	# TODO: (doubt) disable "Enable shared runners for new projects"

	
	#url="http://localhost"
	gitlab_url="http://127.0.0.1"
	description=trucolrunner
	executor=shell
	dockerimage="ruby:2.6"
	
	# Get Gitlab Server runner registration token.
	output=$(get_gitlab_server_runner_tokenV1)
	
	# runner_token=$(get_last_line_of_set_of_lines "\${output}") # python code output is given after last echo in shell, so read it from file instead of from output
	runner_token=$(cat $RUNNER_REGISTRATION_TOKEN_FILEPATH)
	
	# TODO: delete plain text registration token after reading.
	echo "runner_token=$runner_token""nonewlines"
	# Command to run runner in Docker (won't access the machine localhost this way/doesn't work).
	#registration=$(sudo gitlab-runner register \
	#--non-interactive \
	#--url $url \
	#--description $description \
	#--registration-token $runner_token \
	#--executor docker \
	#--docker-image ruby:2.6)
	
	register=$(sudo gitlab-runner register \
	--non-interactive \
	--url "$gitlab_url" \
	--description $description \
	--registration-token "$runner_token" \
	--executor $executor)
}


#source src/install_and_boot_gitlab_runner.sh && create_gitlab_ci_user
# Create a GitLab CI user
create_gitlab_ci_user() {
	# TODO: write check to see if user is already existent. Only add if it is not.
	
	# get list of users
	user_list=$(awk -F: '{ print $1}' /etc/passwd)
	#read -p  "RUNNER_USERNAME=$RUNNER_USERNAME"
	#read -p  "user_list=$user_list"
	if [  "$(lines_contain_string "$RUNNER_USERNAME" "\${user_list}")" == "NOTFOUND" ]; then
		# To overcome:
		#+    FATAL: Failed to install gitlab-runner: Init already exists: /etc/systemd/system/gitlab-runner.service 
		#service_filepath="/etc/systemd/system/"$RUNNER_USERNAME".service"
		#if [ ! -f "$service_filepath" ] ; then
		if [  "$(gitlab_runner_service_is_installed)" == "NO" ]; then
			#read -p  "SERVICE IS NOT FOUND RUNNING"
			sudo useradd --comment 'GitLab Runner' --create-home "$RUNNER_USERNAME" --shell /bin/bash
		fi
	fi
}


# source src/install_and_boot_gitlab_runner.sh && install_gitlab_runner_service
# Install GitLab runner service
install_gitlab_runner_service() {
	
	# only install service if it is not found yet:
	user_list=$(awk -F: '{ print $1}' /etc/passwd)
	#read -p  "RUNNER_USERNAME=$RUNNER_USERNAME"
	#read -p  "user_list=$user_list"
	if [  "$(lines_contain_string "$RUNNER_USERNAME" "\${user_list}")" == "NOTFOUND" ]; then
		if [  "$(gitlab_runner_service_is_installed)" == "NO" ]; then
			#sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab_runner
			$(sudo gitlab-runner install --user=$RUNNER_USERNAME --working-directory=/home/$RUNNER_USERNAME)
		fi
	fi
	$(sudo usermod -a -G sudo $RUNNER_USERNAME)
	# TODO: determine why this folder should be removed after installing the service (instead of before).
	#$(sudo rm -r /home/$RUNNER_USERNAME/.*)
	
	visudo_line="$RUNNER_USERNAME ALL=(ALL) NOPASSWD: ALL"
	filepath="/etc/sudoers"
	added_runner_to_visudo=$(visudo_contains "$visudo_line" "$filepath")
	if [  "$added_runner_to_visudo" == "NOTFOUND" ]; then
		echo "$RUNNER_USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo
		added_runner_to_visudo=$(visudo_contains "$visudo_line" "$filepath")
		if [  "$added_runner_to_visudo" == "NOTFOUND" ]; then
			# TODO: raise exception
			echo "ERROR, did not find the visudo user thatwas added"
			#exit 1
		fi
	fi
}


# Start GitLab runner service
start_gitlab_runner_service() {
	sudo gitlab-runner start
}


# Run GitLab runner service
#source src/install_and_boot_gitlab_runner.sh && run_gitlab_runner_service
run_gitlab_runner_service() {
	#output=$(nohup sudo gitlab-runner run &>/dev/null &) # causes tests to hang.
	#run bash -c "src/./run_gitlab_runner.sh"
	#run bash -c "./src/run_gitlab_runner.sh"
	#"./src/run_gitlab_runner.sh"
	"./src/run_gitlab_runner.sh" & disown
}

#https://stackoverflow.com/questions/64257998/gitlab-ci-pipeline-fails-to-run
# TODO: automate:
#sudo visudo
#gitlab-runner ALL=(ALL) NOPASSWD: ALL
# TODO: share script that fixes it.
