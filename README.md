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

To uninstall and delete all the data of your local GitLab:
```
./uninstall_gitlab.sh -y -h -r
```

## Run your GitLab CI on all repositories of an arbitrary GitHub User:
```
bash -c "source src/import.sh src/run_ci_on_github_repo.sh && run_ci_on_all_repositories_of_user <some GitHub account/organisation>"
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
