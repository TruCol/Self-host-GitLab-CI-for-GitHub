#!./test/libs/bats/bin/bats

load '../../libs/bats-support/load'
load '../../libs/bats-assert/load'

source src/import.sh
#source src/boot_tor.sh

example_lines=$(cat <<-END
First line
second line 
third line 
sometoken
END
)
# Requires working installation
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

# Requires working installation
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