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

@test "Check if the Docker image identifier is retrieved correctly from the full Docker image name." {
	skip
	get_docker_image_identifier
	gitlab_package="gitlab/gitlab-ce:latest"
	
	docker_image_identifier=$(get_docker_image_identifier "$gitlab_package")
	
	EXPECTED_OUTPUT="gitlab"
		
	assert_equal "$docker_image_identifier" "$EXPECTED_OUTPUT"
}



@test "Docker image name is recognised correctly." {
	# Get Docker image name
	docker_image_name=$(get_gitlab_package)
	
	# Check if Docker is installed. If it is, remove it.
	if [ "$(safely_check_if_program_is_installed docker)" == "FOUND" ]; then
		echo "HI"
	
		# Get Docker container id
		docker_container_id=$(get_docker_container_id_of_gitlab_server)
		#read -p "docker_container_id=$docker_container_id"
		
		# Remove container if it is running
		if [ -n "$docker_container_id" ]; then
			
			# Stop Gitlab Docker container
			stopped=$(sudo docker stop "$docker_container_id")
			
			#remove_gitlab_package_docker "$docker_container_id"
			removed=$(sudo docker rm $docker_container_id)
		fi
	
	fi
	
	# Verify that the Docker image does not exist. 
	actual_result=$(docker_image_exists "$docker_image_name")
	assert_equal "$actual_result" "NO"
	
	
	# TODO: why does this test expect docker service to start if docker is not installed?
	# Start Docker service
	output=$(sudo systemctl start docker)
	assert_equal "$output" "Something"
	
	# Start GitLab Docker container
	##TAKES LONG
	#run_gitlab_docker
	
	#### Get the docker image name
	###docker_image_name=$(get_gitlab_package)
	###
	###actual_result=$(docker_image_exists "$docker_image_name")
	###EXPECTED_OUTPUT="YES"
	###
	###assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}




#pass
@test "Docker container is reported as not running if it does not exist." {
	skip
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