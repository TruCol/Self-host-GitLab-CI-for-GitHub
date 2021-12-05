#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

source src/mirror_github_to_gitlab.sh
source src/push_repo_to_gitlab.sh
source src/helper.sh
source src/hardcoded_variables.txt

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
	
	if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
		true
	else
		read -p "Now re-installing GitLab."
		#+ uninstall and re-installation by default
		# Uninstall GitLab Runner and GitLab Server
		run bash -c "./uninstall_gitlab.sh -h -r -y"
	
		# Install GitLab Server
		run bash -c "./install_gitlab.sh -s -r"
	fi
}

@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test that is skipped." {
	skip
	some_function
}

# 3.a Verify invalid repository is not cloned
@test "Verify an error is thrown, if non-existant repository cloning is attempted LATEST." {
	non_existant_repository="NON_EXISTANT_REPOSITORY"
	
	# Assert the GitHub username is correct
	assert_equal "$GITHUB_USERNAME" a-t-0
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME" "$GITHUB_STATUS_WEBSITE")"
	
	# Specify the variables as they are inside the function
	github_username="$GITHUB_USERNAME"
	github_repository="$non_existant_repository"
	target_directory="$MIRROR_LOCATION/GitHub/$non_existant_repository"
	
	export github_username  github_repository has_access target_directory
	run bash -c 'source src/push_repo_to_gitlab.sh &&  export github_username  github_repository && clone_github_repository'
	assert_failure
	assert_output "$expected_error_message"
}

# 3.b Verify not cloning a repo correctly is detected with an error.
@test "Test whether repository download verifcation function identifies it if no repository is cloned." {
	non_existant_repository="NON_EXISTANT_REPOSITORY"
	
	# Assert the GitHub username is correct
	assert_equal "$GITHUB_USERNAME" a-t-0
	
	# Remove repositories
	remove_mirror_directories
	
	github_repository="$non_existant_repository"
	target_directory="$MIRROR_LOCATION/GitHub/$non_existant_repository"
	
	export github_repository target_directory
	run bash -c 'source src/mirror_github_to_gitlab.sh &&  verify_github_repository_is_cloned'
	assert_failure
	assert_output "The following GitHub repository: $github_repository \n was not cloned correctly into the path:$MIRROR_LOCATION/GitHub/$github_repository"
}

# 3.c Clone repository and verify it is cloned
@test "Verify whether the repository is cloned, if it is cloned." {
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME" "$GITHUB_STATUS_WEBSITE")"
	
	clone_github_repository "$GITHUB_USERNAME" "$PUBLIC_GITHUB_TEST_REPO" "$has_access" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO"
	repo_was_cloned=$(verify_github_repository_is_cloned "$PUBLIC_GITHUB_TEST_REPO" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO")
	assert_equal "$repo_was_cloned" "FOUND"
}

# 4. Get the branches of the cloned repository.
@test "Test the branches of the example_repository are cloned correctly." {
	
	###################### Self contained test ###############
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME" "$GITHUB_STATUS_WEBSITE")"
	
	clone_github_repository "$GITHUB_USERNAME" "$PUBLIC_GITHUB_TEST_REPO" "$has_access" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO"
	###################### Self contained test ###############
	
	
	get_git_branches github_branches "GitHub" "$PUBLIC_GITHUB_TEST_REPO"      # call function to populate the array
	declare -p github_branches
	
	assert_equal ""${github_branches[0]}"" "attack_in_new_file"
	assert_equal ""${github_branches[1]}"" "attack_unit_test"
	assert_equal ""${github_branches[2]}"" "main"
	assert_equal ""${github_branches[3]}"" "no_attack_in_filecontent"
	assert_equal ""${github_branches[4]}"" "no_attack_in_new_file"
}

# 6.a Loop through the github branches
@test "Test the branches of the example_repository are looped through correctly." {
	
	###################### Self contained test ###############
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME" "$GITHUB_STATUS_WEBSITE")"
	
	clone_github_repository "$GITHUB_USERNAME" "$PUBLIC_GITHUB_TEST_REPO" "$has_access" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO"
	###################### Self contained test ###############
	
	initialise_github_branches_array "$PUBLIC_GITHUB_TEST_REPO"
	output=$(loop_through_github_branches)
	
	expected_output=$(cat <<-END
attack_in_new_file
attack_unit_test
main
no_attack_in_filecontent
no_attack_in_new_file
END
)
	
	assert_equal "$output" "$expected_output"
}