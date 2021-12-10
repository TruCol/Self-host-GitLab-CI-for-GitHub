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

# 6.i
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# TODO: ensure assumption is replaced with actual call to function.
@test "Test whether the files are copied from GitHub branch to GitLab branch if there is a difference." {
	github_repo_name="sponsor_example"
	github_branch_name="main"
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="main"
	company="GitLab"
	
	# TODO: Delete GitHub repo at start of test.
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
	
	# TODO: Clone GitHub repo at start of test.
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME" "$GITHUB_STATUS_WEBSITE")"
	
	clone_github_repository "$GITHUB_USERNAME" "$PUBLIC_GITHUB_TEST_REPO" "$has_access" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO"
	repo_was_cloned=$(verify_github_repository_is_cloned "$PUBLIC_GITHUB_TEST_REPO" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# checkout GitHub branch
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Assumes the (sponsor_example) repository already exists inside the GitLab
	# server, which usually is not the case.
	# TODO: Check whether the repository exists in the GitLab server
	# TODO: If the repository does not exist in the GitLab server, upload it.
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$gitlab_server_account" "$gitlab_repo_name"
	
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name $company)"
	assert_success
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	actual_result="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	assert_equal "$actual_result" "$gitlab_branch_name"
	
	#
	result="$(copy_files_from_github_to_gitlab_branch $github_repo_name $github_branch_name $gitlab_repo_name $gitlab_branch_name)"
	last_line_result=$(get_last_line_of_set_of_lines "\${result}")
	assert_equal "$last_line_result" "IDENTICAL"
}


# 6.k Commit the GitLab branch changes, with the sha from the GitHub branch.
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# TODO: ensure assumption is replaced with actual call to function.
@test "Test whether the files are copied and committed correctly from GitHub branch to GitLab branch if there is a file-difference." {
	github_repo_name="sponsor_example"
	github_branch_name="main"
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="main"
	company="GitLab"
	
	# TODO: Delete GitHub repo at start of test.
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
	
	# TODO: Clone GitHub repo at start of test.
	# Verify ssh-access
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME" "$GITHUB_STATUS_WEBSITE")"
	
	clone_github_repository "$GITHUB_USERNAME" "$PUBLIC_GITHUB_TEST_REPO" "$has_access" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO"
	repo_was_cloned=$(verify_github_repository_is_cloned "$PUBLIC_GITHUB_TEST_REPO" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# checkout GitHub branch
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Assumes the (sponsor_example) repository already exists inside the GitLab
	# server, which usually is not the case.
	# TODO: Check whether the repository exists in the GitLab server
	# TODO: If the repository does not exist in the GitLab server, upload it.
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$gitlab_server_account" "$gitlab_repo_name"
	
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name $company)"
	assert_success
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	actual_result="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	assert_equal "$actual_result" "$gitlab_branch_name"
	
	# Ensure the files are copied
	result="$(copy_files_from_github_to_gitlab_branch $github_repo_name $github_branch_name $gitlab_repo_name $gitlab_branch_name)"
	last_line_result=$(get_last_line_of_set_of_lines "\${result}")
	assert_equal "$last_line_result" "IDENTICAL"
	
	# Get GitHub commit sha
	github_commit_sha="$(get_current_github_branch_commit $github_repo_name $github_branch_name "GitHub")"
	
	assert_not_equal "" "$github_commit_sha"
	
	# Perform the Git commit function.
	commit_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
}