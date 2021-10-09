#!/bin/bash

source src/helper.sh
source src/hardcoded_variables.txt
source src/creds.txt
source src/create_personal_access_token.sh

# Source: https://docs.gitlab.com/ee/administration/server_hooks.html
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
# TODO A: Write test that verifies the /home/name/gitlab/data/gitlab-shell directory exists
assert_gitlab_shell_dir_exists() {
	linux_username=$(whoami)
	path_to_gitlab_shell_dir="/home/""$linux_username""/gitlab/data/gitlab-shell"
	assert_equal $(dir_exists "$path_to_gitlab_shell_dir") "FOUND"
}


# TODO B: make directory 
# /home/name/gitlab/data/gitlab-shell/hooks
create_gitlab_hook_dir() {
	linux_username=$(whoami)
	path_to_gitlab_hook_dir="/home/""$linux_username""/gitlab/data/gitlab-shell/hooks"
	sudo_create_dir "$path_to_gitlab_hook_dir"
	
	# TODO C: write test that verifies this directory is created
	assert_equal $(sudo_dir_exists "$path_to_gitlab_hook_dir") "FOUND"
}

# TODO D: make the hooks directory owned by user: gitlab-runner
make_hooks_directory_owned_by_gitlab_user() {
	linux_username=$(whoami)
	path_to_gitlab_hook_dir="/home/""$linux_username""/gitlab/data/gitlab-shell/hooks"
	$(make_user_owner_of_dir "$RUNNER_USERNAME" "$path_to_gitlab_hook_dir")
	# TODO E: write test that verifies this directory is owned by user: gitlab-runner
	is_owner=$(is_owner_of_dir "$RUNNER_USERNAME" "$path_to_gitlab_hook_dir")
	assert_equal "$is_owner" "FOUND"
}

# TODO F: Create by user: gitlab-runner directory:
# /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d
# TODO G: write test that verifies this directory is created
create_gitlab_post_receive_dir() {
	linux_username=$(whoami)
	path_to_gitlab_post_receive_dir="/home/""$linux_username""/gitlab/data/gitlab-shell/hooks/post-receive.d"
	sudo_create_dir "$path_to_gitlab_post_receive_dir"
	
	# TODO C: write test that verifies this directory is created
	assert_equal $(sudo_dir_exists "$path_to_gitlab_post_receive_dir") "FOUND"
}
# TODO H: make the hooks directory owned by user: gitlab-runner

make_post_receive_directory_owned_by_gitlab_user() {
	linux_username=$(whoami)
	path_to_gitlab_post_receive_dir="/home/""$linux_username""/gitlab/data/gitlab-shell/hooks/post-receive.d"
	$(make_user_owner_of_dir "$RUNNER_USERNAME" "$path_to_gitlab_post_receive_dir")
	# TODO I: write test that verifies this directory is owned by user: gitlab-runner
	is_owner=$(is_owner_of_dir "$RUNNER_USERNAME" "$path_to_gitlab_post_receive_dir")
	assert_equal "$is_owner" "FOUND"
}


# TODO J: Create file named post-receive in directory: 
# /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d
# Yielding:
# /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d/post-receive
create_gitlab_post_receive_script() {
	linux_username=$(whoami)
	path_to_gitlab_post_receive_script="/home/""$linux_username""/gitlab/data/gitlab-shell/hooks/post-receive.d/post-receive"
	sudo touch "$path_to_gitlab_post_receive_script"
	
	# TODO K: write test that verifies this file is created
	assert_equal $(sudo_file_exists "$path_to_gitlab_post_receive_script") "FOUND"

	# TODO L: Add content:
	echo '#!/bin/bash' | sudo tee "$path_to_gitlab_post_receive_script"
	second_line='echo "helloworld" | sudo tee "/home/'"$linux_username"'/Desktop/helloworld.txt"'
	echo "$second_line" | sudo tee -a sudo tee "$path_to_gitlab_post_receive_script"
	sudo chmod +x "$path_to_gitlab_post_receive_script"

	# TODO M: verify content is created
	#assert_equal "$(file_contains_string "#!/bin/bash" "$path_to_gitlab_post_receive_script")" "FOUND"
	#assert_equal  "$(file_contains_string "$second_line" "$path_to_gitlab_post_receive_script")" "FOUND"
}


# TODO N: make the post-receive file owned by user: gitlab-runner

make_hooks_post_script_owned_by_gitlab_user() {
	linux_username=$(whoami)
	path_to_gitlab_post_receive_script="/home/""$linux_username""/gitlab/data/gitlab-shell/hooks/post-receive.d/post-receive"
	$(make_user_owner_of_dir "$RUNNER_USERNAME" "$path_to_gitlab_post_receive_script")
	
	# TODO I: write test that verifies this post-receive file is owned by user: gitlab-runner
	is_owner=$(is_owner_of_dir "$RUNNER_USERNAME" "$path_to_gitlab_post_receive_script")
	assert_equal "$is_owner" "FOUND"
}