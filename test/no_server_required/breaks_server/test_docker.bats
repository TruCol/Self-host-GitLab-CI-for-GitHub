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