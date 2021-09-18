#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'


source src/boot_tor.sh

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


@test "Verify the timestamp check reports well on timestamps with age 0 seconds when asked was it created less than 3 seconds ago?" {
	filepath=test/timestamp.txt
	
	# Delete the file if it exists
	if [ -f "$filepath" ]; then
		rm "$filepath"
	fi
	
	# create timestamp
	export_timestamp $filepath
	
	# call function that is being tested
	actual_result=$(started_less_than_n_seconds_ago $filepath 3)
	EXPECTED_OUTPUT="YES"

	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Verify the timestamp check reports well on timestamps with age 5 seconds when asked was it created less than 3 seconds ago?" {
	filepath=test/timestamp.txt
	
	# Delete the file if it exists
	if [ -f "$filepath" ]; then
		rm "$filepath"
	fi
	
	# create timestamp
	export_timestamp $filepath
	
	sleep 5
	
	# call function that is being tested
	actual_result=$(started_less_than_n_seconds_ago $filepath 3)
	EXPECTED_OUTPUT="NO"

	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}