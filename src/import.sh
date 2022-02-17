# No shebang because that breaks the tests.
source src/hardcoded_variables.txt
source src/helper_file_dir_related.sh

# Raise sudo permission at the start, to prevent requiring user permission half way through tests.
{
  sudo echo "hi"
} &> /dev/null

# Install prerequisites
if [ $(jq --version) != "jq-1.6" ]; then
	yes | sudo apt install jq
fi

if [ "$(file_exists "../personal_creds.txt")" == "FOUND" ]; then
	source ../personal_creds.txt
elif [ "$(file_exists "src/creds.txt")" == "FOUND" ]; then
	source src/creds.txt
	echo "Note you are using the default credentials, would you like to create your own personal credentials file (outside this repo) y/n?"
else
	echo "No credentials found."
	exit 7
fi




filler="Filler"
# TODO: differentiate between GLOBAL and HARDCODED with:
#GITLAB_SERVER_ACCOUNT_GLOBAL=$(echo "$GITLAB_SERVER_ACCOUNT_HARDCODED" | tr -d '\r')
GITLAB_SERVER_ACCOUNT_GLOBAL=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
GITLAB_SERVER_PASSWORD_GLOBAL=$(echo "$GITLAB_SERVER_PASSWORD_GLOBAL" | tr -d '\r')
GITLAB_ROOT_EMAIL_GLOBAL=$(echo "$GITLAB_ROOT_EMAIL_GLOBAL" | tr -d '\r')
GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL=$(echo "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
GITLAB_WEBSITE_URL_GLOBAL=$(echo "$GITLAB_WEBSITE_URL_GLOBAL" | tr -d '\r')
GITLAB_SERVER_PASSWORD_GLOBAL=$(echo "$GITLAB_SERVER_PASSWORD_GLOBAL" | tr -d '\r')
GITLAB_SERVER_PASSWORD_GLOBAL=$(echo "$GITLAB_SERVER_PASSWORD_GLOBAL" | tr -d '\r')
#echo "$GITLAB_SERVER_ACCOUNT_GLOBAL$filler"
#echo "$GITLAB_SERVER_PASSWORD_GLOBAL$filler"
#echo "$GITLAB_ROOT_EMAIL_GLOBAL$filler"
#echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL$filler"
#echo "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL$filler"
#echo "$GITLAB_WEBSITE_URL_GLOBAL$filler"
#echo "$GITLAB_SERVER_PASSWORD_GLOBAL$filler"
#read -p "Done"


# For installation
source src/helper_ci_management.sh
source src/create_github_personal_access_token.sh
source src/helper_dir_edit.sh
source src/helper_github_modify.sh
source src/helper_github_status.sh
source src/helper_gitlab_modify.sh
source src/helper_gitlab_status.sh
source src/helper_git_neutral.sh
source src/helper_ssh.sh
source src/helper.sh
source src/helper_docker.sh
source src/helper_parsing.sh
source src/helper_configuration.sh

source src/install_support_programs.sh
source src/helper_md5sum.sh

# To get GitLab personal access token
source src/create_personal_access_token.sh

# For uninstallation
source src/uninstall_gitlab_server.sh
source src/uninstall_gitlab_runner.sh

# For tests
# TODO: salvage the used functions of this file and move it into src.
source src/boot_tor.sh
source src/helper_dir_edit.sh
source src/install_and_boot_gitlab_server.sh


# Unsorted imports.
source src/get_gitlab_server_runner_token.sh
source src/run_ci_on_github_repo.sh



source src/sha256_computing.sh


# Load assert abilities into code:
source src/helper_asserts.sh

# Load test files
source test/hardcoded_testdata.txt
source test/helper.sh
