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
	github_repo_name="$1"

	# Get GitLab default username.
	gitlab_username=$(echo "$gitlab_server_account" | tr -d '\r')
	assert_equal "$gitlab_username" "root"

	delete_target_folder
	# Create personal GitLab access token (it is hardcoded in this repo, but needs to
	# be pushed/created in the GitLab server).
	create_gitlab_personal_access_token
	create_empty_repository_v0 "$PUBLIC_GITHUB_TEST_REPO" "$gitlab_username"
	
	# TODO: allow specification of which repository
	clone_repository
	export_repo
	commit_changes
	push_changes
}

# TODO: remove and use its duplicate in push_repo_to_gitlab.sh
commit_changes() {
	output=$(cd ../$SOURCE_FOLDERNAME && git add *)
	output=$(cd ../$SOURCE_FOLDERNAME && git add .gitignore)
	output=$(cd ../$SOURCE_FOLDERNAME && git add .gitlab-ci.yml)
	output=$(cd ../$SOURCE_FOLDERNAME && git commit -m "Uploaded files to trigger GitLab runner.")
}

# TODO: remove and use its duplicate in push_repo_to_gitlab.sh
push_changes() {
	repo_name=$(echo $SOURCE_FOLDERNAME | tr -d '\r')
	gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
	gitlab_server_password=$(echo $gitlab_server_password | tr -d '\r')
	command="http://$gitlab_username:$gitlab_server_password@127.0.0.1/$gitlab_username/$repo_name.git"
	echo "command=$command"
	echo "SOURCE_FOLDERNAME=$SOURCE_FOLDERNAME"
	output=$(cd ../$SOURCE_FOLDERNAME && git push http://$gitlab_username:$gitlab_server_password@127.0.0.1/$gitlab_username/$repo_name.git)
	echo "output=$output"
}

# source src/run_ci_job.sh && export_repo
# Write function that exportis the test-repository to a separate external folder.
delete_target_folder() {
	# check if target folder already exists
	# delete target folder if it already exists
	if [ -d "../$SOURCE_FOLDERNAME" ] ; then
	    sudo rm -r "../$SOURCE_FOLDERNAME"
	fi
	# create target folder
	# copy source folder to target
	
}

export_repo() {
	# check if target folder already exists
	
	# delete target folder if it already exists
	#$(delete_target_folder)
	cp -r "$SOURCE_FOLDERPATH" ../
	# create target folder
	# copy source folder to target
	
}

#source src/run_ci_job.sh && clone_repository
# TODO: remove and use its duplicate in push_repo_to_gitlab.sh
clone_repository() {
	repo_name=$(echo $SOURCE_FOLDERNAME | tr -d '\r')
	gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
	gitlab_server_password=$(echo $gitlab_server_password | tr -d '\r')
	
	#sudo rm -r ../$repo_name
	echo "/$gitlab_server_account=$gitlab_server_account"
	echo "/$gitlab_server_password=$gitlab_server_password"
	command="http://$gitlab_username:$gitlab_server_password@127.0.0.1/$gitlab_username/$repo_name.git"
	echo "command=$command"
	echo "SOURCE_FOLDERNAME=$SOURCE_FOLDERNAME"
	output=$(cd .. && git clone http://$gitlab_username:$gitlab_server_password@127.0.0.1/$gitlab_username/$repo_name.git)
	echo "output=$output"
}