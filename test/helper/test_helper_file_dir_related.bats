#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

# source src/import.sh

@test "Verify delete_file_if_it_exists works on existing file." {
	local existing_filepath="some_test_file.txt"
	touch "$existing_filepath"

	# If an exact error is expected you should not source src/import.sh because
	# that is verbose.
	run bash -c "source src/helper/verification/helper_asserts.sh && manual_assert_file_does_not_exists $existing_filepath"
	assert_failure
	assert_output "The file: $existing_filepath exists, even though it shouldn't."

	#run bash -c "source src/helper/helper_file_dir_related.sh src/helper/verification/helper_asserts.sh && delete_file_if_it_exists $existing_filepath"
	run bash -c "source src/import.sh && delete_file_if_it_exists $existing_filepath"
	assert_success

	run bash -c "source src/import.sh && manual_assert_file_does_not_exists $existing_filepath"
	assert_success
}

@test "Verify delete_file_if_it_exists works on non-existing file." {
	local non_existing_filepath="some_non_existing_test_file.txt"

	run bash -c "source src/import.sh && manual_assert_file_does_not_exists $existing_filepath"
	assert_success

	#run bash -c "source src/helper/helper_file_dir_related.sh src/helper/verification/helper_asserts.sh && delete_file_if_it_exists $existing_filepath"
	run bash -c "source src/import.sh && delete_file_if_it_exists $existing_filepath"
	assert_success

	run bash -c "source src/import.sh && manual_assert_file_does_not_exists $existing_filepath"
	assert_success
}