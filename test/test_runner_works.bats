#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'

source src/install_and_boot_gitlab_server.sh
source src/install_and_boot_gitlab_runner.sh
source src/uninstall_gitlab_runner.sh
source src/helper.sh
source src/run_ci_job.sh
source src/hardcoded_variables.txt

# Method that executes all tested main code before running tests.
setup() {
	# print test filename to screen.
	if [ "${BATS_TEST_NUMBER}" = 1 ];then
		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
	fi

	# Check if the server is already running, if yes, prevent re-installation.
	#+ TODO: turn into argument for quick testing, but do the complete 
	
	if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
		true
	else
		#+ uninstall and re-installation by default
		# Uninstall GitLab Runner and GitLab Server
		run bash -c "./uninstall_gitlab.sh -h -r -y"
	
		# Install GitLab Server
		install_and_run_gitlab_server
	
		# Verify GitLab server is running
	
		# Install GitLab runner
		#install_and_run_gitlab_server
	fi
	
	# Uninstall GitLab runner
	uninstall_gitlab_runner
}


# Installs runner (and verifies it is running) before the bounty 
#+ TODO:  (Probably), make sure the GitLab runner is running as well.
@test "Test if the GitLab Runner CI runner is registered and maintained in the runner overview, after start_gitlab_runner_service." {
	arch=$(get_architecture)
	#skip
	
	# Run the GitLab runner service installer completely
	if [ $(gitlab_runner_is_running $arch) == "NOTRUNNING" ]; then
		get_runner_package $arch
		install_package $arch
		register_gitlab_runner
		create_gitlab_ci_user
		install_gitlab_runner_service
		start_gitlab_runner_service
	fi
	
	# Get GitLab Runner status:
	status=$(sudo gitlab-runner status)
	
	
	EXPECTED_OUTPUT="gitlab-runner: Service is running"
		
	assert_equal "$status" "$EXPECTED_OUTPUT"	
}

# Write test that verifies deleting the test-repository target folder.
@test "Verify the target repository that is used to run a CI job is deleted at the start." {

	output=$(delete_target_folder)
	
	# check if folder does not exist
	if [ -d "../$SOURCE_FOLDERNAME" ] ; then
		assert_equal  "The folder is NOT deleted." "The folder should be deleted."
	else
		assert_equal  "The folder is deleted." "The folder is deleted."
	fi
}

# Write test that verifies exporting the test-repository to a separate external folder.
@test "Verify the target repository is exported to a separate external folder." {

	output=$(export_repo)
	
	# check if folder does not exist
	if [ -d "../$SOURCE_FOLDERNAME" ] ; then
		assert_equal  "The folder is created." "The folder is created."
	else
		assert_equal  "The folder is NOT created." "The folder should be created."
	fi
}

# Write test that verifies removing test repository at GitLab account.
# Write test that verifies passing ssh credentials to root user.
# Write test that verifies adding the repository to the GitLab account.
