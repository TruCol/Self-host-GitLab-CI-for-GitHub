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

# 5. Verify gitlab repo is created.
@test "Test if GitLab repository is created." {
	
	# Get GitLab default username.
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"

	create_empty_gitlab_repository_v0 "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" "$gitlab_username"
	
	# Verify the repo is created.
	output_after_creation=$(gitlab_mirror_repo_exists_in_gitlab "$PUBLIC_GITHUB_TEST_REPO_GLOBAL")
	assert_equal "$output_after_creation" "FOUND"
}

# 6.d Verify gitlab repo is created.
@test "GitLab repo is found if it exists." {
	# TODO: verify the repository is added before testing whether it exists.
	# TODO: remove the repository after verifying it exists
	
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	test_repo_name="extra-project"
	create_empty_gitlab_repository_v0 "$test_repo_name" "$gitlab_username"
	output_after_creation=$(gitlab_mirror_repo_exists_in_gitlab "$test_repo_name")
	assert_equal "$output_after_creation" "FOUND"
	deletion_output=$(delete_gitlab_repo_if_it_exists "$test_repo_name")
	output_after_deletion=$(gitlab_mirror_repo_exists_in_gitlab "$test_repo_name")
	assert_equal "$output_after_deletion" "NOTFOUND"
}

# 6.d Verify gitlab repo is created.
@test "GitLab repo is not found if it does not exists." {
	# TODO: verify the repository is added before testing whether it exists.
	# TODO: remove the repository after verifying it exists
	something=$(get_project_list)
	output=$(gitlab_mirror_repo_exists_in_gitlab "non-existing-repository")
	assert_equal "$output" "NOTFOUND"
}

# 6.e Test if GitLab repository is created if it does not exist.
@test "GitLab repo is found if it is created." {
	# TODO: verify the repository is added before testing whether it exists.
	# TODO: remove the repository after verifying it exists
	something=$(get_project_list)
	
	# TODO: verify the repository is added before testing whether it exists.
	# TODO: remove the repository after verifying it exists
	
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	assert_equal "$gitlab_username" "root"
	
	create_empty_gitlab_repository_v0 "non-existing-repository" "$gitlab_username" 
	output=$(gitlab_mirror_repo_exists_in_gitlab "non-existing-repository")
	assert_equal "$output" "FOUND"
}

# 6.e Test if GitLab repository is created if it does not exist.
@test "GitLab repo is not found if it is deleted." {
	# TODO: verify the repository is added before testing whether it exists.
	# TODO: remove the repository after verifying it exists
	something=$(get_project_list)
	output=$(delete_gitlab_repo_if_it_exists "non-existing-repository")
	output=$(gitlab_mirror_repo_exists_in_gitlab "non-existing-repository")
	assert_equal "$output" "NOTFOUND"
}

@test "ALLOW DUPLICATE EXECUTION." {
	new_repo_name="extra-non-existing-project"
	assert_equal "$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")" "NOTFOUND"
	assert_equal "$(gitlab_mirror_repo_exists_in_gitlab "$new_repo_name")" "NOTFOUND"
}

# 6.e Ensure that the function that checks if the GitLab repo exists returns NOTFOUND for non-existant repos.
@test "Test non-existant local gitlab repo is identified as NOTFOUND." {
	# TODO: ommit this hardcoded username check
	non_existant_repository="NON_EXISTANT_REPOSITORY"
	actual_output=$(gitlab_repo_exists_locally "$non_existant_repository")
	assert_equal "$actual_output" "NOTFOUND"
}

# 6.e.0.T0 Clone GitLab repo if it does not exist locally.
@test "Test GitLab repo is cloned locally successfully." {
	# TODO: ommit this hardcoded username check
	gitlab_username="root" # works if the GitLab repo is public.
	################################################# IMPORTANT#############
	# TODO: make it work if the GitLab repo is private.
	gitlab_repo_name="sponsor_example"
	function_output=$(get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$gitlab_username" "$gitlab_repo_name")
	assert_equal "$function_output" "FOUND"
}


# 6.e.0.T1 Clone GitLab repo if it does not exist locally.
@test "Test GitLab repo is  not cloned if the repo does not exist in GitLab." {
	# TODO: ommit this hardcoded username check
	gitlab_username="root" # works if the GitLab repo is public.
	
	################################################# IMPORTANT#############
	# TODO: make it work if the GitLab repo is private.
	
	gitlab_repo_name="non-existing-repository"
	run bash -c "# source src/import.sh src/helper/GitHub/helper_github_status.sh && get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab $gitlab_username $gitlab_repo_name"
	assert_failure
	assert_output --partial "ERROR, the GitLab repository was not found in the GitLab server."
}

# 6.e.0.helper0 Verify that the GitLab repository can be pulled.
@test "Verify if gitlab repository can be pulled." {
	gitlab_repo_name="sponsor_example"
	paths=$(git_pull_gitlab_repo "$gitlab_repo_name")
	
	# TODO: generate list of acceptable output statements
	# Already up to date.
	assert_success
}


# 6.e.0.helper1 Verify that the GitLab repository can be pulled.
@test "Verify if non-existing repository pull throws error." {
	gitlab_repo_name="non-existing-repository"
	
	#assert_equal --partial "$paths" "PWD=$PWD"
	# TODO: generate list of acceptable output statements
	# Already up to date.
	run bash -c "# source src/import.sh src/helper/GitHub/helper_github_status.sh && git_pull_gitlab_repo $gitlab_repo_name"
	assert_failure
	assert_output "ERROR, the GitLab repository does not exist locally."
}

# 6.f.1.helper3
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# TODO: ensure assumption is replaced with actual call to function.
@test "Test if the git status command is parsed correctly to return the right unborn GitLab branch." {
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="no_attack_in_filecontent"
	company="GitLab"
	
	# Assumes the (sponsor_example) repository already exists inside the GitLab
	# server, which usually is not the case.
	# TODO: Check whether the repository exists in the GitLab server
	# TODO: If the repository does not exist in the GitLab server, upload it.
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# Checkout branch, if branch is found in local Gitlab repo.
	# TODO: re-enable
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name $company)"
	assert_success
	
	# Verify git status command returns the correct branch
	actual_result="$(parse_git_status_to_get_gitlab_branch "\${example_git_status_output}")"
	#actual_result="$(parse_git_status_to_get_gitlab_branch $example_git_status_output)"
	assert_equal "$actual_result" "$gitlab_branch_name"
}


# 6.f.1.helper2
# gitlab branch correctly.
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# TODO: ensure assumption is replaced with actual call to function.
@test "Test if the get_current_unborn_gitlab_branch function returns the current unborn gitlab branch correctly." {
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="no_attack_in_filecontent"
	company="GitLab"
	
	# Assumes the (sponsor_example) repository already exists inside the GitLab
	# server, which usually is not the case.
	# TODO: Check whether the repository exists in the GitLab server
	# TODO: If the repository does not exist in the GitLab server, upload it.
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# Checkout branch, if branch is found in local Gitlab repo.
	# TODO: re-enable
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name $company)"
	assert_success
	
	# Verify git status command returns the correct branch
	actual_result="$(parse_git_status_to_get_gitlab_branch "\${example_git_status_output}")"
	assert_equal "$actual_result" "$gitlab_branch_name"
	
	# Verify the unborn branch is returned correctly.
	actual_result="$(get_current_unborn_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	assert_equal "$actual_result" "$gitlab_branch_name"
}


# 6.f.1.helper1
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# TODO: ensure assumption is replaced with actual call to function.
@test "Test the get_current_gitlab_branch function returns the correct GitLab branch." {
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="no_attack_in_filecontent"
	company="GitLab"
	
	# Assumes the (sponsor_example) repository already exists inside the GitLab
	# server, which usually is not the case.
	# TODO: Check whether the repository exists in the GitLab server
	# TODO: If the repository does not exist in the GitLab server, upload it.
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name $company)"
	assert_success
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	actual_result="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	assert_equal "$actual_result" "$gitlab_branch_name"
}


# 6.f.1.helper0 success
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# TODO: ensure assumption is replaced with actual call to function.
@test "Test the assert_current_gitlab_branch function correctly identifies the correct branch." {
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="no_attack_in_filecontent"
	company="GitLab"
	
	# Assumes the (sponsor_example) repository already exists inside the GitLab
	# server, which usually is not the case.
	# TODO: Check whether the repository exists in the GitLab server
	# TODO: If the repository does not exist in the GitLab server, upload it.
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name $company)"
	assert_success
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	actual_result="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	assert_equal "$actual_result" "$gitlab_branch_name"
	
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	#run bash -c "# source src/import.sh src/helper/helper.sh src/helper/GitHub/helper_github_status.sh && assert_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company"
	run bash -c "# source src/import.sh src/helper/GitHub/helper_github_status.sh && assert_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company"
	assert_success
}


# 6.f.1.helper0 failure
@test "Test the assert_current_gitlab_branch function throws error on the non-existing branch." {
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="no_attack_in_filecontent"
	company="GitLab"
	
	# Assumes the (sponsor_example) repository already exists inside the GitLab
	# server, which usually is not the case.
	# TODO: Check whether the repository exists in the GitLab server
	# TODO: If the repository does not exist in the GitLab server, upload it.
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name $company)"
	assert_success
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	actual_result="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	assert_equal "$actual_result" "$gitlab_branch_name"
	
	
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	non_existing_branchname="non-existing-branchname"
	#run bash -c "# source src/import.sh src/helper/helper.sh && assert_current_gitlab_branch $gitlab_repo_name $non_existing_branchname $company"
	run bash -c "# source src/import.sh src/helper/GitHub/helper_github_status.sh && assert_current_gitlab_branch $gitlab_repo_name $non_existing_branchname $company"
	
	assert_failure
	assert_output "The current Gitlab branch does not match the expected Gitlab branch:$non_existing_branchname"
}

# 6.f.1.
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# TODO: ensure assumption is replaced with actual call to function.
@test "Test the checkout_branch_in_gitlab_repo function checks out the correct GitLab branch." {
	gitlab_repo_name="sponsor_example"
	gitlab_branch_name="no_attack_in_filecontent"
	company="GitLab"
	
	# Assumes the (sponsor_example) repository already exists inside the GitLab
	# server, which usually is not the case.
	# TODO: Check whether the repository exists in the GitLab server
	# TODO: If the repository does not exist in the GitLab server, upload it.
	# Clone the GitLab repository from the GitLab server
	get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab "$GITLAB_SERVER_ACCOUNT_GLOBAL" "$gitlab_repo_name"
	
	# Checkout branch, if branch is found in local Gitlab repo.
	actual_result="$(checkout_branch_in_gitlab_repo $gitlab_repo_name $gitlab_branch_name $company)"
	assert_success
	
	# Verify the get_current_gitlab_branch function returns the correct branch.
	actual_result="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name $company)"
	assert_equal "$actual_result" "$gitlab_branch_name"
}