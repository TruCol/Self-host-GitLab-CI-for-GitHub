#!/bin/bash 
# get a list of the repositories
# per repository get a list of branches
# per branch get a list of commits
# per commit check if it contains a gitlab yml file
# if it does, check if you can find its log file.


source src/hardcoded_variables.txt
#source src/creds.txt
source src/helper.sh
source src/push_repo_to_gitlab.sh

yes | sudo apt install jq
yes | sudo apt install xclip

# Read from which repository and branch one would like to push the build status
github_username=$1
desired_repository=$2
desired_branch=$3
has_access=$4

# load personal_access_token, gitlab username, repository name
personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
gitlab_username=$(echo $gitlab_server_account | tr -d '\r')

# Clone the build-status-website repository from GitHub.
# Note the github user here is not the owner of the repo on which the CI is ran, but the owner of the github build-status-website repository (which is hardcoded, hence capitalised).
# TODO: verify bash recognises difference between capitalised and non-captialised variables.
clone_github_repository "$GITHUB_USERNAME" "$GITHUB_STATUS_WEBSITE" "$has_access" "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE"


# Get a list of the repositories in your own local GitLab server (that runs the GitLab runner CI).
repositories=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
readarray -t repo_arr <  <(echo "$repositories" | jq ".[].path")
#echo "repo_arr =${repo_arr[@]}"

# TODO: filter to keep only  repositories of which GitHub wants the build status.

# Get the GitLab build statusses and export them to the GitHub build status website.
get_and_export_build_status_to_github_build_status_website_repo() {
	repository_name="$1"
	branch_name=$(echo "$2" | tr -d '"') # removes double quotes at start and end.
	branch_commit=$(echo "$3" | tr -d '"') # removes double quotes at start and end.
	
	# curl --header "PRIVATE-TOKEN: <your_access_token>" "http://127.0.0.1/api/v4/projects/1/pipelines"
	pipelines=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repository_name/pipelines")
	
	# get build status from pipelines
	job=$(echo $pipelines | jq -r 'map(select(.sha == "'"$branch_commit"'"))')
	status=$(echo "$(echo $job | jq ".[].status")" | tr -d '"')
		
	# Create a folder of the repository on which a CI has been ran, inside the GitHub build status website repository, if it does not exist yet
	# Also add a folder for the branch(es) of that GitLab CI repository, in that respective folder.
	
	mkdir -p "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch_name"
	read -p "branch_name=$branch_name,status=$status"
	
	# Create build status icon
	if [  "$status" == "pending" ] || [ "$status" == "running" ]; then
		# start recursive loop if the status is pending
		sleep 10
		get_and_export_build_status_to_github_build_status_website_repo "$1" "$2" "$3"
	elif [  "$status" == "passed" ]; then
		cp "src/svgs/passed.svg" "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch_name""/build_status.svg"
	elif [  "$status" == "failed" ]; then
		cp "src/svgs/failed.svg" "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch_name""/build_status.svg"
	elif [  "$status" == "error" ]; then
		cp "src/svgs/error.svg" "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch_name""/build_status.svg"
	elif [  "$status" == "unknown" ]; then
		cp "src/svgs/unknown.svg" "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch_name""/build_status.svg"
	fi
}

# Export the GitLab build status of each *TODO: relevant* GitLab runner CI repository
# to the GItHub build status website repository.	

# Get the branches of the GitLab CI resositories, and their latest commit.
# TODO: switch server name
branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$desired_repository/repository/branches")
#echo "branches=$branches"

# Get two parallel arrays of branches and their latest commits
readarray -t branch_names_arr <  <(echo "$branches" | jq ".[].name")
readarray -t branch_commits_arr <  <(echo "$branches" | jq ".[].commit.id")
#echo "branch_names_arr=${branch_names_arr[@]}"
#echo "branch_commits_arr=${branch_commits_arr[@]}"

# Loop through branches using a mutual index i.
for i in "${!branch_names_arr[@]}"; do
	
	# Only export the desired branch build status
	if [  "${branch_names_arr[i]}" == '"'"$desired_branch"'"' ]; then
		# Get the GitLab build statusses and export them to the GitHub build status website.
		get_and_export_build_status_to_github_build_status_website_repo "$desired_repository" "${branch_names_arr[i]}" "${branch_commits_arr[i]}"
	fi
done

## Export the GitLab build statusses in the GitHub build statusses website repository to GitHub
# Push GitHub build statusses website repository to GitHub.
# Commit files to GitLab branch.
commit_changes "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE"

# Push committed files go GitLab.
#push_changes "$GITHUB_STATUS_WEBSITE" "$GITHUB_USERNAME" "$personal_access_token" "github.com" "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE/"
push_to_github_repository "$GITHUB_USERNAME" "$has_access" "$MIRROR_LOCATION/$GITHUB_STATUS_WEBSITE/"
echo "PUSHED"
echo ""
echo ""
echo ""