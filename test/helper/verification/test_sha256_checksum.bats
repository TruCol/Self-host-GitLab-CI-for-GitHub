#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

# source src/import.sh

# Method that executes all tested main code before running tests.
setup() {
	# print test filename to screen.
	if [ "${BATS_TEST_NUMBER}" = 1 ];then
		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
	fi
}

@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test that is skipped." {
	skip
	some_function
}

## Dir structure:
#same_creation_date
#same_creation_date/a.txt
#same_creation_date/b.txt
#same_creation_date/c
#same_creation_date/c/d.txt
#same_creation_date/e/f.txt
#same_creation_date/.g/h.txt

#different_creation_date
#different_creation_date/a.txt
#different_creation_date/b.txt
#different_creation_date/c
#different_creation_date/c/d.txt
#different_creation_date/e/f.txt
#different_creation_date/.g/h.txt

#different_file_content
#different_file_content/a.txt
#different_file_content/b.txt
#different_file_content/c
#different_file_content/c/d.txt
#different_file_content/e/f.txt
#different_file_content/.g/h.txt

#different_folder_content
#different_folder_content/a.txt
#different_folder_content/b.txt
#different_folder_content/c
#different_folder_content/c/d.txt
#different_folder_content/e/f.txt
#different_folder_content/.g/h.txt

@test "Test identical directories are identified as identical." {
	actual_result="$(two_folders_are_identical_excluding_subdir test/sha256_tests/original test/sha256_tests/different_creation_date)"
	assert_equal "IDENTICAL" "$actual_result"
}

@test "Test non-identical identical directories are identified as different." {
	actual_result="$(two_folders_are_identical_excluding_subdir test/sha256_tests/original test/sha256_tests/different_dot_dir_content)"
	assert_equal "DIFFERENT" "$actual_result"
}

@test "Test non-identical identical directories are identified as identical if the difference is excluded." {
	actual_result="$(two_folders_are_identical_excluding_subdir test/sha256_tests/original test/sha256_tests/different_dot_dir_content ".g")"
	assert_equal "IDENTICAL" "$actual_result"
}

@test "Get the checksum of file a.txt." {
	sha256=$(get_sha256_of_file test/sha256_tests/original/a.txt)
	assert_equal "64ec88ca00b268e5ba1a35678a1b5316d212f4f366b2477232534a8aeca37f3c" "$sha256"
}

@test "Get the checksum of folder c." {
	skip
	sha256=$(get_sha256_of_file test/sha256_tests/original/c)
	assert_equal "64ec88ca00b268e5ba1a35678a1b5316d212f4f366b2477232534a8aeca37f3c" "$sha256"
}

@test "Get the checksum of the entire same_creation_date directory." {
	skip
	get_sha256_of_folder 
}

@test "Get the checksum of the entire different_creation_date directory." {
	skip
}

@test "Test the checksum of same_creation_date equals different_creation_date when modified date is ignored directory ." {
	skip
}

@test "Test the checksum of same_creation_date equals different_creation_date when modified date is ignored directory ." {
	skip
}

