#!/bin/bash
source src/hardcoded_variables.txt
#source src/creds.txt
source ../personal_creds.txt
filler="Filler"
GITLAB_SERVER_ACCOUNT=$(echo "$GITLAB_SERVER_ACCOUNT" | tr -d '\r')
GITLAB_SERVER_PASSWORD=$(echo "$GITLAB_SERVER_PASSWORD" | tr -d '\r')
GITLAB_ROOT_EMAIL=$(echo "$GITLAB_ROOT_EMAIL" | tr -d '\r')
GITLAB_PERSONAL_ACCESS_TOKEN=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN" | tr -d '\r')
GITHUB_PERSONAL_ACCESS_TOKEN=$(echo "$GITHUB_PERSONAL_ACCESS_TOKEN" | tr -d '\r')
GITLAB_WEBSITE_URL=$(echo "$GITLAB_WEBSITE_URL" | tr -d '\r')
GITLAB_SERVER_PASSWORD=$(echo "$GITLAB_SERVER_PASSWORD" | tr -d '\r')
GITLAB_SERVER_PASSWORD=$(echo "$GITLAB_SERVER_PASSWORD" | tr -d '\r')
echo "$GITLAB_SERVER_ACCOUNT$filler"
echo "$GITLAB_SERVER_PASSWORD$filler"
echo "$GITLAB_ROOT_EMAIL$filler"
echo "$GITLAB_PERSONAL_ACCESS_TOKEN$filler"
echo "$GITHUB_PERSONAL_ACCESS_TOKEN$filler"
echo "$GITLAB_WEBSITE_URL$filler"
echo "$GITLAB_SERVER_PASSWORD$filler"
read -p "Done"

source src/helper_ci_management.sh
source src/helper_dir_edit.sh
source src/helper_github_modify.sh
source src/helper_github_status.sh
source src/helper_gitlab_modify.sh
source src/helper_gitlab_status.sh
source src/helper_git_neutral.sh
source src/helper_ssh.sh

source src/get_gitlab_server_runner_token.sh
source src/run_ci_on_github_repo.sh


source src/helper.sh
source src/sha256_computing.sh


# Load assert abilities into code:
source src/helper_asserts.sh