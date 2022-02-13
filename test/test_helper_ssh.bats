#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

source src/import.sh

example_lines=$(cat <<-END
ssh-ed25519 longcode/longcode somename-somename-123
ssh-rsa longcode/longcode+longcode+longcode/longcode/longcode+longcode/longcode+longcode somename@somename-somename-123
ssh-ed25519 longcode somename@somename-somename-123
ssh-ed25519 longcode/longcode+longcode somename@somename.somename
END
)

# Specify expected error message:
expected_error_message=$(cat <<-END
Cloning into 'src/mirrors/GitHub/NON_EXISTANT_REPOSITORY'...
ERROR: Repository not found.
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
END
)
	

example_git_status_output=$(cat <<-END
On branch no_attack_in_filecontent

No commits yet

nothing to commit (create/copy files and use "git add" to track)
END
)

# Method that executes all tested main code before running tests.
setup() {
	# print test filename to screen.
	if [ "${BATS_TEST_NUMBER}" = 1 ];then
		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
	fi
	
	#if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
	#	true
	#else
	#	#+ uninstall and re-installation by default
	#	# Uninstall GitLab Runner and GitLab Server
	#	run bash -c "./uninstall_gitlab.sh -h -r -y"
	#
	#	# Install GitLab Server
	#	run bash -c "./install_gitlab.sh -s -r"
	#fi
}

@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test that is skipped." {
	skip
	some_function
}


@test "Check if ssh-key is created if it does not yet exist." {
	local email="example@example.com"
	local identifier="some_test_ssh_key_name"
	local public_key_filename="$identifier.pub"
	local private_key_filename="$identifier"

	output=$(generate_ssh_key_if_not_exists "$email" "$identifier")
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
}

@test "Check if ssh-key is created if only private_key_filename exists." {
	local email="example@example.com"
	local identifier="some_test_ssh_key_name"
	local public_key_filename="$identifier.pub"
	local private_key_filename="$identifier"

	# Ensure both keys are created.
	output=$(generate_ssh_key_if_not_exists "$email" "$identifier")
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"

	# Delete private key and assert it does not exist
	delete_file_if_it_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_does_not_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"

	# Run method to (re)create both keys, and assert they are created.
	output=$(generate_ssh_key_if_not_exists "$email" "$identifier")
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
}

@test "Check if ssh-key is created if only public_key_filename exists." {
	local email="example@example.com"
	local identifier="some_test_ssh_key_name"
	local public_key_filename="$identifier.pub"
	local private_key_filename="$identifier"

	# Ensure both keys are created.
	output=$(generate_ssh_key_if_not_exists "$email" "$identifier")
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"

	# Delete public key and assert it does not exist
	delete_file_if_it_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
	manual_assert_file_does_not_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"

	# Run method to (re)create both keys, and assert they are created.
	output=$(generate_ssh_key_if_not_exists "$email" "$identifier")
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
}

@test "Check if ssh-key still exists if both keys already exist." {
	local email="example@example.com"
	local identifier="some_test_ssh_key_name"
	local public_key_filename="$identifier.pub"
	local private_key_filename="$identifier"

	# Ensure both keys are created.
	output=$(generate_ssh_key_if_not_exists "$email" "$identifier")
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"

	# Run method to (re)create both keys, and assert they exist.
	output=$(generate_ssh_key_if_not_exists "$email" "$identifier")
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$public_key_filename"
	manual_assert_file_exists "$DEFAULT_SSH_LOCATION/$private_key_filename"
}


### Activate GitHub ssh account
@test "Check if ssh-key is added to ssh-agent after adding it to ssh-agent." {
	local email="example@example.com"
	local identifier="some_test_ssh_key_name"
	local public_key_filename="$identifier.pub"
	local private_key_filename="$identifier"
	
	# Run method to (re)create both keys, and assert they exist.
	output=$(generate_ssh_key_if_not_exists "$email" "$identifier")
	public_key_sha=$(get_public_key_sha_from_key_filename $identifier)

	activate_ssh_agent_and_add_ssh_key_to_ssh_agent "$identifier"
	
	# TODO: assert the ssh agent is running in this shell.

	# Assert the ssh-key is found in the ssh agent
	#check_if_public_key_sha_is_in_ssh_agent
	assert_equal "$(check_if_public_key_sha_is_in_ssh_agent $public_key_sha)" "FOUND"
}



@test "Check pull access to public repository." {
	skip
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME_GLOBAL" a-t-0
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
	assert_equal "$has_access" "HASACCESS"
}

@test "Check error is thrown when checking pull access to non-existant repository." {
	skip
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME_GLOBAL" a-t-0
	#has_access="$()"
	non_existant_repository="NON_EXISTANT_REPOSITORY"
	run bash -c "source src/import.sh src/mirror_github_to_gitlab.sh && check_ssh_access_to_repo $GITHUB_USERNAME_GLOBAL $non_existant_repository"
	assert_failure
	assert_output 'Your ssh-account:'$GITHUB_USERNAME_GLOBAL' does not have pull access to the repository:'$non_existant_repository
}


### SSH tests
@test 'Get last element of line, when it is delimted using the space character.' {
	skip
	local line_one="ssh-ed25519 longcode/longcode somename-somename-123"
	local line_two="ssh-rsa longcode/longcode+longcode+longcode/longcode/longcode+longcode/longcode+longcode somename@somename-somename-123"
	local line_three="ssh-ed25519 longcode somename@somename-somename-123"
	local line_four="ssh-ed25519 longcode/longcode+longcode somename@somename.somename"
	assert_equal "$(get_last_space_delimted_item_in_line "$line_one")" "somename-somename-123"
	assert_equal "$(get_last_space_delimted_item_in_line "$line_two")" "somename@somename-somename-123"
	assert_equal "$(get_last_space_delimted_item_in_line "$line_three")" "somename@somename-somename-123"
	assert_equal "$(get_last_space_delimted_item_in_line "$line_four")" "somename@somename.somename"
}

@test 'If ssh account is activated, FOUND is returned' {
	skip
	assert_equal "$(github_account_ssh_key_is_added_to_ssh_agent "somename@somename-somename-123" "\${example_lines}")" "FOUND"
}

@test 'If ssh account is not activated, NOTFOUND is returned' {
	skip
	assert_equal "$(github_account_ssh_key_is_added_to_ssh_agent "this_username_is_in_not_inthe_example" "\${example_lines}")" "NOTFOUND"
}

# Do not allow partial match but only allow complete match.
@test 'If ssh account is not activated, yet if it is a subset of an ssh account that IS activated, NOTFOUND is (still) returned' {
	skip
	assert_equal "$(github_account_ssh_key_is_added_to_ssh_agent "some" "\${example_lines}")" "NOTFOUND"
}





@test "Assert code execution is terminated if a required ssh-key is not activated." {
	skip
	non_existant_ssh_account="Some_random_non_existing_ssh_account_31415926531"
	
	run bash -c "source src/import.sh src/helper.sh && verify_ssh_key_is_added_to_ssh_agent $non_existant_ssh_account"
	assert_failure
	assert_output 'Please ensure the ssh-account '$non_existant_ssh_account' key is added to the ssh agent. You can do that with commands:'"\\n"' eval $(ssh-agent -s)'"\n"'ssh-add ~/.ssh/'$non_existant_ssh_account''"\n"' Please run this script again once you are done.'
	#assert_output "$feedback"
}

@test "Assert code execution is proceeded if the required ssh-key is activated." {
	skip
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME_GLOBAL" a-t-0
	
	existant_ssh_account="$GITHUB_USERNAME_GLOBAL"
	
	run bash -c "source src/import.sh src/helper.sh && verify_ssh_key_is_added_to_ssh_agent $existant_ssh_account"
	assert_success
}



##################################################################### ORDER##############################################


### 0. Test GitHub ssh-key is added to ssh-agent
@test "Check if ssh-account is activated." {
	skip
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME_GLOBAL" a-t-0
	
	ssh_output=$(ssh-add -L)
	
	
	# Get the email address tied to the ssh-account.
	ssh_email=$(get_ssh_email "$GITHUB_USERNAME_GLOBAL")
	echo "ssh_email=$ssh_email"
	echo "ssh_output=$ssh_output"
	
	# Check if the ssh key is added to ssh-agent by means of username.
	found_ssh_username="$(github_account_ssh_key_is_added_to_ssh_agent "$GITHUB_USERNAME_GLOBAL" "\${ssh_output}")"
	
	# Check if the ssh key is added to ssh-agent by means of email.
	found_ssh_email="$(github_account_ssh_key_is_added_to_ssh_agent "$ssh_email" "\${ssh_output}")"
	
	if [ "$found_ssh_username" == "FOUND" ]; then
		assert_equal  "$found_ssh_username" "FOUND"
	else
		assert_equal  "$found_ssh_email" "FOUND"
	fi
}