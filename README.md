# Self-hosted GitLab CI for all your GitHub repos

Hi, thanks for checking out this repo! :) It runs your own self-hosted GitLab CI on all GitHub repositories of a GitHub user/organisation, in a single command. Tested on Ubuntu 20.04 LTS. 


## Setup GitLab server + GitLab runner CI
To install your own GitLab server:
```
git clone https://github.com/TruCol/Self-host-GitLab-CI-for-GitHub.git
cd Self-host-GitLab-CI-for-GitHub
chmod +x *.sh
./install_gitlab.sh -s -r -hu <your GitHub account> -le somegitlab@email.com -lp -hp
```
(You can leave out `-hp` if you're not comfortable typing your GitHub pw in code, then you'll be manually prompted to login via the browser.)


## Run your GitLab CI on all repositories of an arbitrary GitHub User:
```
bash -c "source src/import.sh src/run_ci_on_github_repo.sh && run_ci_on_all_repositories_of_user <some GitHub account/organisation>"
```
## Run your GitLab CI on a particular repository
```
bash -c "source src/import.sh helper_github_modify.sh && get_build_status_repository_from_github"
bash -c "source src/import.sh src/run_ci_on_github_repo.sh && run_ci_on_github_repo hiveminds renamed_test_repo hiveminds"
```

## Run your GitLab CI on a particular commit using GraphQL
First, ensure GitHub Personal Access Token is valid. After installation of the GitLab CI, (and re-using it after a month+), first get your GitHub personal access token:
```
bash -c "source src/import.sh && get_github_personal_access_token <your GitHub username> <your GitHub password>"
```
e.g. for me it could be:
```
bash -c "source src/import.sh && get_github_personal_access_token a-t-0 'examplepassword'"
```

Then run GitLab CI on custom GitHub repository (temporary instructions)
In file: `src/run_ci_from_graphql.sh`, change the line:
```
local github_organisation="trucol"
```
to:
```
local github_organisation="<the GitHub username/organisation on which you want to run a CI job>"
```
Also change the line:
```
if [ "$repo_name" == "checkstyle-for-bash" ]; then
```
to:
```
if [ "$repo_name" == "<the repository you want to run your ci on>" ]; then
```
Also change the line:
```
if [ "$repo_name_without_quotations" == "checkstyle-for-bash" ]; then
```
to:
```
if [ "$repo_name_without_quotations" == "<the repository you want to run your ci on>" ]; then
```

in `src/examplequery14.gql` change the line:
```
repositoryOwner(login: "trucol") {
```
to:
```
repositoryOwner(login: "<the GitHub username/organisation on which you want to run a CI job>") {
```
Then run the GitLab CI:
```
bash -c "source src/import.sh && get_query_results"
```


## Uninstall and delete all the data of your local GitLab server:
```
./uninstall_gitlab.sh -y -h -r
```

## Testing
After GitLab, and its runner CI is installed and running, you can run the tests with: 
```
rm -r test/libs/*
chmod +x *.sh
./install-bats-libs.sh
./test.sh
```
Alternatively to running all tests with `./test.sh`, you can run a single testfile with:
```
./test/libs/bats/bin/bats test/test_helper_gitlab_modify.bats
```
