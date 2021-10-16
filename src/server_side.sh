#!/bin/bash 
# get a list of the repositories
# per repository get a list of branches
# per branch get a list of commits
# per commit check if it contains a gitlab yml file
# if it does, check if you can find its log file.


source src/hardcoded_variables.txt
source src/creds.txt
# load personal_access_token, gitlab username, repository name
personal_access_token=$(echo $GITLAB_PERSONAL_ACCESS_TOKEN | tr -d '\r')
gitlab_username=$(echo $gitlab_server_account | tr -d '\r')
repo_name=$SOURCE_FOLDERNAME

echo "personal_access_token=$personal_access_token"
echo "repo_name=$repo_name"
echo "gitlab_username=$gitlab_username"

## get a list of the repositories
## per repository get a list of branches
branches=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/repository/branches")
echo "branches=$branches"

## per branch get a list of commits
# Source:https://docs.gitlab.com/ee/api/commits.html
# curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/commits"
commits=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/repository/commits")
#echo "commits=$commits"

# curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines"
pipelines=$(curl --header "PRIVATE-TOKEN: $personal_access_token" "http://127.0.0.1/api/v4/projects/$gitlab_username%2F$repo_name/pipelines")
#echo "pipelines=$pipelines"





## per commit check the build status
# Option I: check if it contains a gitlab yml file if it does, check if you can find its log file.
# OPTION II: check pipelines for that repo and see if it has one for that commit.
