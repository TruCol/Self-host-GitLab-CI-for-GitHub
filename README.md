# Self-hosted GitLab CI for all your GitHub repos

Hi, thanks for checking out this repo! :) It runs your own self-hosted GitLab CI on all GitHub repositories of a GitHub user/organisation, in a single command. Tested on Ubuntu 20.04.1 LTS. This CI deployment partially CI's its own CI deployment.
![image](https://user-images.githubusercontent.com/34750068/188695430-f8fc4c8e-cf66-48ff-b9cb-7934cfdfeee5.png)

You can use this to easily host your own GitLab server, or to run your own GitLab CI on all your GitHub repositories, for free.

## How
The GitLab server runs on your device, so you don't have to pay anyone, the build statusses of the GitHub commits are pushed from GitLab to GitHub automatically.

 - The build status badges and results are stored in a (new) GitHub repository named: [gitlab-ci-build-statuses](https://github.com/a-t-0/gitlab-ci-build-statuses). That allows you to display your GitLab CI badge on all your GitHub repo's by referring to the build status icon stored (and updated) in that repo.
This is done by adding a GitHub SSH deploy key to your GitHub account, which is used to push GitLab build statusses from your device into your new GitHub repository.
- The GitHub commit statusses are also automatically set/updated when you run the GitLab CI. A GitHub personal access token is added to your GitHub for this purpose.

Both setting the GitHub SSH deploy key and personal access token are automated, using the Selenium browser controller, which is automatically downloaded by [this repo](https://github.com/a-t-0/get-gitlab-runner-registration-token), which is automatically downloaded as well. That repo creates a conda environment that is automatically created and activated to set the respective GitHub tokens. Anaconda is not automatically installed.

The browsercontroller is a lot of boilerplate code, so you can also just manually add the SSH deploy token to GitHub. Similarly, for the GitHub personal access token, you can manually store it in the: `personal_creds.txt` file above the repo root folder, with:
```
GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL=yourpersonalgithubaccesstoken
```
and then the code should automatically detect that you already have the prequisite access to GitHub, and automatically skip the whole boiler-plate browser controller stuf.

## Setup GitLab server + GitLab runner CI
To install your own GitLab server and GitLab runner:
```
git clone https://github.com/TruCol/Self-host-GitLab-CI-for-GitHub.git
cd Self-host-GitLab-CI-for-GitHub
chmod +x *.sh
./install_gitlab.sh -s -r -hu <your GitHub account> -le somegitlab@email.com -lp -hp
```
(You can leave out `-hp` if you're not comfortable typing your GitHub pw in code, then you'll be manually prompted to login via the browser.)


## Run your GitLab CI on GitHub
You can perform various types of CI runs. To run the CI commands, you should first have set up the GitLab server using the above command. These are described below:

### CI latest commit of each branch of each repo of a GitHub user
(Yes any GitHub user, doesn't have to be your GitHub user account.)
```
bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_all_repositories_of_user <some GitHub account/organisation>"
```
### CI latest commit of a particular GitHub repository
```
bash -c "source src/import.sh helper_github_modify.sh && get_build_status_repository_from_github"
bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && run_ci_on_github_repo hiveminds renamed_test_repo"
```

### CI a particular commit using GraphQL
```
bash -c "source src/import.sh && get_github_personal_access_token <your GitHub username> <your GitHub password>"
```
e.g. for me it could be:
```
bash -c "source src/import.sh && get_github_personal_access_token a-t-0 'examplepassword'"
```

Then run GitLab CI on custom GitHub repository (temporary instructions)
In file: `src/CI/call_CI/run_ci_from_graphql.sh`, change the line:
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
./test/libs/bats/bin/bats test/helper/GitLab/test_helper_gitlab_modify.bats
```

## Removing invalid build statusses
```
bash -c 'source src/import.sh && remove_commits_without_build_status_from_evaluated_list "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME"'

bash -c 'source src/import.sh && remove_commits_without_build_status_from_evaluated_list "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_WITH_CI_LIST_FILENAME"'

cd src/mirrors/GitHub/gitlab-ci-build-statuses/
git add *
git commit -m "Removed old build statusses."
git push
cd ../../../..
```