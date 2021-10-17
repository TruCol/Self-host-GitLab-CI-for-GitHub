#!/bin/bash 
# get a list of the repositories
# per repository get a list of branches
# per branch get a list of commits
# per commit check if it contains a gitlab yml file
# if it does, check if you can find its log file.


source src/hardcoded_variables.txt
source src/creds.txt
source src/helper.sh
yes | sudo apt install jq

# load personal_access_token, gitlab username, repository name
personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
repo_name=$SOURCE_FOLDERNAME

echo "personal_access_token=$personal_access_token"
echo "repo_name=$repo_name"
echo "gitlab_username=$gitlab_username"

## get a list of the repositories
#curl --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v3/projects/?simple=yes&private=true&per_page=1000&page=1"
##repositories=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects")
repositories=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
readarray -t repo_arr <  <(echo "$repositories" | jq ".[].name")


get_build_status_through_pipelines() {
	branch_name=$1
	branch_commit=$(echo "$2" | tr -d '"') # removes double quotes at start and end.
	
	# curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines"
	pipelines=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/pipelines")
	
	# get build status from pipelines
	job=$(echo $pipelines | jq -r 'map(select(.id == 46))')
	branch=$(echo $job | jq ".[].ref")
	status=$(echo $job | jq ".[].status")
	read -p "job=$job"
	read -p "branch=$branch"
	read -p "status=$status"
	
	# Create repository folder if it does not exist yet
	# Create branch folder in repository if it does not exist yet
	# Create build status icon
	
}

## per repository get a list of branches
for repo in "${repo_arr[@]}"; do
	 simplified_repo=$(echo "$repo" | tr -d '"')
	#branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/repository/branches")
	#branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo/repository/branches")
	branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$simplified_repo/repository/branches")
	#echo "branches=$branches"
	
	# Get pairs of branches and leading commits
	readarray -t branch_names_arr <  <(echo "$branches" | jq ".[].name")
	readarray -t branch_commits_arr <  <(echo "$branches" | jq ".[].commit.id")
	echo "branch_names_arr=${branch_names_arr[@]}"
	echo "branch_commits_arr=${branch_commits_arr[@]}"
	
	# loop through branches
	for i in "${!branch_names_arr[@]}"; do
	
		# get latest commit of the branch.
		echo "branchname=${branch_names_arr[i]}, commit=${branch_commits_arr[i]}"

		# get the data from the pipeline
		get_build_status_through_pipelines "${branch_names_arr[i]}" "${branch_commits_arr[i]}"
	done
done



## per branch get a list of commits
# Source:https://docs.gitlab.com/ee/api/commits.html
# curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/commits"
commits=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/repository/commits")
nr_of_commits=$(echo "$commits" | jq 'length')
list_of_commits=$(echo "$commits" | jq '.[].id')
#echo "list_of_commits=$list_of_commits"
#echo "nr_of_commits=$nr_of_commits"

## per commit check the build status
# Option I: check if it contains a gitlab yml file if it does, check if you can find its log file.
# OPTION II: check pipelines for that repo and see if it has one for that commit.