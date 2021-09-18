#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'

source src/install_and_boot_gitlab_server.sh
source src/install_and_boot_gitlab_runner.sh
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
		# TODO: either run this and test the results 
		# OR create separate test files that each test a different cumulative step in the
		# GitLab Runner installation process (latter preferred)
		#install_and_run_gitlab_server
	fi
	
	# Uninstall GitLab runner
	# TODO: move uninstall_gitlab_runner to after test execution
	#uninstall_gitlab_runner
}


@test "Not different." {
	assert_equal "Same" "Same"
}

# WORKS
#@test "Verify that the GitLab server is running within 300." {
#	#source src/helper.sh && check_for_n_seconds_if_gitlab_server_is_running "300"
#	is_running=$(check_for_n_seconds_if_gitlab_server_is_running "300")
#	assert_equal "$is_running" "RUNNING"
#}

#@test "Verifying the downloading of the GitLab Runner installer package." {
#	architecture=$(get_architecture)
#	COMMAND_OUTPUT=$(get_runner_package "$architecture")
#	EXPECTED_OUTPUT=""
#	
#	assert_equal "$COMMAND_OUTPUT" "$EXPECTED_OUTPUT"
#}
# TODO: test if file is curled (exists)
# TODO: test if the file is made runnable
# TODO: test md5sum (is correct)


#TODO: test if the install_gitlab_runner() { returns error if an unsupported architecture is included.

	



#@test "Checking if GitLab Runner installation was succesfull." {
#	architecture=$(get_architecture)
#	COMMAND_OUTPUT=$(install_package "$architecture")
#	EXPECTED_OUTPUT=""
#	
#	# actual expected output
#	#filename=gitlab-runner_amd64.deb
#	#install=Selecting previously unselected package gitlab-runner.
#	#(Reading database ... 513537 files and directories currently installed.)
#	#Preparing to unpack gitlab-runner_amd64.deb ...
#	#Unpacking gitlab-runner (14.1.0) ...
#	#Setting up gitlab-runner (14.1.0) ...
#	#GitLab Runner: creating gitlab-runner...
#	#Home directory skeleton not used
#	#
#	#Check and remove all unused containers (both dangling and unreferenced) including volumes.
#	#------------------------------------------------------------------------------------------
#	#
#	#
#	#Total reclaimed space: 0B
#
#	
#	assert_equal "$COMMAND_OUTPUT" "$EXPECTED_OUTPUT"
#}
## TODO: inspect several lines of the installation are found.
## TODO: distinguish between output when the package is not, and is installed.
#
#
#@test "Check if GitLab Runner was succesfully registered with the GitLab server." {
#	actual_output=$(register_gitlab_runner)
#	EXPECTED_OUTPUT=""
#		
#	assert_equal "$actual_output" "$EXPECTED_OUTPUT"
#}
## TODO: determine how one can verify whether the GitLab Runner is indeed verified at the GitLab server.
#
#
#@test "Verify a sudo user account is created for the GitLab Runner CI." {
#	output=$(create_gitlab_ci_user)
#	EXPECTED_OUTPUT="EQUAL"
#		
#	assert_equal "$output" "$EXPECTED_OUTPUT"
#}
## TODO: First remove the user account that is used for this runner, then verify it is removed, then verify it is added
## TODO: determine how one can verify whether a sudo user account is created for the GitLab Runner CI

# TODO: Probably remove this test and make it consistent with the series of consecutive tests that test each method of the GitLab runner function separately.
#@test "Verify the GitLab Runner CI service is installed correctly." {
#	# First uninstall the service:
#	uninstall_output=$(sudo gitlab-runner uninstall)
#	
#	# Then run the installation command that is being tested
#	output=$(install_gitlab_runner_service)
#	EXPECTED_OUTPUT=""
#
#	assert_equal "$output" "$EXPECTED_OUTPUT"
#}
## TODO: determine how one can verify whether the GitLab Runner CI service is installed correctly.
#
#
#@test "Test if the GitLab Runner CI service is started correctly." {
#	output=$(start_gitlab_runner_service)
#	EXPECTED_OUTPUT=""
#		
#	assert_equal "$output" "$EXPECTED_OUTPUT"
#}
## TODO: determine how one can verify whether the GitLab Runner CI service is started correctly.


# WORKS, 
#+ TODO: create separate test for "register_gitlab_runner" command.
#+ TODO: Change the before all, to before each to make sure the test starts from the beginning for this test (otherwise, only one test can be used per run).
#@test "Test if the GitLab Runner CI runner is registered correctly." {
#	arch=$(get_architecture)
#	
#	# Run the GitLab runner service installer completely
#	if [ $(gitlab_runner_is_running $arch) == "NOTRUNNING" ]; then
#		get_runner_package $arch
#		install_package $arch
#		register_gitlab_runner
#	fi
#	
#	# Get GitLab Runner status:
#	status=$(sudo gitlab-runner status)
#	
#	
#	EXPECTED_OUTPUT="gitlab-runner: Service is running"
#		
#	assert_equal "$status" "$EXPECTED_OUTPUT"	
#}

# WORKS, 
#+ TODO: create separate test for "create_gitlab_ci_user" command.
#+ TODO: Change the before all, to before each to make sure the test starts from the beginning for this test (otherwise, only one test can be used per run).
#@test "Test if the GitLab Runner CI runner is registered and maintained in the runner overview, after gitlab user is created." {
#	arch=$(get_architecture)
#	
#	# Run the GitLab runner service installer completely
#	if [ $(gitlab_runner_is_running $arch) == "NOTRUNNING" ]; then
#		get_runner_package $arch
#		install_package $arch
#		register_gitlab_runner
#		create_gitlab_ci_user
#	fi
#	
#	# Get GitLab Runner status:
#	status=$(sudo gitlab-runner status)
#	
#	
#	EXPECTED_OUTPUT="gitlab-runner: Service is running"
#		
#	assert_equal "$status" "$EXPECTED_OUTPUT"	
#}

# Works
#+ TODO: create separate test for "install_gitlab_runner_service" command.
#+ TODO: Change the before all, to before each to make sure the test starts from the beginning for this test (otherwise, only one test can be used per run).
#@test "Test if the GitLab Runner CI runner is registered and maintained in the runner overview, after install_gitlab_runner_service." {
#	arch=$(get_architecture)
#	
#	# Run the GitLab runner service installer completely
#	if [ $(gitlab_runner_is_running $arch) == "NOTRUNNING" ]; then
#		get_runner_package $arch
#		install_package $arch
#		register_gitlab_runner
#		create_gitlab_ci_user
#		install_gitlab_runner_service
#	fi
#	
#	# Get GitLab Runner status:
#	status=$(sudo gitlab-runner status)
#	
#	
#	EXPECTED_OUTPUT="gitlab-runner: Service is running"
#		
#	assert_equal "$status" "$EXPECTED_OUTPUT"	
#}

# WORKS
#+ TODO: create separate test for "start_gitlab_runner_service" command.
#+ TODO: Change the before all, to before each to make sure the test starts from the beginning for this test (otherwise, only one test can be used per run).
@test "Test if the GitLab Runner CI runner is registered and maintained in the runner overview, after start_gitlab_runner_service." {
	arch=$(get_architecture)
	
	# Run the GitLab runner service installer completely
	if [ $(gitlab_runner_is_running $arch) == "NOTRUNNING" ]; then
		get_runner_package $arch
		install_package $arch
		register_gitlab_runner
		create_gitlab_ci_user
		install_gitlab_runner_service
		start_gitlab_runner_service
		run_gitlab_runner_service
	else
		# GitLab runner status is already: Running, just need to launch a runner
		# TODO: remove
		run_gitlab_runner_service
	fi
	
	# Get GitLab Runner status:
	status=$(sudo gitlab-runner status)
	
	
	EXPECTED_OUTPUT="gitlab-runner: Service is running"
		
	assert_equal "$status" "$EXPECTED_OUTPUT"	
}

@test "Test if the GitLab Runner CI automatically evaluates the example repository to a succesfull build." {
	
	# Push the example repository to the GitLab server and verifiy the runner evaluates the build to be succesfull.
	create_and_run_ci_job
	
	# Get GitLab Runner CI build status of test repository:
	successfull_build_status_is_found=$(get_build_status)
	
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$successfull_build_status_is_found" "$EXPECTED_OUTPUT"	
}

# WORKS!
#+ TODO: Change the before all, to before each to make sure the test starts from the beginning for this test (otherwise, only one test can be used per run).
#@test "Test if the GitLab Runner CI service is started correctly." {
#	arch=$(get_architecture)
#	
#	# Run the GitLab runner service installer completely
#	if [ $(gitlab_runner_is_running $arch) == "NOTRUNNING" ]; then
#		get_runner_package $arch
#		install_package $arch
#		register_gitlab_runner
#		create_gitlab_ci_user
#		install_gitlab_runner_service
#		start_gitlab_runner_service
#		#run_gitlab_runner_service
#	fi
#	
#	# Get GitLab Runner status:
#	status=$(sudo gitlab-runner status)
#	
#	EXPECTED_OUTPUT="gitlab-runner: Service is running"
#		
#	assert_equal "$status" "$EXPECTED_OUTPUT"
#}

# THE RUN COMMAND HANGS
# TODO: ensure the run command does not result in an infinite wait.
#@test "Test if the GitLab Runner CI service is running correctly." {
#	arch=$(get_architecture)
#	
#	# Run the GitLab runner service installer completely
#	if [ $(gitlab_runner_is_running $arch) == "NOTRUNNING" ]; then
#		get_runner_package $arch
#		install_package $arch
#		register_gitlab_runner
#		create_gitlab_ci_user
#		install_gitlab_runner_service
#		start_gitlab_runner_service
#		#run_gitlab_runner_service # TODO: prevent this function from stalling the tests untill enter is pressed!
#	fi
#	
#	# Get GitLab Runner status:
#	status=$(sudo gitlab-runner status)
#	read -p "status=$status"
#	
#	EXPECTED_OUTPUT="gitlab-runner: Service is running"
#		
#	assert_equal "$status" "$EXPECTED_OUTPUT"
#	assert_equal "one" "$status"
#}
### TODO: determine how one can verify whether the GitLab Runner CI service is running correctly.



#@test "Trivial test." {
#	assert_equal "True" "True"
#}
