#!/bin/bash

source src/helper.sh
source src/hardcoded_variables.txt
source src/creds.txt
source src/create_personal_access_token.sh

# TODO: change 127.0.0.1 with gitlab server address variable
# TODO: ensure the receipe works every time, instead of every other time.
# There currently is an error when the gitlab repo is deleted or cloned, which is
# resolved the second time the function is called because at that time the repo is
# deleted or cloned/created.

#source src/run_ci_job.sh && receipe
create_and_run_ci_job() {
	# Get GitLab default username.
	gitlab_username=$(echo "$gitlab_server_account" | tr -d '\r')
	assert_equal "$gitlab_username" "root"

	delete_target_folder
	# Create personal GitLab access token (it is hardcoded in this repo, but needs to
	# be pushed/created in the GitLab server).
	# TODO: re-enable
	create_gitlab_personal_access_token
	# TODO: https://github.com/TruCol/setup_your_own_GitLab_CI/issues/6
	#delete_gitlab_repository_if_it_exists "$PUBLIC_GITHUB_TEST_REPO" "$gitlab_username"
	#sleep 60
	create_empty_repository_v0 "$PUBLIC_GITHUB_TEST_REPO" "$gitlab_username"
	clone_repository
	export_repo
	commit_changes
	push_changes
}