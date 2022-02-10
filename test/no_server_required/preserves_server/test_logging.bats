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

# TODO: remove duplicate with: test_boot_tor.bats
@test "Verify the timestamp is created and contains the recent time." {
	filepath=test/timestamp.txt
	
	# Delete the file if it exists
	if [ -f "$filepath" ]; then
		rm "$filepath"
	fi
	
	# call function that is being tested
	export_timestamp $filepath
	
	# get results and specify expected result.
	actual_output=$(cat "$filepath")
	EXPECTED_OUTPUT=$[$(date +%s)]

	timestamp_age="$(echo $EXPECTED_OUTPUT $actual_output-p | dc)"
	
	# assert at most a delay of 5 seconds between file creation and file reading.
	[ "$timestamp_age" -lt 5 ]
}