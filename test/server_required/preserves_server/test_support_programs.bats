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



# Requires working installation
@test "Verify apache2 is not found." {

	actual_result=$(apache2_is_running)
	EXPECTED_OUTPUT="NOTFOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}