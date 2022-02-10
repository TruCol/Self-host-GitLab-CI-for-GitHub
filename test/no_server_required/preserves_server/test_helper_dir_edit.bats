#!./test/libs/bats/bin/bats

load '../../libs/bats-support/load'
load '../../libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load '../../libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load '../../assert_utils'

source src/import.sh




@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test that is skipped." {
	skip
	some_function
}

### 1. Remove mirror directories
@test "Check if mirror directories are removed." {
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}

### 2. Create mirror directories
@test "Check if mirror directories are created." {
	create_mirror_directories
	# TODO: determine if one should change assert_file_exists
	# to assert_folder_exists.
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
}
