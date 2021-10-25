# Description to set up a GitLab server, Website and SSH over tor (for a Raspberry Pi 4b)

This repository first sets up wifi on a Raspberry Pi 4b (with 4gb ram) and then it starts the following services:
 - A GitLab server
 - A GitLab runner
 - A website
 - An SSH connection
 all accessible over tor. These services are started using a cronjob.


## Setup GitLab server + GitLab runner CI
```
chmod +x *.sh
./install_gitlab.sh -s -r
```
After GitLab, and its runner CI is installed, create a personal access token and test if the runner CI works with: 
```
rm -r test/libs/*
chmod +x install-bats-libs.sh
./install-bats-libs.sh
./test/libs/bats/bin/bats test/modular_test_runner.bats
```


## Run GitLab runner CI on GitHub repositories
This script mirrors the source code of all the branches of a GitHub repository to GitLab, and then runs the GitLab runner CI on each of those branches (if a `.gitlab-ci.yml` file exists).
```
src/./mirror_github_to_gitlab.sh "hiveminds" "tw-install" "filler_github" "root" "filler_gitlab"
```
Next, the following script (needs to be adapted to ensure it) pushes the GitLab runner CI build statusses as a badge to a GitHub repository that is a GitHub pages website:
```
src/./server_side.sh
```
The Readme's of the respective branches can be adjusted to display the build status badge from the GitHub pages website.

 
 ## First-time usage Raspberry Pi 4B
 Copy the `first_time_rpi_4b.sh` script to the Raspberry Pi 4B via a USB stick with code:
```
TODO
```
TODO: automatically download this GitHub and automatically set up the cronjob to establish the Tor connection upon boot.
TODO: Scan for private input data to claim accompanying domains.
TODO: Ensure that the SSH access is set up automatically towards the parent pc.


## Establish Tor connection upon boot:
Create a cronjob that runs the file:
`torssh.sh`


## Setup Website
TODO: Run script that sets up website server once the tor connection is enabled.
TODO: Create script that detects once the Website has been established, continuously monitor and reboot upon failure.


## Setup SSH service upon boot
TODO: Create script that adds a cronjob for this task.
TODO: Create script that verifies the SSH is available.

## How to use (for developers)
First install the required submodules with:
```
cd ~/.task
git clone git@github.com:HiveMinds-EU/tw-install.git install
cd install
rm -r test/libs/*
chmod +x install-bats-libs.sh
./install-bats-libs.sh
```

Next, run the unit tests with:
```
chmod +x test.sh
./test.sh
```
Note: Put your unit test files (with extention .bats) in folder: `/test/`
