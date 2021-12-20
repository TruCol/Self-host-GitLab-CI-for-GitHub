#!/bin/bash 
# get a list of the repositories
# per repository get a list of branches
# per branch get a list of commits
# per commit check if it contains a gitlab yml file
# if it does, check if you can find its log file.


source src/hardcoded_variables.txt
#source src/creds.txt
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

# Download the build-status-website repository.
git clone git@github.com:"$GITHUB_USERNAME"/"$GITHUB_STATUS_WEBSITE"

# Get a list of the repositories in your own local GitLab server (that runs the GitLab runner CI).
repositories=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/?simple=yes&private=true&per_page=1000&page=1")
readarray -t repo_arr <  <(echo "$repositories" | jq ".[].path")
echo "repo_arr =${repo_arr[@]}"

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
	
	# print data
	echo "branch_name=$branch_name"
	echo "branch_commit=$branch_commit"
	echo "pipelines=$pipelines"
	echo "job=$job"
	#read -p "repository_name=$repository_name"
	#read -p "job=$job"
	#read -p "branch=$branch"
	#read -p "status=$status"
	
	# Create a folder of the repository on which a CI has been ran, inside the GitHub build status website repository, if it does not exist yet
	# Also add a folder for the branch(es) of that GitLab CI repository, in that respective folder.
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

# Export the GitLab build status of each *TODO: relevant* GitLab runner CI repository
# to the GItHub build status website repository.
for repo in "${repo_arr[@]}"; do
	# Remove the double quotes from the repository.
	simplified_repo=$(echo "$repo" | tr -d '"')
	#echo "simplified_repo=$simplified_repo"
	
	# Get the branches of the GitLab CI resositories, and their latest commit.
	branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$simplified_repo/repository/branches")
	#echo "branches=$branches"
	
	# Get two parallel arrays of branches and their latest commits
	readarray -t branch_names_arr <  <(echo "$branches" | jq ".[].name")
	readarray -t branch_commits_arr <  <(echo "$branches" | jq ".[].commit.id")
	#echo "branch_names_arr=${branch_names_arr[@]}"
	#echo "branch_commits_arr=${branch_commits_arr[@]}"
	
	# Loop through branches using a mutual index i.
	for i in "${!branch_names_arr[@]}"; do
	
		# Get the GitLab build statusses and export them to the GitHub build status website.
		get_and_export_build_status_to_github_build_status_website_repo "$simplified_repo" "${branch_names_arr[i]}" "${branch_commits_arr[i]}"
	done
done


## Export the GitLab build statusses in the GitHub build statusses website repository to GitHub

# Generate ssh deployment keys. (The n prevents overwriting an existing ssh-key with a new one)
n | ssh-keygen -b 2048 -t rsa -f ~/.ssh/deploy_key -q -N ""


# put ssh-key in GitHub build statusses website repository
# TODO: automate, instead of manual
xclip -sel clip < ~/.ssh/deploy_key.pub
read -p "Add the key to github if you havent yet (It's copied, just ctrl+V in: https://github.com/""$GITHUB_USERNAME"/"$GITHUB_STATUS_WEBSITE""/settings/keys/new"
read -p "Now go to: https://github.com/settings/tokens/ and create a GitHub Token with repo read authorities."
read -p "Now go to: http://127.0.0.1/import/github/status and click import 90 repositories!"

# TODO: verify the deploy key works before proceeding.

# Push GitHub build statusses website repository to GitHub.
cd "$GITHUB_STATUS_WEBSITE" && git status
git add *
git commit -m "Updated build status."
git push


## TODO: move to separate shell script that mirrors the GitHub repositories.
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

# Source: https://stackoverflow.com/questions/69601327/import-git-repository-into-gitlab-using-api/69602373#69602373
# Source: https://stackoverflow.com/questions/13902593/how-does-one-find-out-ones-own-repo-id/47223479
echo "retry"
curl --request POST \
  --url "http://127.0.0.1/api/v4/import/github" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: $personal_access_token" \
  --data '{
    "personal_access_token": "$GITHUB_PERSONAL_ACCESS_TOKEN",
    "repo_id": "385243548",
    "target_namespace": "root",
    "new_name": "tw-install",
    "github_hostname": "https://www.github.com"
}'
echo "retried,personal_access_token=$personal_access_token"
#curl --request POST \
#  --url "http://127.0.0.1/api/v4/import/github" \
#  --header "content-type: application/json" \
#  --header "PRIVATE-TOKEN: $personal_access_token" \
#  --data '{ "path":"https://github.com/HiveMinds/tw-install", "name": "newrepo" }'
#echo "RETRIED"

## per branch get a list of commits
# Source:https://docs.gitlab.com/ee/api/commits.html
# curl --header "PRIVATE-TOKEN: <your_access_token>" "http://127.0.0.1/api/v4/projects/5/repository/commits"
# commits=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/repository/commits")
# nr_of_commits=$(echo "$commits" | jq 'length')
# list_of_commits=$(echo "$commits" | jq '.[].id')
# echo "list_of_commits=$list_of_commits"
# echo "nr_of_commits=$nr_of_commits"

## per commit check the build status
# Option I: check if it contains a gitlab yml file if it does, check if you can find its log file.
# OPTION II: check pipelines for that repo and see if it has one for that commit.