#!/bin/bash

source src/helper.sh
source src/hardcoded_variables.txt
source src/creds.txt
source src/create_personal_access_token.sh

# Source: https://docs.gitlab.com/ee/administration/server_hooks.html#:~:text=executed%20as%20appropriate.-,Create%20a%20global%20server%20hook%20for%20all%20repositories,-To%20create%20a
# To create a Git hook that applies to all of the repositories in your instance, set a global server hook. The default global server hook directory is in the GitLab Shell directory. Any hook added there applies to all repositories.
# For an installation from source is usually /home/git/gitlab-shell/hooks. For this installer it is ASSUMED to be in:
# /home/name/gitlab/data/gitlab-shell/hooks
# However, that directory does not exist, and the /home/name/gitlab/data/gitlab-shell/ directory is owned by: 
#user #998
# According to: https://askubuntu.com/questions/651408/why-does-the-file-owner-appear-as-user-1004 ans by A.B. the user of this number can be found with:
# grep ':998' /etc/passwd
# Which returns:
# gitlab-runner:x:998:997:GitLab Runner:/home/gitlab-runner:/bin/bash
# Hence it is assumed the /home/name/gitlab/data/gitlab-shell/ directory is owned by user: gitlab-runner

# TODO Prepare: Write test that verifies the /home/name/gitlab/data/gitlab-shell directory exists
assert_gitlab_shell_dir_exists() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	echo "docker_container_id=$docker_container_id"
	path_to_gitlab_shell_dir="/opt/gitlab/embedded/service/gitlab-shell"
	
	# check if directory exists inside GitLab Docker
	#https://superuser.com/questions/98825/how-to-check-if-a-directory-exists-in-linux-command-line
	#sudo docker exec -i "1a8150b37039" bash -c "if test -d /opt/gitlab/embedded/service/gitlab-shell; then echo 'FOUND'; fi "
	dir_exists=$(sudo docker exec -i "$docker_container_id" bash -c "if test -d $path_to_gitlab_shell_dir; then echo 'FOUND'; fi ")
	
	assert_equal "$dir_exists" "FOUND"
}


# TODO 2.A: make hooks directory
# E.g. /home/name/gitlab/data/gitlab-shell/hooks
create_gitlab_hook_dir() {
	# Get Linux username
	linux_username=$(whoami)
	
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	path_to_gitlab_hook_dir="/opt/gitlab/embedded/service/gitlab-shell/hooks"
	docker_sudo_create_dir "$path_to_gitlab_hook_dir" "$docker_container_id"
	
	# TODO 2.B: write test that verifies the hooks directory is created
	dir_exists=$(sudo docker exec -i "$docker_container_id" bash -c "if test -d $path_to_gitlab_hook_dir; then echo 'FOUND'; fi ")
	
	assert_equal "$dir_exists" "FOUND"
}

# TODO 4.A: make the hooks directory owned by user: gitlab-runner
# Skippesd as this is done automatically if the dir is created inside the GitLab docker

# TODO 2.C: Create by user: gitlab-runner directory:
# E.g. /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d


#	assert_equal $(sudo_dir_exists "$path_to_gitlab_post_receive_dir") "FOUND"
#}

create_gitlab_post_receive_dir() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
		
	path_to_gitlab_post_receive_dir="/opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d"
	docker_sudo_create_dir "$path_to_gitlab_post_receive_dir" "$docker_container_id"
	
	# TODO 2.D: write test that verifies this directory is created
	dir_exists=$(sudo docker exec -i "$docker_container_id" bash -c "if test -d $path_to_gitlab_post_receive_dir; then echo 'FOUND'; fi ")
	
	assert_equal "$dir_exists" "FOUND"
}



# TODO 4.C: make the hooks directory owned by user: gitlab-runner
# Skipped as this is done automatically if the dir is created inside the GitLab docker

# TODO 2.E: Create file named post-receive in directory: 
# /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d
# Yielding e.g.:
# /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d/post-receive
create_gitlab_post_receive_script() {
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	linux_username=$(whoami)
	path_to_gitlab_post_receive_script="/opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d/post-receive"
	$(sudo docker exec -i "$docker_container_id" bash -c "touch "$path_to_gitlab_post_receive_script"")
	
	# TODO 2.F: write test that verifies this file is created
	file_exists=$(sudo docker exec -i "$docker_container_id" bash -c "if test -f $path_to_gitlab_post_receive_script; then echo 'FOUND'; fi ")
	assert_equal "$file_exists" "FOUND"
	
	#/opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d
	# TODO 2.G: Add content:
	$(sudo docker exec -i "$docker_container_id" bash -c 'echo \#!/bin/bash > '$path_to_gitlab_post_receive_script)
	#sudo docker exec -i 1a8150b37039 bash -c "echo \"#!/bin/bash\" | tee "/opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d/post-receive""
	
	# works
	#sudo docker exec -i 1a8150b37039 bash -c 'echo \#!/bin/bash >> /opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d/post-receive'
	#sudo docker exec -i 1a8150b37039 bash -c 'rm /opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d/post-receive'
	#sudo docker exec -i 1a8150b37039 bash -c 'echo "helloworld" >> /opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d/post-receive'
	
	#
	#sudo docker exec -i 1a8150b37039 bash -c "if test -f /opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d/post-receive; then echo 'FOUND'; fi "
	#sudo docker exec -i 1a8150b37039 bash -c "cat /opt/gitlab/embedded/service/gitlab-shell/hooks/post-receive.d/post-receive"
	first_line=$(sudo docker exec -i "$docker_container_id" bash -c "cat $path_to_gitlab_post_receive_script")
	assert_equal "$first_line" "#!/bin/bash"
	
	$(sudo docker exec -i "$docker_container_id" bash -c 'echo "touch general_server_output.txt" >> '$path_to_gitlab_post_receive_script)
	
	two_lines=$(sudo docker exec -i "$docker_container_id" bash -c "cat $path_to_gitlab_post_receive_script")

	# TODO 2.H: verify content is created (manually verified)
	assert_equal "$two_lines" '#!/bin/bash
touch general_server_output.txt'
	
	# Make script runnable
	two_lines=$(sudo docker exec -i "$docker_container_id" bash -c "chmod +x $path_to_gitlab_post_receive_script")
}


# TODO 4.E: make the post-receive file owned by user: gitlab-runner
# Skipped as this is done automatically if the dir is created inside the GitLab docker

get_hashed_repo_path() {
	sudo docker exec -t -i 1a8150b37039 /bin/bash
	gitlab-rails console
	sudo gitlab-rails runner Project.find_by_full_path('root/repo_to_test_runner').disk_path
	# returns hashed path
	# Does something
	##sudo docker exec -i 1a8150b37039 bash -c 'gitlab-rails console gitlab-rails runner "Project.find_by_full_path("root/repo_to_test_runner").disk_path"'
	#sudo docker exec -i 1a8150b37039 bash -c 'gitlab-rails console "Project.find_by_full_path("root/repo_to_test_runner").disk_path"'
	#sudo docker exec -i 1a8150b37039 bash -c 'gitlab-rails runner "Project.find_by_full_path("root/repo_to_test_runner").disk_path"'
	
	#docker exec -it myContainer bin/rails console
	#https://github.com/sameersbn/docker-gitlab/issues/1384
	
}

# Verify if the post-receive script creates an output file
check_if_post_script_is_ran_after_commit() {
	
	file_exists=$(sudo docker exec -i "$docker_container_id" bash -c "if test -f $path_to_gitlab_post_receive_script; then echo 'FOUND'; fi ")
	assert_equal "$file_exists" "FOUND"
}