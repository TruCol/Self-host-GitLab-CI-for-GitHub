#!/bin/bash
# Source: https://www.youtube.com/watch?v=G8ZONHOTAQk 
# Source: https://docs.gitlab.com/runner/install/
# Source: https://docs.gitlab.com/runner/install/linux-manually.html

source src/helper.sh
source src/install_and_boot_gitlab_runner.sh

uninstall_gitlab_runner() {
	arch=$(get_architecture)
	# TODO: verify if architecture is supported, raise error if not
	# TODO: Mention that support for the architecture can be gained by
	# downloading the right GitLab Runner installation package and adding
	# its verified md5sum into hardcoded.txt (possibly adding an if statement 
	# to get_architecture().)
	
	#get_runner_package $arch
	uninstall_package $arch
	deregister_gitlab_runner
	remove_gitlab_ci_user
	uninstall_gitlab_runner_service
	stop_gitlab_runner_service
	remove_gitlab_runner_services
}


# Install GitLab runner (=not install GitLab runner as a service)
# TODO: uninstall package
# TODO: determine why the list of runners is not cleared/removed after uninstalling.
uninstall_package() {
	arch=$1
	#filename="gitlab-runner_"$arch".deb"
	filename="gitlab-runner_"$arch
	echo "filename=$filename"
	#install=$(sudo dpkg -i "$filename")
	install=$(sudo dpkg -P "$filename")
	echo "install=$install"
}



# Register GitLab Runner
deregister_gitlab_runner() {
	
	url="http://localhost"
	description=trucolrunner
	executor=shell
	dockerimage="ruby:2.6"
	
	register=$(sudo gitlab-runner unregister --all-runners)
}

# Create a GitLab CI user
# TODO: specify which user
remove_gitlab_ci_user() {
	
	# get list of users
	user_list=$(awk -F: '{ print $1}' /etc/passwd)
	if [  "$(lines_contain_string "$RUNNER_USERNAME" "\${user_list}")" == "FOUND" ]; then
		output=$(sudo userdel -r -f "$RUNNER_USERNAME")
	fi
}


# Install GitLab runner service
# TODO: specify which service
uninstall_gitlab_runner_service() {
	if [  "$(gitlab_runner_service_is_installed)" == "YES" ]; then
		sudo gitlab-runner uninstall
	fi
}


# Start GitLab runner service
# TODO: specify which service
stop_gitlab_runner_service() {
	if [  "$(gitlab_runner_is_running)" == "RUNNING" ]; then
		sudo gitlab-runner stop
	fi
}


# Run GitLab runner service
# TODO: determine why there is no equivalent of stopping running the runner.
remove_gitlab_runner_services() {
	#run_command=$(sudo gitlab-runner run &)
	run_command=$(sudo gitlab-runner verify --delete)
	#run_command=$(nohup sudo gitlab-runner run > gitlab_runner_run.out &)
	#run_command=$(nohup sudo gitlab-runner run --user=gitlab-runner &)
	echo "$run_command"
}

# Troubleshooting: when runners are not removed:
# Source: https://stackoverflow.com/questions/66616014/how-do-i-delete-unregister-a-gitlab-runner
# Source: https://gitlab.com/gitlab-org/gitlab-foss/-/issues/19828#note_54956232
