#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'


source src/helper.sh
source src/install_and_boot_gitlab_server.sh
source test/helper.sh

source src/hardcoded_variables.txt
source test/hardcoded_testdata.txt

#@test "Checking get_checksum." {
#	md5sum=$(get_expected_md5sum_of_gitlab_runner_installer_for_architecture "amd64")
#	EXPECTED_OUTPUT="31f2cb520079da881c02ce479c562ae9"
#		
#	assert_equal "$md5sum" "$EXPECTED_OUTPUT"
#}

@test "Verify apache2 is not found." {

	actual_result=$(apache2_is_running)
	EXPECTED_OUTPUT="NOTFOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Checking check_md5_sum." {
	actual_output=$(check_md5_sum "42dbacaf348d3e48e5cde4fe84ef48b3" "test/static_file_with_spaces.txt")
	md5sum=$(sudo md5sum "test/static_file_with_spaces.txt")
	md5sum_head=${md5sum:0:32}
	echo "md5sum_head=$md5sum_head"
	
	EXPECTED_OUTPUT="EQUAL"
		
	assert_equal "$actual_output" "$EXPECTED_OUTPUT"
}


@test "Checking get line containing substring." {
	identification_str="second li"
	#line=$(get_first_line_containing_substring "test/static_file_with_spaces.txt" "$identification_str")
	line=$(get_first_line_containing_substring "test/static_file_with_spaces.txt" "\${identification_str}")
	EXPECTED_OUTPUT="second line"
		
	assert_equal "$line" "$EXPECTED_OUTPUT"
}


@test "Lines contain string." {
	lines=$(printf 'First line\nsecond line \nthird line \n')
	
	contained_substring="second"
	
	actual_result=$(lines_contain_string "$contained_substring" "\${lines}")
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test get remainder of line starting from the semicolon character." {
	line="some long line: with some spaces in it"
	character=":"
	
	actual_result=$(get_rhs_of_line_till_character "$line" "$character")
	# TODO: make it work with space included.
	#EXPECTED_OUTPUT=" with some spaces in it"
	EXPECTED_OUTPUT="with some spaces in it"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Test get remainder of line starting from the space character." {
	line="somelongline:withsome spaces in it"
	character=" "
	
	actual_result=$(get_rhs_of_line_till_character "$line" "$character")
	EXPECTED_OUTPUT="spaces in it"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Test get substring of a line before the semicolon character." {
	line="some long line: with some spaces in it"
	character=":"
	
	actual_result=$(get_lhs_of_line_till_character "$line" "$character")
	EXPECTED_OUTPUT="some long line"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test get substring of a line before the spacebar character." {
	line="somelongline:withsome spaces in it"
	character=" "
	
	actual_result=$(get_lhs_of_line_till_character "$line" "$character")
	EXPECTED_OUTPUT="somelongline:withsome"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test file contains string." {
	line="first line"
	filepath="test/static_file_with_spaces.txt"
	actual_result=$(file_contains_string "$line" "$filepath")
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test file contains string with variable username." {
	line="first line"
	filepath="test/static_file_with_spaces.txt"
	actual_result=$(file_contains_string "$line" "$filepath")
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test file contains string with variable username that does exist." {
	username=root
	line="$username	ALL=(ALL:ALL) ALL"
	actual_result=$(visudo_contains "$line" )
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Test file contains string with variable username that does not exist." {
	username=an-unused-username
	line="$username	ALL=(ALL:ALL) ALL"
	actual_result=$(visudo_contains "$line" )
	EXPECTED_OUTPUT="NOTFOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Line 1 is returrend correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_line_by_nr_from_variable 1 "\${lines}")
	EXPECTED_OUTPUT="First line"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Line 2 is returrend correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_line_by_nr_from_variable 2 "\${lines}")
	EXPECTED_OUTPUT="second line "
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Line 3 is returrend correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_line_by_nr_from_variable 3 "\${lines}")
	EXPECTED_OUTPUT="third line "
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Line 4 is returrend correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_line_by_nr_from_variable 4 "\${lines}")
	EXPECTED_OUTPUT="sometoken"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Line four is returrend correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	line_nr="4"
	
	actual_result=$(get_line_by_nr_from_variable "$line_nr" "\${lines}")
	EXPECTED_OUTPUT="sometoken"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Number of lines is returrend correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_nr_of_lines_in_var "\${lines}")
	EXPECTED_OUTPUT="4"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Last line is returrend correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_last_line_of_set_of_lines "\${lines}")
	EXPECTED_OUTPUT="sometoken"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Check if the Docker image identifier is retrieved correctly from the full Docker image name." {
	get_docker_image_identifier
	gitlab_package="gitlab/gitlab-ce:latest"
	
	docker_image_identifier=$(get_docker_image_identifier "$gitlab_package")
	
	EXPECTED_OUTPUT="gitlab"
		
	assert_equal "$docker_image_identifier" "$EXPECTED_OUTPUT"
}



@test "Docker image name is recognised correctly." {
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
		
		# Stop Gitlab Docker container
		stopped=$(sudo docker stop "$docker_container_id")
		
		#remove_gitlab_package_docker "$docker_container_id"
		removed=$(sudo docker rm $docker_container_id)
	fi
	
	# Verify that the Docker image does not exist. 
	actual_result=$(docker_image_exists "$docker_image_name")
	assert_equal "$actual_result" "NO"
	
	# Start Docker service
	output=$(sudo systemctl start docker)
	
	# Start GitLab Docker container
	run_gitlab_docker
	
	# Get the docker image name
	docker_image_name=$(get_gitlab_package)
	
	actual_result=$(docker_image_exists "$docker_image_name")
	EXPECTED_OUTPUT="YES"

	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Docker container is reported as running correctly." {
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
		
		# Stop Gitlab Docker container
		stopped=$(sudo docker stop "$docker_container_id")
		
		#remove_gitlab_package_docker "$docker_container_id"
		removed=$(sudo docker rm $docker_container_id)
	fi
	
	# Verify that the Docker image does not exist. 
	actual_result=$(docker_image_exists "$docker_image_name")
	assert_equal "$actual_result" "NO"
	
	# Start Docker service
	output=$(sudo systemctl start docker)
	
	# Start GitLab Docker container
	run_gitlab_docker
	
	# Get the docker image name
	docker_image_name=$(get_gitlab_package)
	
	actual_result=$(docker_image_exists "$docker_image_name")
	EXPECTED_OUTPUT="YES"

	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
	
	# Get the docker image status
	actual_result=$(container_is_running | tail -1)
	EXPECTED_OUTPUT="FOUND"
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

#pass
@test "Docker container is reported as not running if it does not exist." {
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
		
		# Stop Gitlab Docker container
		stopped=$(sudo docker stop "$docker_container_id")
		
		#remove_gitlab_package_docker "$docker_container_id"
		removed=$(sudo docker rm $docker_container_id)
	fi
	
	# Get the docker image status
	actual_result=$(container_is_running | tail -1)
	EXPECTED_OUTPUT="NOTFOUND"
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Docker container is reported as stopped correctly." {
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
		
		# Stop Gitlab Docker container
		stopped=$(sudo docker stop "$docker_container_id")
		
		#remove_gitlab_package_docker "$docker_container_id"
		removed=$(sudo docker rm $docker_container_id)
	fi
	
	# Verify that the Docker image does not exist. 
	actual_result=$(docker_image_exists "$docker_image_name")
	assert_equal "$actual_result" "NO"
	
	# Start Docker service
	output=$(sudo systemctl start docker)
	
	# Start GitLab Docker container
	run_gitlab_docker
	
	# Get the docker image name
	docker_image_name=$(get_gitlab_package)
	
	actual_result=$(docker_image_exists "$docker_image_name")
	EXPECTED_OUTPUT="YES"

	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
	
	# Get the new container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Stop Gitlab Docker container
	stopped=$(sudo docker stop "$docker_container_id")
	
	# Get the docker image status
	actual_result=$(container_is_running | tail -1)
	EXPECTED_OUTPUT="NOTFOUND"
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}



@test "Docker container is stopped correctly." {
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# Get Docker container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Remove container if it is running
	if [ -n "$docker_container_id" ]; then
		
		# Stop Gitlab Docker container
		stopped=$(sudo docker stop "$docker_container_id")
		
		#remove_gitlab_package_docker "$docker_container_id"
		removed=$(sudo docker rm $docker_container_id)
	fi
	
	# Verify that the Docker image does not exist. 
	actual_result=$(docker_image_exists "$docker_image_name")
	assert_equal "$actual_result" "NO"
	
	# Start Docker service
	output=$(sudo systemctl start docker)
	
	# Start GitLab Docker container
	run_gitlab_docker
	
	# Get the docker image name
	docker_image_name=$(get_gitlab_package)
	
	actual_result=$(docker_image_exists "$docker_image_name")
	EXPECTED_OUTPUT="YES"

	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
	
	# Get the new container id
	docker_container_id=$(get_docker_container_id_of_gitlab_server)
	
	# Get the docker image status and assert it is running before it is stopped
	actual_result=$(container_is_running | tail -1)
	EXPECTED_OUTPUT="FOUND"
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
	
	# Stop Gitlab Docker container
	stop_gitlab_package_docker
	
	# Get the docker image status
	actual_result=$(container_is_running | tail -1)
	EXPECTED_OUTPUT="NOTFOUND"
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

