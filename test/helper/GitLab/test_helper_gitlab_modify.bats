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


# 6.i
# TODO: fix error.
@test "Test whether the files are copied from GitHub branch to GitLab branch if there is a difference." {
	github_repo_name="sponsor_example"
	github_branch_name="main"
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="main"
	company="GitLab"
	
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
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$gitlab_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$gitlab_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$gitlab_repo_name" "$MIRROR_LOCATION/GitHub/$gitlab_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Checkout GitHub branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Create the empty GitLab repository (deletes any existing GitLab repos with same name).
	create_empty_repository_v0 "$gitlab_repo_name" "$gitlab_username"
	
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
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

# TODO verify consistent usage of gitlab_repo_name and PUBLIC_GITHUB_TEST_REPO_GLOBAL
@test "Test whether an empty repository is created, regardless of whether it already existed or not." {
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	# Create the empty GitLab repository.
	create_empty_repository_v0 "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" "$gitlab_username"
	
	# Verify the repository is created.
	gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$gitlab_repo_exists" "FOUND"
}

@test "Test whether an empty repository is created with create_empty_repository_v0, if it did not exist in advance." {
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	# Check if the GitLab repository exists.
	gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	
	# If the repository exists, delete it.
	if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
	
		# If it already exists, delete the repository
		delete_existing_repository "$gitlab_repo_name" "$gitlab_username"
		sleep 60
		
		# Verify the repository is deleted.
		if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
			# Throw an error if it is not deleted.
			echo "The GitLab repository was supposed to be deleted, yet it still exists."
			#exit 177
		fi
	fi
	
	# Create the empty GitLab repository.
	create_empty_repository_v0 "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" "$gitlab_username"
	
	# Verify the repository is created.
	gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$gitlab_repo_exists" "FOUND"
}

@test "Test whether an empty repository is created with create_gitlab_repository_if_not_exists, if it did not exist in advance." {
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	# Check if the GitLab repository exists.
	gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	
	# If the repository exists, delete it.
	if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
	
		# If it already exists, delete the repository
		delete_existing_repository "$gitlab_repo_name" "$gitlab_username"
		sleep 60
		
		# Verify the repository is deleted.
		if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
			# Throw an error if it is not deleted.
			echo "The GitLab repository was supposed to be deleted, yet it still exists."
			#exit 177
		fi
	fi
	
	# Create the empty GitLab repository.
	create_gitlab_repository_if_not_exists "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" "$gitlab_username"
	
	# Verify the repository is created.
	gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$gitlab_repo_exists" "FOUND"
}

# TODO: Write test that pushes a file to a repo, then runs:
#create_gitlab_repository_if_not_exists and verifies that afterwards
# the repository still contains the file (meaning no new empty repo is created).

@test "Test whether a repository is deleted if it exists." {
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	# Check if the GitLab repository exists.
	gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	
	# If the repository exists, delete it.
	if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
	
		# Create the empty GitLab repository.
		create_gitlab_repository_if_not_exists "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" "$gitlab_username"
	
		# Verify the repository is created.
		gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
		assert_equal "$gitlab_repo_exists" "FOUND"
	fi
	
	# If it already exists, delete the repository
	delete_gitlab_repository_if_it_exists "$gitlab_repo_name" "$gitlab_username"
	sleep 60
	
	# Verify the repository is deleted.
	gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$gitlab_repo_exists" "NOTFOUND"
}

@test "Test whether deleting a repository that does not exist does not yield an error with delete_gitlab_repository_if_it_exists." {
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	# Check if the GitLab repository exists.
	gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	
	# If the repository exists, delete it.
	if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
	
		# If it already exists, delete the repository
		delete_gitlab_repository_if_it_exists "$gitlab_repo_name" "$gitlab_username"
		sleep 60
		
		# Verify the repository is deleted.
		gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
		assert_equal "$gitlab_repo_exists" "NOTFOUND"
	fi
	
	# If it already exists, delete the repository
	delete_gitlab_repository_if_it_exists "$gitlab_repo_name" "$gitlab_username"
	sleep 60
	
	# Verify the repository is deleted.
	gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$gitlab_repo_exists" "NOTFOUND"
}

@test "Test whether deleting a repository that does not exist throws an error." {
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	# Check if the GitLab repository exists.
	gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	
	# If the repository exists, delete it.
	if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
	
		# If it already exists, delete the repository
		delete_gitlab_repository_if_it_exists "$gitlab_repo_name" "$gitlab_username"
		sleep 60
		
		# Verify the repository is deleted.
		gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
		assert_equal "$gitlab_repo_exists" "NOTFOUND"
	fi
	
	# If it already exists, delete the repository
	run bash -c "# source src/import.sh src/helper_gitlab_modify.sh && delete_existing_repository sponsor_example root"
	assert_failure
	assert_output --partial "ERROR, you tried to delete a GitLab repository that does not exist."
}

@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test that is skipped." {
	skip
	some_function
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
	
	# Get GitLab default username.
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	# Delete GitLab repo from server
	delete_gitlab_repository_if_it_exists "$gitlab_repo_name" "$gitlab_username"
	
	# Verify the repository is deleted.
	gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$gitlab_repo_exists" "NOTFOUND"
	
	
	# Create GitLab repo in server
	create_empty_repository_v0 "$gitlab_repo_name" "$gitlab_username"
	
	# Verify the repo is created.
	# TODO: fix error
	output_after_creation=$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")
	assert_equal "$output_after_creation" "FOUND"
	
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
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
	
	# Clone GitHub repo at start of test.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" "$has_access" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO_GLOBAL"
	repo_was_cloned=$(verify_github_repository_is_cloned "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" "$MIRROR_LOCATION/GitHub/$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# checkout GitHub branch
	# Checkout branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Create the empty GitLab repository (deletes any existing GitLab repos with same name).
	create_empty_repository_v0 "$gitlab_repo_name" "$gitlab_username"
	
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
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


# 6.k  Push the committed GitLab branch changes, with the sha from the GitHub branch as the commit message.
@test "Test whether the files are copied, committed and pushed correctly from GitHub branch to GitLab branch if there is a file-difference." {
	github_repo_name="sponsor_example"
	github_branch_name="main"
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="main"
	company="GitLab"
	
	# Get GitLab default username.
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	# Delete GitLab repo from server
	delete_gitlab_repository_if_it_exists "$gitlab_repo_name" "$gitlab_username"
	
	# Verify the repository is deleted.
	gitlab_repo_exists=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$gitlab_repo_exists" "NOTFOUND"
	
	# Create GitLab repo in server
	create_empty_repository_v0 "$gitlab_repo_name" "$gitlab_username"
	
	# Verify the repo is created.
	output_after_creation=$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")
	assert_equal "$output_after_creation" "FOUND"
	
	# Delete GitHub and GitLab repos at start of test.
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
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL")"
	
	# Clone GitHub repository.
	clone_github_repository "$GITHUB_USERNAME_GLOBAL" "$gitlab_repo_name" "$has_access" "$MIRROR_LOCATION/GitHub/$gitlab_repo_name"
	repo_was_cloned=$(verify_github_repository_is_cloned "$gitlab_repo_name" "$MIRROR_LOCATION/GitHub/$gitlab_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"
	
	# Checkout GitHub branch, if branch is found in local GitHub repo.
	actual_result="$(checkout_branch_in_github_repo $github_repo_name $github_branch_name "GitHub")"
	assert_success
	
	# Verify the get_current_github_branch function returns the correct branch.
	actual_result="$(get_current_github_branch $github_repo_name $github_branch_name "GitHub")"
	assert_equal "$actual_result" "$github_branch_name"
	
	# Create the empty GitLab repository (deletes any existing GitLab repos with same name).
	create_empty_repository_v0 "$gitlab_repo_name" "$gitlab_username"
	
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
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
	
	# Perform the Push function.
	push_changes_to_gitlab "$github_repo_name" "$github_branch_name" "$github_commit_sha" "$gitlab_repo_name" "$gitlab_branch_name"
}