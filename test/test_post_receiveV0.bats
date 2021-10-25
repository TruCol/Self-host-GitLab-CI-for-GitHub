#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'

source src/install_and_boot_gitlab_server.sh
source src/install_and_boot_gitlab_runner.sh
source src/create_post_receive.sh
source src/run_ci_job.sh
source src/uninstall_gitlab_runner.sh
source src/helper.sh
source src/hardcoded_variables.txt

# Method that executes all tested main code before running tests.
setup() {
	# print test filename to screen.
	if [ "${BATS_TEST_NUMBER}" = 1 ];then
		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
	fi
	
	if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
		true
	else
		#+ uninstall and re-installation by default
		# Uninstall GitLab Runner and GitLab Server
		run bash -c "./uninstall_gitlab.sh -h -r -y"
	
		# Install GitLab Server
		run bash -c "./install_gitlab.sh -s -r"
	fi
}

@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test if the GitLab Runner CI automatically evaluates the example repository to a succesfull build." {
	skip
	# Push the example repository to the GitLab server and verifiy the runner evaluates the build to be succesfull.
	create_and_run_ci_job
	
	# Get GitLab Runner CI build status of test repository:
	successfull_build_status_is_found=$(get_build_status)
	
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$successfull_build_status_is_found" "$EXPECTED_OUTPUT"	
}

@test "Test assert_gitlab_shell_dir_exists." {
	assert_gitlab_shell_dir_exists
}

@test "Test gitlab hook dir is created." {
	create_gitlab_hook_dir
}

@test "Test owner of hook dir." {
	make_hooks_directory_owned_by_gitlab_user
}


@test "Test gitlab post_receive dir is created." {
	create_gitlab_post_receive_dir
}

@test "Test owner of post-receive dir." {
	make_post_receive_directory_owned_by_gitlab_user
}

@test "Test gitlab post_receive script is created." {
	create_gitlab_post_receive_script
}


@test "Test gitlab post_receive script is owned by gitlab-runner." {
	make_hooks_post_script_owned_by_gitlab_user
}
