#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

# source src/import.sh
source src/import.sh
#source src/CI/call_CI/run_ci_on_github_repo.sh

# Method that executes all tested main code before running tests.
###setup() {
###	
###	# print test filename to screen.
###	if [ "${BATS_TEST_NUMBER}" = 1 ];then
###		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
###	fi
###	
###	if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
###		true
### # TODO: change into elif to only install and uninstall to NOTRUNNING.
###	else
###		#+ uninstall and re-installation by default
###		# Uninstall GitLab Runner and GitLab Server
###		run bash -c "./uninstall_gitlab.sh -h -r -y"
###	
###		# Install GitLab Server
###		run bash -c "./install_gitlab.sh -s -r"
###	fi
###}

@test "Test if GitHub repository is cloned correctly." {
	local github_username="a-t-0"
	local github_repo_name="sponsor_example"
	
	# Delete the repository locally if it exists.
	remove_dir "$MIRROR_LOCATION/GitHub/$github_repo_name"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"

	# TODO: change this method to download with https?
	# Download the GitHub repo on which to run the GitLab CI:
	download_github_repo_on_which_to_run_ci "$github_username" "$github_repo_name"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
	
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"

	# Delete the repository locally if it exists.
	remove_dir "$MIRROR_LOCATION/GitHub/$github_repo_name"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
}

@test "Test copying github branches with yaml to GitLab repo." {
	local github_username="a-t-0"
	local github_repo_name="sponsor_example"
	
	# Delete the repository locally if it exists.
	remove_dir "$MIRROR_LOCATION/GitHub/$github_repo_name"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"

	# TODO: change this method to download with https?
	# Download the GitHub repo on which to run the GitLab CI:
	download_github_repo_on_which_to_run_ci "$github_username" "$github_repo_name"
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
	
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"

	copy_github_branches_with_yaml_to_gitlab_repo "$github_username" "$github_repo_name"
	# TODO: write some assert to verify yamls are copied to GitLab repo.

	# Delete the repository locally if it exists.
	remove_dir "$MIRROR_LOCATION/GitHub/$github_repo_name"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
}

# TODO: write test that verifies this works on a new clean/empty repo.
# TODO: make this run after the loop over github branches.
@test "Test pushing GitHub commit build status to repo with build statusses is successful." {
	skip
	local github_username="a-t-0"
	local github_repo_name="sponsor_example"
	local github_branch_name="main"
	local github_commit_sha="85ad4b39fe9c9af893b4d7b35a76a595a8e680d5"
	
	
	copy_commit_build_status_to_github_status_repo "$github_username" "$github_repo_name" "$github_branch_name" "$github_commit_sha" "success"
	
	# TODO: write asserts
	# Assert svg file is created correctly
	assert_equal $(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/build_status.svg") "FOUND"
	
	# Assert GitHub commit build status txt file is created correctly
	assert_equal $(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/$github_commit_sha.txt") "FOUND"
	
	# Assert GitHub commit build status txt file contains the right data.
	assert_equal $(cat "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/$github_commit_sha.txt") "success"
	
	push_commit_build_status_in_github_status_repo_to_github "$github_username"
	assert_success
	
	# Delete GitHub build status repository after test.
	sudo rm -r "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
}

# TODO: make this run after the loop over github branches.
@test "Test export successful GitHub commit build status to repo with build statusses is exported correctly." {
	skip
	github_username="a-t-0"
	github_repo_name="sponsor_example"
	github_branch_name="main"
	github_commit_sha="85ad4b39fe9c9af893b4d7b35a76a595a8e680d5"
	
	
	copy_commit_build_status_to_github_status_repo "$github_username" "$github_repo_name" "$github_branch_name" "$github_commit_sha" "success"
	
	# TODO: write asserts
	# Assert svg file is created correctly
	assert_equal $(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/build_status.svg") "FOUND"
	
	# Assert GitHub commit build status txt file is created correctly
	assert_equal $(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/$github_commit_sha.txt") "FOUND"
	
	# Assert GitHub commit build status txt file contains the right data.
	assert_equal $(cat "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/$github_commit_sha.txt") "success"
	
	# Delete GitHub build status repository after test.
	sudo rm -r "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
}

# TODO: make this run after the loop over github branches.
@test "Test export failed GitHub commit build status to repo with build statusses is exported correctly." {
	skip
	github_username="a-t-0"
	github_repo_name="sponsor_example"
	github_branch_name="main"
	github_commit_sha="85ad4b39fe9c9af893b4d7b35a76a595a8e680d5"
	
	
	copy_commit_build_status_to_github_status_repo "$github_username" "$github_repo_name" "$github_branch_name" "$github_commit_sha" "failed"
	
	# TODO: write asserts
	# Assert svg file is created correctly
	assert_equal $(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/build_status.svg") "FOUND"
	
	# Assert GitHub commit build status txt file is created correctly
	assert_equal $(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/$github_commit_sha.txt") "FOUND"
	
	# Assert GitHub commit build status txt file contains the right data.
	assert_equal $(cat "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/$github_commit_sha.txt") "failed"
	
	# Delete GitHub build status repository after test.
	sudo rm -r "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
}

# TODO: make this run after the loop over github branches.
@test "Test export error GitHub commit build status to repo with build statusses is exported correctly." {
	skip
	github_username="a-t-0"
	github_repo_name="sponsor_example"
	github_branch_name="main"
	github_commit_sha="85ad4b39fe9c9af893b4d7b35a76a595a8e680d5"
	
	
	copy_commit_build_status_to_github_status_repo "$github_username" "$github_repo_name" "$github_branch_name" "$github_commit_sha" "error"
	
	# TODO: write asserts
	# Assert svg file is created correctly
	assert_equal $(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/build_status.svg") "FOUND"
	
	# Assert GitHub commit build status txt file is created correctly
	assert_equal $(file_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/$github_commit_sha.txt") "FOUND"
	
	# Assert GitHub commit build status txt file contains the right data.
	assert_equal $(cat "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"/"$github_repo_name"/"$github_branch_name""/$github_commit_sha.txt") "error"
	
	# Delete GitHub build status repository after test.
	sudo rm -r "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
	assert_file_not_exist "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
}

@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test that is skipped." {
	skip
	some_function
}


@test "Test verifies GitHub repository is cloned." {
	skip
	github_username="a-t-0"
	github_repo_name="sponsor_example"
	
	download_github_repo_on_which_to_run_ci "$github_username" "$github_repo_name"
	
	repo_was_cloned=$(verify_github_repository_is_cloned "$github_repo_name" "$MIRROR_LOCATION/GitHub/$github_repo_name")
	assert_equal "$repo_was_cloned" "FOUND"

}




@test "Test get GitLab commit function." {
	skip
}

# TODO: make this run after the loop over github branches.
@test "Test get GitLab commit build status function." {
	skip
	github_username="a-t-0"
	github_repo_name="sponsor_example"
	github_branch_name="main"
	
	# Get GitLab username.
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	
	# Get GitLab personal access token from hardcoded file.
	GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
	
	# Get last commit of GitLab repo.
	gitlab_commit_sha=$(get_commit_sha_of_branch "$github_branch_name" "$github_repo_name" "$gitlab_username" "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL")
	gitlab_commit_sha=$(echo "$gitlab_commit_sha" | tr -d '"') # removes double quotes at start and end.
	echo "gitlab_commit_sha=$gitlab_commit_sha"
	
	assert_equal "1f9cccbef76720f8be88b6b9c7104ca06c0a280a" "$gitlab_commit_sha"
	
	# Get build status
	gitlab_ci_build_status=$(get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")
	echo "gitlab_ci_build_status=$gitlab_ci_build_status"
	#assert_equal "success" "$gitlab_ci_build_status"
	assert_equal "failure" "$gitlab_ci_build_status"
}

# TODO: make this run after the loop over github branches.
@test "Test set GitHub commit build status function." {
	skip
	github_username="a-t-0"
	github_repo_name="sponsor_example"
	github_branch_name="main"
	github_commit_sha="85ad4b39fe9c9af893b4d7b35a76a595a8e680d5"
	
	# get GitHub personal access token or verify ssh access to support private repositories.
	github_personal_access_code=$(echo "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
	
	# Get GitLab username.
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	
	# Get GitLab personal access token from hardcoded file.
	GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
	
	# Get GitLab server url from credentials file.
	GITLAB_SERVER_HTTP_URL=$(echo "$GITLAB_SERVER_HTTP_URL" | tr -d '\r')
	
	
	# Get last commit of GitLab repo.
	gitlab_commit_sha=$(get_commit_sha_of_branch "$github_branch_name" "$github_repo_name" "$gitlab_username" "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL")
	gitlab_commit_sha=$(echo "$gitlab_commit_sha" | tr -d '"') # removes double quotes at start and end.
	#echo "gitlab_commit_sha=$gitlab_commit_sha"
	
	assert_equal "1f9cccbef76720f8be88b6b9c7104ca06c0a280a" "$gitlab_commit_sha"
	
	# Get build status
	gitlab_ci_build_status=$(get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")
	#echo "gitlab_ci_build_status=$gitlab_ci_build_status"
	#echo "github_personal_access_code=$github_personal_access_code"
	#echo "GITLAB_SERVER_HTTP_URL=$GITLAB_SERVER_HTTP_URL"
	#assert_equal "success" "$gitlab_ci_build_status"
	assert_equal "failure" "$gitlab_ci_build_status"
	
	output=$(set_build_status_of_github_commit_using_github_pat "$github_username" "$github_repo_name" "$github_commit_sha" "$github_personal_access_code" "$GITLAB_SERVER_HTTP_URL" "$gitlab_ci_build_status")
	#echo "output=$output"
	assert_equal "something" "$output"
}


# TODO: make this run after the loop over github branches.
@test "Test set GitHub commit build status is exported correctly." {
	skip
	github_username="a-t-0"
	github_repo_name="sponsor_example"
	github_branch_name="main"
	github_commit_sha="85ad4b39fe9c9af893b4d7b35a76a595a8e680d5"
	
	# get GitHub personal access token or verify ssh access to support private repositories.
	github_personal_access_code=$(echo "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
	
	# Get GitLab username.
	gitlab_username=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
	
	# Get GitLab personal access token from hardcoded file.
	GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
	
	# Get GitLab server url from credentials file.
	GITLAB_SERVER_HTTP_URL=$(echo "$GITLAB_SERVER_HTTP_URL" | tr -d '\r')
	
	
	# Get last commit of GitLab repo.
	gitlab_commit_sha=$(get_commit_sha_of_branch "$github_branch_name" "$github_repo_name" "$gitlab_username" "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL")
	gitlab_commit_sha=$(echo "$gitlab_commit_sha" | tr -d '"') # removes double quotes at start and end.
	#echo "gitlab_commit_sha=$gitlab_commit_sha"
	
	assert_equal "1f9cccbef76720f8be88b6b9c7104ca06c0a280a" "$gitlab_commit_sha"
	
	# Get build status
	gitlab_ci_build_status=$(get_gitlab_ci_build_status "$github_repo_name" "$github_branch_name" "$gitlab_commit_sha")
	#echo "gitlab_ci_build_status=$gitlab_ci_build_status"
	#echo "github_personal_access_code=$github_personal_access_code"
	#echo "GITLAB_SERVER_HTTP_URL=$GITLAB_SERVER_HTTP_URL"
	#assert_equal "success" "$gitlab_ci_build_status"
	assert_equal "failure" "$gitlab_ci_build_status"
	
	output=$(set_build_status_of_github_commit_using_github_pat "$github_username" "$github_repo_name" "$github_commit_sha" "$github_personal_access_code" "$GITLAB_SERVER_HTTP_URL" "$gitlab_ci_build_status")
	#echo "output=$output"
	assert_equal "something" "$output"
}