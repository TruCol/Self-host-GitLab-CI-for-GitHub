#!./test/libs/bats/bin/bats

load '../../libs/bats-support/load'
load '../../libs/bats-assert/load'

source src/import.sh
#source src/Tor_support/boot_tor.sh

example_lines=$(cat <<-END
First line
second line 
third line 
sometoken
END
)
#@test "Checking get_checksum." {
#	md5sum=$(get_expected_md5sum_of_gitlab_runner_installer_for_architecture "amd64")
#	EXPECTED_OUTPUT="31f2cb520079da881c02ce479c562ae9"
#		
#	assert_equal "$md5sum" "$EXPECTED_OUTPUT"
#}




@test "Checking check_md5_sum." {
	actual_output=$(check_md5_sum "42dbacaf348d3e48e5cde4fe84ef48b3" "test/static_file_with_spaces.txt")
	md5sum=$(sudo md5sum "test/static_file_with_spaces.txt")
	md5sum_head=${md5sum:0:32}
	echo "md5sum_head=$md5sum_head"
	
	EXPECTED_OUTPUT="EQUAL"
		
	assert_equal "$actual_output" "$EXPECTED_OUTPUT"
}


