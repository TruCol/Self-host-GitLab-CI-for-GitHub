#!/bin/bash
source src/hardcoded_variables.txt
#source src/creds.txt
source ../personal_creds.txt

source src/helper_dir_edit.sh
source src/helper_github_modify.sh
source src/helper_github_status.sh
source src/helper_gitlab_modify.sh
source src/helper_gitlab_status.sh
source src/helper_git_neutral.sh
source src/helper_ssh.sh

source src/get_gitlab_server_runner_token.sh
#source src/push_repo_to_gitlab.sh
source src/run_ci_on_github_repo.sh


source src/helper.sh
source src/sha256_computing.sh


# Load assert abilities into code:
source src/helper_asserts.sh