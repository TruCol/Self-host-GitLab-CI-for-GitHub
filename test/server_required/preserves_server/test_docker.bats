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


@test "Docker image name is recognised correctly." {
		
	# Get the docker image name
	docker_image_name=$(get_gitlab_package)
	
	actual_result=$(docker_image_exists "$docker_image_name")
	EXPECTED_OUTPUT="YES"
	
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}