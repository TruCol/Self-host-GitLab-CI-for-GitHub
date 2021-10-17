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
yes | sudo apt install xclip

# load personal_access_token, gitlab username, repository name
personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
repo_name=$SOURCE_FOLDERNAME

echo "personal_access_token=$personal_access_token"
echo "repo_name=$repo_name"
echo "gitlab_username=$gitlab_username"




# get the website repository
git clone git@github.com:"$GITHUB_USERNAME"/"$GITHUB_STATUS_WEBSITE"



## get a list of the repositories
#curl --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v3/projects/?simple=yes&private=true&per_page=1000&page=1"
##repositories=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects")
repositories=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
readarray -t repo_arr <  <(echo "$repositories" | jq ".[].path")
#echo "repositories=$repositories"
echo "repo_arr =${repo_arr[@]}"

# export the build statusses to the build status website.
get_build_status_through_pipelines() {
	repository_name="$1"
	branch_name=$(echo "$2" | tr -d '"') # removes double quotes at start and end.
	branch_commit=$(echo "$3" | tr -d '"') # removes double quotes at start and end.
	
	
	# curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines"
	pipelines=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repository_name/pipelines")
	
	# get build status from pipelines
	echo "branch_name=$branch_name"
	echo "branch_commit=$branch_commit"
	echo "pipelines=$pipelines"
	#job=$(echo $pipelines | jq -r 'map(select(.id == 46))')#works
	#job=$(echo $pipelines | jq -r 'map(select(.commit.id == 00c16a620847faae3a6b7b1dcc5d4d458f2c7986))')# works
	#job=$(echo $pipelines | jq -r 'map(select(.commit.id == "00c16a620847faae3a6b7b1dcc5d4d458f2c7986"))')
	#job=$(echo $pipelines | jq -r "map(select(.commit.id == "00c16a620847faae3a6b7b1dcc5d4d458f2c7986"))")
	#job=$(echo $pipelines | jq -r 'map(select(.commit.id == '"00c16a620847faae3a6b7b1dcc5d4d458f2c7986"'))')
	#job=$(echo $pipelines | jq -r 'map(select(.commit.id == "'"00c16a620847faae3a6b7b1dcc5d4d458f2c7986"'"))')# works
	#job=$(echo $pipelines | jq -r 'map(select(.commit.id == "'"$branch_commit"'"))')
	job=$(echo $pipelines | jq -r 'map(select(.sha == "'"$branch_commit"'"))')
	echo "job=$job"
	#branch=$(echo $job | jq ".[].ref")
	#branch=$(echo "$(echo $job | jq ".[].ref")" | tr -d '"')
	#status=$(echo $job | jq ".[].status")
	status=$(echo "$(echo $job | jq ".[].status")" | tr -d '"')
	
	# print data
	read -p "repository_name=$repository_name"
	read -p "job=$job"
	read -p "branch=$branch"
	read -p "status=$status"
	
	# Create repository folder if it does not exist yet
	# Create branch folder in repository if it does not exist yet
	mkdir -p "$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch"
	
	# Create build status icon
	if [  "$status" == "passed" ]; then
		cp "src/svgs/passed.svg" "$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch""/build_status.svg"
	elif [  "$status" == "failed" ]; then
		cp "src/svgs/failed.svg" "$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch""/build_status.svg"
	elif [  "$status" == "error" ]; then
		cp "src/svgs/error.svg" "$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch""/build_status.svg"
	elif [  "$status" == "unknown" ]; then
		cp "src/svgs/unknown.svg" "$GITHUB_STATUS_WEBSITE"/"$repository_name"/"$branch""/build_status.svg"
	fi
}

## per repository get a list of branches
for repo in "${repo_arr[@]}"; do
	simplified_repo=$(echo "$repo" | tr -d '"')
	echo "simplified_repo=$simplified_repo"
	#branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/repository/branches")
	#branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo/repository/branches")
	branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$simplified_repo/repository/branches")
	echo "branches=$branches"
	
	# Get pairs of branches and leading commits
	readarray -t branch_names_arr <  <(echo "$branches" | jq ".[].name")
	readarray -t branch_commits_arr <  <(echo "$branches" | jq ".[].commit.id")
	#echo "branch_names_arr=${branch_names_arr[@]}"
	#echo "branch_commits_arr=${branch_commits_arr[@]}"
	
	# loop through branches
	for i in "${!branch_names_arr[@]}"; do
	
		# get latest commit of the branch.
		#echo "branchname=${branch_names_arr[i]}, commit=${branch_commits_arr[i]}"

		# get the data from the pipeline
		get_build_status_through_pipelines "$simplified_repo" "${branch_names_arr[i]}" "${branch_commits_arr[i]}"
	done
done


# Generate ssh deployment keys.
n | ssh-keygen -b 2048 -t rsa -f ~/.ssh/deploy_key -q -N ""
# Activate ssh deploy keys

# put ssh-key in deploy website
xclip -sel clip < ~/.ssh/deploy_key.pub
read -p "Add the key to github if you havent yet (It's copied, just ctrl+V in: https://github.com/""$GITHUB_USERNAME"/"$GITHUB_STATUS_WEBSITE""/settings/keys/new"

# Push repo with deploy key
cd "$GITHUB_STATUS_WEBSITE" && git status
git add *
git commit -m "Updated build status."
git push


# Add repository mirrors:
# Source: https://docs.gitlab.com/ee/api/remote_mirrors.html
curl --request POST --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/1/export" \
    --data "upload[http_method]=PUT" \
    --data-urlencode "upload[url]=http://github.com/a-t-0/sponsor_example.git"
	#--data-urlencode "upload[url]=https://github.com/a-t-0/sponsor_example.git"
	
#curl --request PUT --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/1/export" \
#    --data "upload[http_method]=PUT" \
#    --data-urlencode "upload[url]=http://github.com/a-t-0/sponsor_example.git"
	

# Source: https://forum.gitlab.com/t/problems-with-triggering-pull-mirroring-proces-from-api/25867/2
#curl -X PUT \
#--url https://gitlab.com/api/v4/projects/<migrated-gitlab-repo-ID> \
#--header 'Content-Type: application/json' \
#--header 'Authorization: <gitlab-token>' \
#--data '{"mirror": true, "import_url":"https://<gitlhub-user>:<github-token>@github.com/<org-name-id>/<repo- name>.git"}'


## per branch get a list of commits
# Source:https://docs.gitlab.com/ee/api/commits.html
# curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/commits"
# commits=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/repository/commits")
# nr_of_commits=$(echo "$commits" | jq 'length')
# list_of_commits=$(echo "$commits" | jq '.[].id')
# echo "list_of_commits=$list_of_commits"
# echo "nr_of_commits=$nr_of_commits"

## per commit check the build status
# Option I: check if it contains a gitlab yml file if it does, check if you can find its log file.
# OPTION II: check pipelines for that repo and see if it has one for that commit.