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

@test "Check docker program is not recognised if it is not installed.." {
	safely_remove_docker
	local actual_result=$(safely_check_if_program_is_installed "docker")
	
	local expected_output="NOTFOUND"
		
	assert_equal "$actual_result" "$expected_output"
}

@test "Check docker program is recognised if it is installed." {
	
	install_docker
	
	local actual_result=$(safely_check_if_program_is_installed "docker")
	
	local expected_output="FOUND"
		
	assert_equal "$actual_result" "$expected_output"
}

@test "Checking Docker version response." {
	# First remove Docker: 
	# (succeeds even if docker already removed/not installed.)
	run bash -c "source src/import.sh && completely_remove_docker"
	
	# Install docker.
	run bash -c "source src/import.sh && install_docker"
	
	# Get version of installed Docker
	run bash -c "source src/import.sh && get_docker_version"
	assert_success
	
	# Verify a version of Docker is installed.
	assert_output --partial "Docker version 2"
}


@test "Checking Docker version response fails if docker is removed." {
	run bash -c "source src/import.sh && completely_remove_docker"
	
	# Get version of installed Docker
	run bash -c "docker --version"
	assert_failure
	
	# Verify a version of Docker is removed.
	assert_output --partial "bash: docker: command not found"
}