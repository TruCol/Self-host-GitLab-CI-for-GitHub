#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

# TODO: move to import
# TODO: before moving, verify the function names do not collide.
source test/helper/helper.sh
source test/hardcoded_testdata.txt

# Method that executes all tested main code before running tests.
setup() {
	# print test filename to screen.
	if [ "${BATS_TEST_NUMBER}" = 1 ];then
		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
	fi
	
	#ans=$(create_file_with_three_lines_with_spaces)
	#ans=$(create_file_with_three_lines_without_spaces)
}


#@test "Verify the GitLab storage folder is deleted correctly." {
#	output=$(create_gitlab_folder)
#	EXPECTED_OUTPUT="EQUAL"
#	username=$(whoami)
#
#	if [ -d "/home/$username/gitlab" ]; then
#		assert_equal "found_directory" "found_directory"
#	else
#		assert_equal "did_not_find_directory" "did_not_find_directory_after_the_directory_creation_function"
#	fi
#}
# TODO: test on dummy folder