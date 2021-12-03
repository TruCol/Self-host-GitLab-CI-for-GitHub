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
	delete_target_folder
	# Create personal GitLab access token (it is hardcoded in this repo, but needs to
	# be pushed/created in the GitLab server).
	# TODO: re-enable
	create_gitlab_personal_access_token
	# TODO: https://github.com/TruCol/setup_your_own_GitLab_CI/issues/6
	#delete_repository
	#sleep 60
	create_repository
	clone_repository
	export_repo
	commit_changes
	push_changes
}

# TODO: Check if personal access token is already made, if not, create it.
# Verify this has access:
# TODO: replace token with variable
#curl --header "PRIVATE-TOKEN: somelongpersonalaccesscode3" "http://127.0.0.1/api/v4/personal_access_tokens"
# If not hasaccess, run personal access token creation
# source src/create_personal_access_token.sh && create_gitlab_personal_access_token
# check has access again, if not, raise exception.

create_repository() {
	repo_name=$1
	
	# load personal_access_token (from hardcoded data)
	personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
	
	# Create command that creates the repository in GitLab
	command="curl -H Content-Type:application/json http://127.0.0.1/api/v4/projects?private_token=""$personal_access_token -d ""{ \"name\": \"""$repo_name""\" }"
	

	# Create the repository in the GitLab server
	{ # try
		output=$(curl -H "Content-Type:application/json" http://127.0.0.1/api/v4/projects?private_token=$personal_access_token -d "{ \"name\": \"$repo_name\" }")
		echo "output=$output"
		# TODO: save your output
		true
	} || { # catch
		# TODO: save log for exception
		true
	}
}

#source src/run_ci_job.sh && delete_repository
delete_repository() {
	repo_name="$1"
	repo_username="$2"
	# load personal_access_token
	personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
	
	gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
	gitlab_server_password=$(echo $gitlab_server_password | tr -d '\r')
	###repo_name=$SOURCE_FOLDERNAME
	# TODO: modify the functions that call this functions to pass the source folder name.
	
	
	# TODO: check if the repo exists (unstable behaviour, sometimes empty when repository DOES exist).
	exists=$(git ls-remote --exit-code -h "http://$gitlab_username:$gitlab_server_password@127.0.0.1/$repo_username/$repo_name")
	echo "exists=$exists"
	# DELETE the repository
	if [ -z "$exists" ]; then
		echo "Repo does not exist."
	else
		#output=$(curl -H 'Content-Type: application/json' -H "Private-Token: $personal_access_token" -X DELETE http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name)
		output=$(curl -H 'Content-Type: application/json' -H "Private-Token: $personal_access_token" -X DELETE http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name)
	fi
	
	# TODO: loop untill repository is deleted (otherwise the following error is thrown:
	# TODO: check if the repo exists
	#output={"message":{"base":["The project is still being deleted. Please try again later."],"limit_reached":[]}}

}

delete_existing_repository() {
	repo_name="$1"
	repo_username="$2"
	
	# load personal_access_token
	personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
	
	output=$(curl -H 'Content-Type: application/json' -H "Private-Token: $personal_access_token" -X DELETE http://127.0.0.1/api/v4/projects/$repo_username%2F$repo_name)
}

#source src/run_ci_job.sh && clone_repository
# TODO: rename to clone_gitlab_repository_from _local_server
clone_repository() {
	repo_name=$1
	gitlab_username=$2
	gitlab_server_password=$3
	gitlab_server=$4
	target_directory=$5
	
	# TODO:write test to verify the gitlab username and server don't end with a spacebar character.	
	
	# Clone the GitLab repository into the GitLab mirror storage location.
	output=$(cd "$target_directory" && git clone http://$gitlab_username:$gitlab_server_password@$gitlab_server/$gitlab_username/$repo_name.git)
}

clone_github_repository() {
	if [[ "$1" != "" ]] && [[ "$2" != "" ]] && [[ "$3" != "" ]] && [[ "$4" != "" ]]; then
		github_username="$1"
		github_repository="$2"
		has_access="$3"
		target_directory="$4"
	fi
	#echo  "github_username=$github_username"
	#echo  "github_repository=$github_repository"
	#echo  "has_access=$has_access"
	#echo  "target_directory=$target_directory"
	
	# Remove target directory if it already exists.
	remove_dir "$target_directory"
	
	if [ "$has_access"=="HASACCESS" ]; then
		git clone git@github.com:"$github_username"/"$github_repository" "$target_directory"
	else
		$(git clone https://github.com/"$github_username"/"$github_repository".git "$target_directory")
		echo "Did not get ssh_access, downloaded using https, assumed it was a public repository."
		# TODO: support asking for GitHub username and pw to allow cloning private repositories over HTTPS.
		# TODO: support asking for GitHub personal access token to allow cloning private repositories over HTTPS.
	fi
}

push_to_github_repository() {
	github_username=$1
	has_access=$2
	target_directory=$3
	
	if [ "$has_access"=="HASACCESS" ]; then
		#git push git@github.com:"$github_username"/"$github_repository"
		output=$(cd "$target_directory" && git push)
	else
		#$(cd "$target_directory" && git push https://github.com/"$github_username"/"$github_repository".git)
		echo "Did not get ssh_access, downloaded using https, assumed it was a public repository."
		# TODO: support asking for GitHub username and pw to allow cloning private repositories over HTTPS.
		# TODO: support asking for GitHub personal access token to allow cloning private repositories over HTTPS.
		exit 125
	fi
}

commit_changes() {
	target_directory=$1
	#echo "$commit_changes"
	output=$(cd "$target_directory" && git add *)
	output=$(cd "$target_directory" && git add .)
	output=$(cd "$target_directory" && git add -A)
	output=$(cd "$target_directory" && git commit -m "Uploaded files to trigger GitLab runner.")
}

push_changes() {
	repo_name=$1
	gitlab_username=$2
	gitlab_server_password=$3
	gitlab_server=$4
	target_directory=$5
	
	output=$(cd "$target_directory" && git push http://$gitlab_username:$gitlab_server_password@$gitlab_server/$gitlab_username/$repo_name.git)
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




