#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

# source src/import.sh

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

# 6.e.0.helper1
@test "Test if GitHub branch exists." {
	github_repo_name="sponsor_example"
	github_branch_name="attack_in_new_file"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Checkout GitHub branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Check if branch is found in local GitHub repo.
	actual_result="$(github_branch_exists $github_repo_name $github_branch_name)"
	last_line=$(get_last_line_of_set_of_lines "\${actual_result}")
	assert_equal "$last_line" "FOUND"
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}

# 6.e.0.helper1
@test "Test if GitHub branch exists function fails if GitHub repo not found." {
	github_repo_name="non-existing-repository"
	github_branch_name="attack_in_new_file"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"

	# Check if branch is found in local GitHub repo.
	run bash -c "# source src/import.sh src/helper_github_modify.sh && github_branch_exists $github_repo_name $github_branch_name"
	assert_failure
	assert_output --partial "ERROR, the GitHub repository does not exist locally."
}

# 6.e.0.helper1
@test "Test if GitHub branch exists function returns NOTFOUND for non-existant branches." {
	github_repo_name="sponsor_example"
	github_branch_name="non-existing-branchname"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Check if branch is found in local GitHub repo.
	actual_result="$(github_branch_exists $github_repo_name $github_branch_name)"
	last_line=$(get_last_line_of_set_of_lines "\${actual_result}")
	assert_equal "$last_line" "NOTFOUND"
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}






# 6.f.0 Checkout that branch in the local GitHub mirror repository.
@test "Test if GitHub branch is checked out if it exists." {
	github_repo_name="sponsor_example"
	github_branch_name="attack_in_new_file"
	company="GitHub"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Check if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name $company)"
	assert_success
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}

# 6.f.0.helper1
@test "Test if GitHub branch checkout function fails if GitHub repo not found." {
	github_repo_name="non-existing-repository"
	github_branch_name="attack_in_new_file"
	company="GitHub"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
		
	# Check if branch is found in local GitHub repo.
	run bash -c "# source src/import.sh src/helper_gitlab_modify.sh src/import.sh && checkout_branch_in_github_repo $github_repo_name $github_branch_name $company"
	assert_failure
	assert_output --partial "ERROR, the GitHub repository does not exist locally."
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}

# 6.f.0.helper1
@test "Test if GitHub branch checkout function throws an error if the branch is not found." {
	github_repo_name="sponsor_example"
	github_branch_name="non-existing-branchname"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Check if branch is found in local GitHub repo.
	run bash -c "# source src/import.sh src/helper_gitlab_modify.sh && checkout_branch_in_github_repo $github_repo_name $github_branch_name $company"
	assert_failure
	assert_output --partial "ERROR, the GitHub branch does not exist locally."
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}


# 6.f.1 Test if the correct branch is gotten after a checkout.
@test "Test if GitHub branch is checked out correctly." {
	github_repo_name="sponsor_example"
	github_branch_name="attack_in_new_file"
	company="GitHub"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Checkout GitHub branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name $company)"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name $company)"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}


# 6.f.1 Test if the correct branch is gotten after a checkout.
@test "Test if another GitHub branch is checked out correctly." {
	github_repo_name="sponsor_example"
	github_branch_name="no_attack_in_filecontent"
	company="GitHub"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Checkout GitHub branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name $company)"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name $company)"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}

# 6.g.0 Test the function that checks whether the GitHub branch contains a GitLab yaml file.
@test "Test if the function verify_github_branch_contains_gitlab_yaml returns FOUND if the branch contains a GitLab yaml file." {
	github_repo_name="sponsor_example"
	#github_branch_name="no_attack_in_filecontent"
	github_branch_name="main"
	company="GitHub"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Checkout GitHub branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(verify_github_branch_contains_gitlab_yaml $github_repo_name $github_branch_name $company)"
	assert_equal "$actual_result" "FOUND"
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}

# 6.g.0 Test the function that checks whether the GitHub branch contains a GitLab yaml file.
@test "Test if the function verify_github_branch_contains_gitlab_yaml returns NOTFOUND if the branch contains a GitLab yaml file." {
	github_repo_name="sponsor_example"
	github_branch_name="no_attack_in_filecontent"
	company="GitHub"
	
	# Delete GitHub repo at start of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
	
	# Create mmirror directories
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
	
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo_name")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$github_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$github_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Checkout GitHub branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name $company)"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name $company)"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(verify_github_branch_contains_gitlab_yaml $github_repo_name $github_branch_name $company)"
	assert_equal "$actual_result" "NOTFOUND"
	
	# Delete GitHub repo at end of test.
	remove_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_not_exist "$MIRROR_LOCATION"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub"
	assert_file_not_exist "$MIRROR_LOCATION/GitLab"
}