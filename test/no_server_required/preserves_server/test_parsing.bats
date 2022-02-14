#!./test/libs/bats/bin/bats

load '../../libs/bats-support/load'
load '../../libs/bats-assert/load'

source src/import.sh
#source src/boot_tor.sh

EXAMPLE_LINES=$(cat <<-END
First line
second line 
third line 
sometoken
END
)

EXAMPLE_LINES_ENDING_IN_FOUND=$(cat <<-END
First line
second line 
third line 
sometoken
FOUND
END
)

EXAMPLE_LINES_ENDING_IN_NOTFOUND=$(cat <<-END
First line
second line 
third line 
sometoken
NOTFOUND
END
)


@test "Last line is returned correctly." {
	# TODO: determine why this test does not work.
	#lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	#local actual_result=$(get_last_line_of_set_of_lines "${EXAMPLE_LINES}")
	local actual_result=$(get_last_line_of_set_of_lines $EXAMPLE_LINES)
	local expected_output="sometoken"
		
	assert_equal "$actual_result" "$expected_output"
}


@test "Test ends_in_found_or_notfound ending in FOUND." {
	local actual_result=$(ends_in_found_or_notfound $EXAMPLE_LINES_ENDING_IN_FOUND)
	local expected_output="TRUE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test ends_in_found_or_notfound ending in NOTFOUND." {
	local actual_result=$(ends_in_found_or_notfound $EXAMPLE_LINES_ENDING_IN_NOTFOUND)
	local expected_output="TRUE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test ends_in_found_or_notfound ending in neither FOUND nor NOTFOUND.." {
	local actual_result=$(ends_in_found_or_notfound $EXAMPLE_LINES)
	local expected_output="FALSE"
	assert_equal "$actual_result" "$expected_output"
}


@test "Test assert_ends_in_found_or_notfoundends_in_found_or_notfound ending in FOUND." {
	local actual_result=$(assert_ends_in_found_or_notfound $EXAMPLE_LINES_ENDING_IN_FOUND)
	local expected_output="TRUE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test assert_ends_in_found_or_notfoundends_in_found_or_notfound ending in NOTFOUND." {
	local actual_result=$(assert_ends_in_found_or_notfound $EXAMPLE_LINES_ENDING_IN_NOTFOUND)
	local expected_output="TRUE"
	assert_equal "$actual_result" "$expected_output"
}


@test "Test assert_ends_in_found_or_notfound ending in neither FOUND nor NOTFOUND." {
	# TODO: determine why the output message fails to match. (Only first line is displayed.)
	run bash -c "source src/helper_parsing.sh && assert_ends_in_found_or_notfound $EXAMPLE_LINES"
	assert_failure
	assert_output "ERROR, the end of $EXAMPLE_LINES does not end in FOUND, nor in NOTFOUND."
}


@test "Test ends_in_found_and_not_in_notfound ending in FOUND." {
	local actual_result=$(ends_in_found_and_not_in_notfound $EXAMPLE_LINES_ENDING_IN_FOUND)
	local expected_output="TRUE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test ends_in_found_and_not_in_notfound ending in NOTFOUND." {
	local actual_result=$(ends_in_found_and_not_in_notfound $EXAMPLE_LINES_ENDING_IN_NOTFOUND)
	local expected_output="FALSE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test ends_in_found_and_not_in_notfound ending in neither FOUND nor NOTFOUND.." {
	local actual_result=$(ends_in_found_and_not_in_notfound $EXAMPLE_LINES)
	local expected_output="FALSE"
	assert_equal "$actual_result" "$expected_output"
}


@test "Test assert_ends_in_found_and_not_in_notfound ending in FOUND." {
	local actual_result=$(assert_ends_in_found_and_not_in_notfound $EXAMPLE_LINES_ENDING_IN_FOUND)
	local expected_output="TRUE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test assert_ends_in_found_and_not_in_notfound ending in NOTFOUND." {
	# TODO: determine why the output message fails to match. (Only first line is displayed.)
	run bash -c "source src/helper_parsing.sh && assert_ends_in_found_and_not_in_notfound $EXAMPLE_LINES_ENDING_IN_NOTFOUND"
	assert_failure
	assert_output "ERROR, the end of $EXAMPLE_LINES does not end in FOUND, nor in NOTFOUND."
}

@test "Test assert_ends_in_found_and_not_in_notfound ending in neither FOUND nor NOTFOUND.." {
	# TODO: determine why the output message fails to match. (Only first line is displayed.)
	run bash -c "source src/helper_parsing.sh && assert_ends_in_found_and_not_in_notfound $EXAMPLE_LINES"
	assert_failure
	assert_output "ERROR, the end of $EXAMPLE_LINES does not end in FOUND, nor in NOTFOUND."
}


@test "Test ends_in_notfound_and_not_in_found ending in FOUND." {
	local actual_result=$(ends_in_notfound_and_not_in_found $EXAMPLE_LINES_ENDING_IN_FOUND)
	local expected_output="FALSE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test ends_in_notfound_and_not_in_found ending in NOTFOUND." {
	local actual_result=$(ends_in_notfound_and_not_in_found $EXAMPLE_LINES_ENDING_IN_NOTFOUND)
	local expected_output="TRUE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test ends_in_notfound_and_not_in_found ending in neither FOUND nor NOTFOUND.." {
	local actual_result=$(ends_in_notfound_and_not_in_found $EXAMPLE_LINES)
	local expected_output="FALSE"
	assert_equal "$actual_result" "$expected_output"
}


@test "Test assert_ends_in_notfound_and_not_in_found ending in FOUND." {
	run bash -c "source src/helper_parsing.sh && assert_ends_in_notfound_and_not_in_found $EXAMPLE_LINES_ENDING_IN_FOUND"
	assert_failure
	assert_output "ERROR, the end of $EXAMPLE_LINES does not end in FOUND, nor in NOTFOUND."
	
}

@test "Test assert_ends_in_notfound_and_not_in_found ending in NOTFOUND." {
	# TODO: determine why the output message fails to match. (Only first line is displayed.)
	local actual_result=$(assert_ends_in_notfound_and_not_in_found $EXAMPLE_LINES_ENDING_IN_NOTFOUND)
	local expected_output="TRUE"
	assert_equal "$actual_result" "$expected_output"
}

@test "Test assert_ends_in_notfound_and_not_in_found ending in neither FOUND nor NOTFOUND.." {
	# TODO: determine why the output message fails to match. (Only first line is displayed.)
	run bash -c "source src/helper_parsing.sh && assert_ends_in_notfound_and_not_in_found $EXAMPLE_LINES"
	assert_failure
	assert_output "ERROR, the end of $EXAMPLE_LINES does not end in FOUND, nor in NOTFOUND."
}



@test "Checking get line containing substring." {
	identification_str="second li"
	#line=$(get_first_line_containing_substring "test/static_file_with_spaces.txt" "$identification_str")
	line=$(get_first_line_containing_substring "test/static_file_with_spaces.txt" "\${identification_str}")
	EXPECTED_OUTPUT="second line"
		
	assert_equal "$line" "$EXPECTED_OUTPUT"
}


@test "Substring in first line is found in lines by lines_contain_string." {
	contained_substring="First line"

	#actual_result=$(lines_contain_string "$contained_substring" "${EXAMPLE_LINES}")
	#actual_result=$(lines_contain_string_with_space "$contained_substring" "${EXAMPLE_LINES}")
	actual_result=$(string_in_lines "$contained_substring" "${EXAMPLE_LINES}")
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Substring in second line is found in lines by lines_contain_string." {
	contained_substring="second"
	
	#actual_result=$(lines_contain_string "$contained_substring" "${EXAMPLE_LINES}")
	#actual_result=$(lines_contain_string_with_space "$contained_substring" "${EXAMPLE_LINES}")
	actual_result=$(string_in_lines "$contained_substring" "${EXAMPLE_LINES}")
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "lines_contain_string returns NOTFOUND on non-existing substring." {
	contained_substring="Non-existing-substring"
	
	#actual_result=$(lines_contain_string "$contained_substring" "${EXAMPLE_LINES}")
	#actual_result=$(lines_contain_string_with_space "$contained_substring" "${EXAMPLE_LINES}")
	actual_result=$(string_in_lines "$contained_substring" "${EXAMPLE_LINES}")
	EXPECTED_OUTPUT="NOTFOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Substring in last line is found in lines by lines_contain_string." {
	lines=$(printf 'First line\nsecond line \nthird line \n')
	
	contained_substring="third line "
	
	actual_result=$(lines_contain_string "$contained_substring" "${lines}")
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}



@test "Test get remainder of line starting from the semicolon character." {
	line="some long line: with some spaces in it"
	character=":"
	
	actual_result=$(get_rhs_of_line_till_character "$line" "$character")
	# TODO: make it work with space included.
	EXPECTED_OUTPUT=" with some spaces in it"
	#EXPECTED_OUTPUT="with some spaces in it"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Test get remainder of line starting from the space character." {
	line="somelongline:withsome spaces in it"
	character=" "
	
	actual_result=$(get_rhs_of_line_till_character "$line" "$character")
	EXPECTED_OUTPUT="spaces in it"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Test get substring of a line before the semicolon character." {
	line="some long line: with some spaces in it"
	character=":"
	
	actual_result=$(get_lhs_of_line_till_character "$line" "$character")
	EXPECTED_OUTPUT="some long line"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test get substring of a line before the spacebar character." {
	line="somelongline:withsome spaces in it"
	character=" "
	
	actual_result=$(get_lhs_of_line_till_character "$line" "$character")
	EXPECTED_OUTPUT="somelongline:withsome"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test file contains string." {
	line="first line"
	filepath="test/static_file_with_spaces.txt"
	actual_result=$(file_contains_string "$line" "$filepath")
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test file contains string with variable username." {
	line="first line"
	filepath="test/static_file_with_spaces.txt"
	actual_result=$(file_contains_string "$line" "$filepath")
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test file contains string with variable username that does not exist." {
	local username="an-unused-username"
	local line="$username	ALL=(ALL:ALL) ALL"
	local actual_result="$(visudo_contains $line)"
	local EXPECTED_OUTPUT="NOTFOUND"
	
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Line 1 is returned correctly." {
	local lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	local actual_result=$(get_line_by_nr_from_variable 1 "${lines}")
	EXPECTED_OUTPUT="First line"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Line 2 is returned correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_line_by_nr_from_variable 2 "${lines}")
	EXPECTED_OUTPUT="second line "
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Line 3 is returned correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_line_by_nr_from_variable 3 "${lines}")
	EXPECTED_OUTPUT="third line "
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Line 4 is returned correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_line_by_nr_from_variable 4 "${lines}")
	EXPECTED_OUTPUT="sometoken"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Line four is returned correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	line_nr="4"
	
	actual_result=$(get_line_by_nr_from_variable "$line_nr" "${lines}")
	EXPECTED_OUTPUT="sometoken"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}

@test "Number of lines is returned correctly." {
	lines=$(printf 'First line\nsecond line \nthird line \nsometoken')
	
	actual_result=$(get_nr_of_lines_in_var "${lines}")
	EXPECTED_OUTPUT="4"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}


@test "Test file contains string with variable username that does exist." {
	# TODO: Move this test to a function where the installation is completed.
	username="$GITLAB_SERVER_ACCOUNT_GLOBAL"
	line="$username	ALL=(ALL:ALL) ALL"
	actual_result=$(visudo_contains "$line" )
	EXPECTED_OUTPUT="FOUND"
		
	assert_equal "$actual_result" "$EXPECTED_OUTPUT"
}