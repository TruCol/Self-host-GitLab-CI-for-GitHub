# No shebang because that breaks the tests.
source src/hardcoded_variables.txt
source src/helper/helper_file_dir_related.sh


# TODO: replace with hardcoded PERSONAL_CREDENTIALS_PATH.
if [ "$(file_exists "../personal_creds.txt")" == "FOUND" ]; then
	source ../personal_creds.txt
elif [ "$(file_exists "src/creds.txt")" == "FOUND" ]; then
	source src/creds.txt
	echo "Note you are using the default credentials, would you like to create your own personal credentials file (outside this repo) y/n?"
else
	echo "No credentials found."
	exit 7
fi

# Remove the trailing edge characters from the global variables read from
# hardcoded_variables.txt and personal_creds.txt
GITLAB_SERVER_ACCOUNT_GLOBAL=$(echo "$GITLAB_SERVER_ACCOUNT_GLOBAL" | tr -d '\r')
GITLAB_SERVER_PASSWORD_GLOBAL=$(echo "$GITLAB_SERVER_PASSWORD_GLOBAL" | tr -d '\r')
GITLAB_ROOT_EMAIL_GLOBAL=$(echo "$GITLAB_ROOT_EMAIL_GLOBAL" | tr -d '\r')
GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL=$(echo "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')
GITLAB_SERVER_HTTP_URL=$(echo "$GITLAB_SERVER_HTTP_URL" | tr -d '\r')
GITLAB_SERVER_PASSWORD_GLOBAL=$(echo "$GITLAB_SERVER_PASSWORD_GLOBAL" | tr -d '\r')
GITLAB_SERVER_PASSWORD_GLOBAL=$(echo "$GITLAB_SERVER_PASSWORD_GLOBAL" | tr -d '\r')

# TODO: determine how the "filler" can be deleted.
filler="Filler"
#echo "$GITLAB_SERVER_ACCOUNT_GLOBAL$filler"
#echo "$GITLAB_SERVER_PASSWORD_GLOBAL$filler"
#echo "$GITLAB_ROOT_EMAIL_GLOBAL$filler"
#echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL$filler"
#echo "$GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL$filler"
#echo "$GITLAB_SERVER_HTTP_URL$filler"
#echo "$GITLAB_SERVER_PASSWORD_GLOBAL$filler"
#read -p "Done"


# For installation
source src/CI/helper_ci_management.sh
source src/CI/GitLab_runner/install_and_boot_gitlab_runner.sh
source src/CI/call_CI/verify_build_statusses_are_valid.sh

source src/helper/GitHub/helper_github_modify.sh
source src/helper/GitHub/helper_github_status.sh
source src/helper/GitHub/verify_GitHub_server.sh
source src/helper/GitLab/helper_gitlab_modify.sh
source src/helper/GitLab/helper_gitlab_status.sh
source src/helper/git_neutral/helper_git_neutral.sh
source src/helper/helper.sh

source src/helper/verification/helper_asserts.sh # Loads assert abilities into code
source src/helper/helper_configuration.sh
source src/helper/helper_dir_edit.sh
source src/helper/helper_docker.sh
source src/helper/helper_parsing.sh
source src/helper/verification/helper_md5sum.sh
source src/helper/verification/sha256_computing.sh

source src/prerequisites/firefox_version.sh
source src/prerequisites/jquery.sh
source src/prerequisites/prerequisites.sh
source src/prerequisites/install_support_programs.sh
source src/prerequisites/manage_prerequisites.sh

# To get GitLab personal access token
source src/Selenium/PAT/create_gitlab_personal_access_token.sh # TODO: verify its naming.
source src/Selenium/PAT/ensure_github_personal_access_token_is_created.sh
source src/Selenium/PAT/check_github_pat_usability.sh
source src/Selenium/get_gitlab_server_runner_token.sh
source src/Selenium/SSH/check_GitHub_ssh_access.sh
source src/Selenium/SSH/ensure_GitHub_ssh_access.sh
source src/Selenium/SSH/local_ssh_checks.sh
source src/Selenium/SSH/set_GitHub_ssh_key.sh

# For uninstallation
source src//GitLab_server/uninstall_gitlab_server.sh
source src/CI/GitLab_runner/uninstall_gitlab_runner.sh

# For CI usage
source src/CI/call_CI/run_ci_on_github_repo.sh
source src/CI/call_CI/run_ci_on_commit.sh
source src/CI/call_CI/run_ci_from_graphql.sh

# A dashboard/list of arguments to allow user to modify GitLab on the fly.
source src/Dashboard/call_run_function_with_timeout.sh

# For tests
# TODO: salvage the used functions of boot_tor and move it into src.
source src/Tor_support/boot_tor.sh
source src/helper/helper_dir_edit.sh
source src/GitLab_server/install_and_boot_gitlab_server.sh

# Load test files
source test/hardcoded_testdata.txt
source test/helper/helper.sh
