#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

# source src/import.sh

@test "Verify manual_assert_equal passes on equal input." {
	left="same"
	right="same"
	
	assert_equal "$left" "$right"
	
	
	run bash -c "source src/import.sh src/helper_asserts.sh && manual_assert_equal $left $right"
	assert_success
}

@test "Verify manual_assert_equal throws error on unequal input." {
	left="same"
	right="different"
	
	assert_not_equal "$left" "$right"
	
	
	run bash -c "source src/import.sh src/helper_asserts.sh && manual_assert_equal $left $right"
	assert_failure
	assert_output --partial "Error, same does not equal: different"
	
}

@test "Verify manual_assert_not_equal succeeds on unequal input." {
	left="same"
	right="different"
	
	assert_not_equal "$left" "$right"
	
	
	run bash -c "source src/import.sh src/helper_asserts.sh && manual_assert_not_equal $left $right"
	assert_success
}


@test "Verify manual_assert_not_equal throws error on equal input." {
	left="same"
	right="same"
	
	assert_equal "$left" "$right"
	
	
	run bash -c "source src/import.sh src/helper_asserts.sh && manual_assert_not_equal $left $right"
	assert_failure
	assert_output --partial "Error, same equals: same"
}




@test "Verify manual_assert_file_does_not_exists throws error on existing file." {
	local existing_filepath="src/hardcoded_variables.txt"
	
	run bash -c "source src/helper_asserts.sh && manual_assert_file_does_not_exists $existing_filepath"
	assert_failure
	assert_output "The file: $existing_filepath exists, even though it shouldn't."
}

@test "Verify manual_assert_file_does_not_exists succeeds on non-existing file." {
	local existing_filepath="src/some_non_existing_file.txt"
	
	run bash -c "source src/helper_asserts.sh && manual_assert_file_does_not_exists $existing_filepath"
	assert_success
}