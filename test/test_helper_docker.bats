#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

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