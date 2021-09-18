#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'

source src/helper.sh

@test "If error is thrown if the GitLab server is not running within 5 seconds after uninstallation." {
	# uninstall the GitLab server and runners.
	run bash -c "./uninstall_gitlab.sh -h -r -y"
	
	# Specify how long to test/wait on the GitLab server to get up and running
	duration=4
		
	# run the tested method
	run bash -c "source src/helper.sh && check_for_n_seconds_if_gitlab_server_is_running $duration"
	assert_failure 
	#check_for_n_seconds_if_gitlab_server_is_running
	assert_output --partial "ERROR, did not find the GitLab server running within $duration seconds!"
}


@test "Test if the function correctly identifies that the GitLab server is running within 300 seconds after installation." {
	# uninstall the GitLab server and runners.
	run bash -c "./uninstall_gitlab.sh -h -r -y"
	# install the gitlab runner
	run bash -c "./install_gitlab.sh -s"
	
	# Specify how long to test/wait on the GitLab server to get up and running
	duration=300
		
	# run the tested method
	run bash -c "source src/helper.sh && check_for_n_seconds_if_gitlab_server_is_running $duration"
	
	actual_output=$(gitlab_server_is_running | tail -1) 
	expected_output="RUNNING"
	assert_equal "$actual_output" "$expected_output"
}

#### additional tests

@test "Test download website source code." {
	# TODO: move to long test and ensure GitLab is installed and running before executing this test.
	source_filepath=$LOG_LOCATION$RUNNER_SOURCE_FILENAME
	output=$(downoad_website_source "$GITLAB_SERVER_HTTP_URL" "$source_filepath")
	
	# TODO: delete file if exists
	
	# TODO: change to: https://github.com/ztombol/bats-file
	if [ -f "$source_filepath" ]; then
		assert_equal "file exists"  "file exists"
	else
		assert_equal "The following file does not exist:" "$source_filepath"
	fi 
}


@test "Checking docker_container_id." {
	# TODO: move to long test and ensure GitLab is installed and running before executing this test.
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	EXPECTED_OUTPUT="d5e4001b4d8f"
	
	# TODO: replace hardcoded container id with a `sudo docker ps -a` command
	# that verifies the returned container_id is in the output of that command.
	# (for the given gitlab package/architecture).
		
	assert_equal "$docker_container_id" "$EXPECTED_OUTPUT"
}

@test "Test check if gitlab runner status is identified correctly." {
	# TODO: move to long test and ensure GitLab is installed and running before executing this test.
	actual_result=$(check_gitlab_runner_status)
	EXPECTED_OUTPUT="gitlab-runner: Service is running"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Test check if gitlab server status is identified correctly." {
	# TODO: move to long test and ensure GitLab is installed and running before executing this test.
	actual_result=$(check_gitlab_server_status)
	EXPECTED_OUTPUT="gitlab-runner: Service is running"
	assert_equal "$(lines_contain_string 'run: alertmanager: (pid ' "\${actual_result}")" "FOUND"
	assert_equal "$(lines_contain_string 'run: gitaly: (pid ' "\${actual_result}")" "FOUND"
	assert_equal "$(lines_contain_string 'run: gitlab-exporter: (pid ' "\${actual_result}")" "FOUND"
	assert_equal "$(lines_contain_string 'run: gitlab-workhorse: (pid ' "\${actual_result}")" "FOUND"
	assert_equal "$(lines_contain_string 'run: grafana: (pid ' "\${actual_result}")" "FOUND"
	assert_equal "$(lines_contain_string 'run: logrotate: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: nginx: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: postgres-exporter: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: postgresql: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: prometheus: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: puma: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: redis: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: redis-exporter: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: sidekiq: (pid ' "\${actual_result}")" "FOUND"
    assert_equal "$(lines_contain_string 'run: sshd: (pid ' "\${actual_result}")" "FOUND"
}


@test "Test check if gitlab runner is running function returns correct output for running runner." {
	# TODO: move to long test and ensure GitLab is installed and running before executing this test.
	# TODO: uninstall gitlab server
	# TODO: uninstall gitlab runner
	# TODO: install gitlab server
	# TODO: wait untill gitlab server is installed and running correctly/responsively
	# TODO: start gitlab runner
	
	# ATTENTION: This test only works if you (manually) started a gitlab runner)
	
	# Check if runner is running
	actual_result=$(check_gitlab_runner_status)
	EXPECTED_OUTPUT="gitlab-runner: Service is running"
	
	if [ "$actual_result" == "$EXPECTED_OUTPUT" ]; then
		actual_result=$(gitlab_runner_is_running | tail -1)
		EXPECTED_OUTPUT="RUNNING"
		assert_equal "$actual_result" "$EXPECTED_OUTPUT"
	else
		assert_equal "The gitlab runner is not running." "To use this test, you should ensure the runner is running."
	fi
}