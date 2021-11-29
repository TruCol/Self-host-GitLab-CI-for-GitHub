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
	

# Method that executes all tested main code before running tests.
setup() {
	# print test filename to screen.
	if [ "${BATS_TEST_NUMBER}" = 1 ];then
		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
	fi
	
	if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
		true
	else
		read -p "Now re-i	nstalling GitLab."
		#+ uninstall and re-installation by default
		# Uninstall GitLab Runner and GitLab Server
		run bash -c "./uninstall_gitlab.sh -h -r -y"
	
		# Install GitLab Server
		run bash -c "./install_gitlab.sh -s -r"
	fi
}

### Activate GitHub ssh account
@test "Check if ssh-account is activated after activating it." {
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME" a-t-0
	
	activate_ssh_account "$GITHUB_USERNAME"
	# Expected function output
	#Agent pid 123
	#Identity added: /home/name/.ssh/a-t-0 (some@email.domain)
	
	# Assert the ssh-key is found in the ssh agent
	assert_equal "$(any_ssh_key_is_added_to_ssh_agent "$GITHUB_USERNAME" "$(ssh-add -L)")" "FOUND"
	#assert_equal "$(github_account_ssh_key_is_added_to_ssh_agent "$GITHUB_USERNAME" "$(ssh-add -L)")" "FOUND"
}





@test "Check pull access to public repository." {
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME" a-t-0
	has_access="$(check_ssh_access_to_repo "$GITHUB_USERNAME" "$GITHUB_STATUS_WEBSITE")"
	assert_equal "$has_access" "HASACCESS"
}

@test "Check error is thrown when checking pull access to non-existant repository." {
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME" a-t-0
	#has_access="$()"
	non_existant_repository="NON_EXISTANT_REPOSITORY"
	run bash -c "source src/mirror_github_to_gitlab.sh && check_ssh_access_to_repo $GITHUB_USERNAME $non_existant_repository"
	assert_failure
	assert_output 'Your ssh-account:'$GITHUB_USERNAME' does not have pull access to the repository:'$non_existant_repository
}





@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test that is skipped." {
	skip
	some_function
}

### SSH tests
@test 'Get last element of line, when it is delimted using the space character.' {
	line_one="ssh-ed25519 longcode/longcode somename-somename-123"
	line_two="ssh-rsa longcode/longcode+longcode+longcode/longcode/longcode+longcode/longcode+longcode somename@somename-somename-123"
	line_three="ssh-ed25519 longcode somename@somename-somename-123"
	line_four="ssh-ed25519 longcode/longcode+longcode somename@somename.somename"
	assert_equal "$(get_last_space_delimted_item_in_line "$line_one")" "somename-somename-123"
	assert_equal "$(get_last_space_delimted_item_in_line "$line_two")" "somename@somename-somename-123"
	assert_equal "$(get_last_space_delimted_item_in_line "$line_three")" "somename@somename-somename-123"
	assert_equal "$(get_last_space_delimted_item_in_line "$line_four")" "somename@somename.somename"
}

@test 'If ssh account is activated, FOUND is returned' {
	assert_equal "$(github_account_ssh_key_is_added_to_ssh_agent "somename@somename-somename-123" "\${example_lines}")" "FOUND"
}

@test 'If ssh account is not activated, NOTFOUND is returned' {
	assert_equal "$(github_account_ssh_key_is_added_to_ssh_agent "this_username_is_in_not_inthe_example" "\${example_lines}")" "NOTFOUND"
}

# Do not allow partial match but only allow complete match.
@test 'If ssh account is not activated, yet if it is a subset of an ssh account that IS activated, NOTFOUND is (still) returned' {
	assert_equal "$(github_account_ssh_key_is_added_to_ssh_agent "some" "\${example_lines}")" "NOTFOUND"
}





@test "Assert code execution is terminated if a required ssh-key is not activated." {
	non_existant_ssh_account="Some_random_non_existing_ssh_account_31415926531"
	
	run bash -c "source src/helper.sh && verify_ssh_key_is_added_to_ssh_agent $non_existant_ssh_account"
	assert_failure
	assert_output 'Please ensure the ssh-account '$non_existant_ssh_account' key is added to the ssh agent. You can do that with commands:'"\\n"' eval $(ssh-agent -s)'"\n"'ssh-add ~/.ssh/'$non_existant_ssh_account''"\n"' Please run this script again once you are done.'
	#assert_output "$feedback"
}

@test "Assert code execution is proceeded if the required ssh-key is activated." {
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME" a-t-0
	
	existant_ssh_account="$GITHUB_USERNAME"
	
	run bash -c "source src/helper.sh && verify_ssh_key_is_added_to_ssh_agent $existant_ssh_account"
	assert_success
}



##################################################################### ORDER##############################################


### 0. Test GitHub ssh-key is added to ssh-agent
@test "Check if ssh-account is activated." {
	# TODO: ommit this hardcoded username check
	assert_equal "$GITHUB_USERNAME" a-t-0
	
	ssh_output=$(ssh-add -L)
	
	
	# Get the email address tied to the ssh-account.
	ssh_email=$(get_ssh_email "$GITHUB_USERNAME")
	echo "ssh_email=$ssh_email"
	echo "ssh_output=$ssh_output"
	
	# Check if the ssh key is added to ssh-agent by means of username.
	found_ssh_username="$(github_account_ssh_key_is_added_to_ssh_agent "$GITHUB_USERNAME" "\${ssh_output}")"
	
	# Check if the ssh key is added to ssh-agent by means of email.
	found_ssh_email="$(github_account_ssh_key_is_added_to_ssh_agent "$ssh_email" "\${ssh_output}")"
	
	if [ "$found_ssh_username" == "FOUND" ]; then
		assert_equal  "$found_ssh_username" "FOUND"
	else
		assert_equal  "$found_ssh_email" "FOUND"
	fi
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
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
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


# 5. Verify gitlab repo is created.
@test "Test if GitLab repository is created." {
	create_repository "$PUBLIC_GITHUB_TEST_REPO"
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

# 6.d Verify gitlab repo is created.
@test "GitLab repo is found if it exists." {
	# TODO: verify the repository is added before testing whether it exists.
	# TODO: remove the repository after verifying it exists
	test_repo_name="extra-project"
	create_repo_if_not_exists "$test_repo_name"
	output_after_creation=$(gitlab_mirror_repo_exists_in_gitlab "$test_repo_name")
	assert_equal "$output_after_creation" "FOUND"
	deletion_output=$(delete_repo_if_it_exists "$test_repo_name")
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
	creating_repo_output=$(create_repo_if_not_exists "non-existing-repository")
	output=$(gitlab_mirror_repo_exists_in_gitlab "non-existing-repository")
	assert_equal "$output" "FOUND"
}

# 6.e Test if GitLab repository is created if it does not exist.
@test "GitLab repo is not found if it is deleted." {
	# TODO: verify the repository is added before testing whether it exists.
	# TODO: remove the repository after verifying it exists
	something=$(get_project_list)
	output=$(delete_repo_if_it_exists "non-existing-repository")
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
	function_output=$(get_gitlab_repo_if_not_exists "$gitlab_username" "$gitlab_repo_name")
	assert_equal "$function_output" "FOUND"
}


# 6.e.0.T1 Clone GitLab repo if it does not exist locally.
@test "Test GitLab repo is  not cloned if the repo does not exist in GitLab." {
	# TODO: ommit this hardcoded username check
	gitlab_username="root" # works if the GitLab repo is public.
	
	################################################# IMPORTANT#############
	# TODO: make it work if the GitLab repo is private.
	
	gitlab_repo_name="non-existing-repository"
	run bash -c "source src/mirror_github_to_gitlab.sh && get_gitlab_repo_if_not_exists $gitlab_username $gitlab_repo_name"
	assert_failure
	assert_output --partial "ERROR, the GitLab repository was not found in the GitLab server."
}

# Verify that the GitLab repository can be pulled.
@test "Verify if gitlab repository can be pulled." {
	gitlab_repo_name="sponsor_example"
	paths=$(git_pull_gitlab_repo "$gitlab_repo_name")
	#assert_equal --partial "$paths" "PWD=$PWD"
	# TODO: generate list of acceptable output statements
	# Already up to date.
	assert_success
}


# Verify that the GitLab repository can be pulled.
@test "Verify if non-existing repository pull throws error." {
	gitlab_repo_name="non-existing-repository"
	
	#assert_equal --partial "$paths" "PWD=$PWD"
	# TODO: generate list of acceptable output statements
	# Already up to date.
	run bash -c "source src/mirror_github_to_gitlab.sh && git_pull_gitlab_repo $gitlab_repo_name"
	assert_failure
	assert_output "The GitLab repository does not exist locally."
}