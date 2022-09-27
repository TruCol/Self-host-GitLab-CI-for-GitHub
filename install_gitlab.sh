#!/bin/bash
POSITIONAL_ARGS=()


source src/import.sh

# Specify default argument values.
commit_status_personal_access_token_flag='false'
commit_status_ssh_flag='false'
deploy_ssh_flag='false'
github_pwd_flag='false'
github_username_flag='false'
runner_flag='false'
server_flag='false'
setup_boot_script_flag='false'
setup_tor_website_for_gitlab_server_flag='false'
gitlab_username_flag='false'
gitlab_pwd_flag='false'
gitlab_email_flag='false'

# Specify variable defaults
gitlab_username="root"
gitlab_email="some@email.com"


print_usage() {
  printf "\nDefault usage, write:"
  printf "\n./install_gitlab.sh -s -r -hu <your GitHub username> -le somegitlab@email.com -lp -hp\n                                       to install GitLab CI and run it on your GitHub repositories."

  printf "\nSupported options:"
  # TODO: verify if the user can set the value of the GitHub personal access
  # token, or whether the value is given/set by GitHub automatically.
  # If it is given by GitHub automatically, change this into a boolean decision
  # that indicates whether or not the user will set the commit build statuses
  # on GitHub or not.
  
  printf "\n-r | --runner                          to do an installation of the GitLab runner."
  printf "\n-s | --server                          to do an installation of the GitLab server."
  

  printf "\n\n-hu <your GitHub username> | --github-username <your GitHub username>\n                                       to pass your GitHub username, to prevent having to wait untill you can                                          enter it in the website."
  printf "\n-hp | --github-password                to get a prompt for your GitHub password, so you don't have to wait to enter it manually."
  
  printf "\n\n-lu <your new GitLab username> | --gitlab-username <your GitLab username>\n                                       to set a custom GitLab username(default=root), and store it in your                                             ../personal_credentials.txt."
  printf "\n-lp | --gitlab-password                to pass your new GitLab password,pass your GitLab username, and store it                                        in your ../personal_credentials.txt."  
  printf "\n-le <your email for GitLab> | --gitlab-email <your email for GitLab>\n                                       to pass your the email address you use for GitLab, and store it in your                                         ../personal_credentials.txt."

  

  printf "\n\nNot yet supported:"
  printf "\n-hubcssh | --github-commit-status-ssh  to enable the code to set the build status of GitHub commits using an                                           ssh-key."
  printf "\n-b | --boot                            to set up a script/cronjob that runs the GitLab CI on your GitHub                                               repositories in the background after reboots."
  printf "\n-repo | --repo                         to run the GitLab CI on a particular GitHub repository."
  printf "\n-tw | --tor-website                    to set up tor website for your GitLab server."
  printf "\n-user | --user                         to run the GitLab CI on a particular GitHub user/organisation."
  
  printf "\n\nyou can also combine the separate arguments in different orders, e.g. -r -s -w.\n\n"
}

# print the usage if no arguments are given
[ $# -eq 0 ] && { print_usage; exit 1; }

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--server)
	    server_flag='true'
      shift # past argument
      ;;
    -r|--runner)
      runner_flag='true'
      shift # past argument
      ;;
    -ds|--deploy-ssh)
	    # Start by setting the ssh-deploy key to the GitHub build status 
	    # repository.
      deploy_ssh_flag='true'
      shift # past argument
      ;;
    -hubcssh|--github-commit-status-ssh)
      commit_status_ssh_flag='true'
      shift # past argument
      ;;
    -hubcpat|--github-commit-status-pat)
      commit_status_personal_access_token_flag='true'
      shift # past argument
      ;;
    -b|--boot)
      setup_boot_script_flag='true'
      shift # past argument
      ;;
    -tw|--tor_website)
      setup_tor_website_for_gitlab_server_flag='true'
      shift # past argument
      ;;
    -hu|--github-username)
      github_username_flag='true'
      github_username="$2"
      assert_is_non_empty_string ${github_username}
      shift # past argument
      shift
      ;;
    -hp|--github-password)
      github_pwd_flag='true'
      #github_pwd="$2" # Don't allow vissibly typing pwd in command line.
      shift # past argument
      ;;
    
    -lu|--gitlab-username)
      gitlab_username_flag='true'
      gitlab_username="$2"
      assert_is_non_empty_string ${gitlab_username}
      shift # past argument
      shift
      ;;
    -lp|--gitlab-password)
      gitlab_pwd_flag='true'
      #gitlab_pwd="$2" # Don't allow vissibly typing pwd in command line.
      shift # past argument
      ;;
    -lt |--gitlab-personal-access-token)
      gitlab_personal_access_token_flag='true'
      gitlab_personal_access_token="$2"
      # The token must be 20 characters long. 
      # Source: https://forge.etsi.org/rep/help/user/profile/personal_access_tokens.md
      # TODO: verify length.
      assert_is_non_empty_string ${gitlab_personal_access_token}
      assert_string_only_contains_alphanumeric_chars ${gitlab_personal_access_token}
      shift # past argument
      shift
      ;;
    -le|--gitlab-email)
      gitlab_email_flag='true'
      gitlab_email="$2"
      shift # past argument
      shift
      ;;
      #shift # past argument
      #shift
      #;;
    -*|--*)
      echo "Unknown option $1"
      print_usage
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

echo "server_flag                              = ${server_flag}"
echo "runner_flag                              = ${runner_flag}"
echo "deploy_ssh_flag                          = ${deploy_ssh_flag}"
echo "commit_status_ssh_flag                   = ${commit_status_ssh_flag}"
echo "commit_status_personal_access_token_flag = ${commit_status_personal_access_token_flag}"
echo "setup_boot_script_flag                   = ${setup_boot_script_flag}"
echo "set_up_tor_website_for_gitlab_server_flag= ${set_up_tor_website_for_gitlab_server_flag}"

if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
fi


# Set GitLab password without displaying it in terminal.
if [ "$gitlab_pwd_flag" == "true" ]; then
	echo -n "Your new GitLab password:"
	read -s gitlab_pwd
	echo
  assert_string_only_contains_alphanumeric_chars ${gitlab_pwd}
fi

# Set GitHub password without displaying it in terminal.
if [ "$github_pwd_flag" == "true" ]; then
	echo -n GitHub Password: 
	read -s github_password
	echo
  assert_is_non_empty_string ${github_password}
fi

### Verify prerequistes
if [ "$github_username" != "" ]; then
  echo "Setting: github_username=$github_username"
  set_default_personal_cred_if_empty "GITHUB_USERNAME_GLOBAL" $github_username
fi
# GitHub password is not stored.

if [ "$gitlab_username" != "" ]; then
	set_default_personal_cred_if_empty "GITLAB_SERVER_ACCOUNT_GLOBAL" $gitlab_username
fi
if [ "$gitlab_pwd" != "" ]; then
  set_gitlab_pwd $gitlab_pwd
fi
if [ "$gitlab_email" != "" ]; then
	set_default_personal_cred_if_empty "GITLAB_ROOT_EMAIL_GLOBAL" "$gitlab_email"
fi
if [ "$gitlab_email" != "" ]; then
	set_default_personal_cred_if_empty "GITLAB_ROOT_EMAIL_GLOBAL" "$gitlab_email"
fi

# TODO: verify required data is in personal_creds.txt


# Reload personal_creds.txt
source "$PERSONAL_CREDENTIALS_PATH"

# Verify the personal credits are stored correctly.
printf "\n\n\n Verifying the $PERSONAL_CREDENTIALS_PATH contains the right data."
verify_prerequisite_personal_creds_txt_contain_required_data
verify_prerequisite_personal_creds_txt_loaded


# Raise sudo permission at the start, to prevent requiring user permission half way through tests.
printf "\n\n\n Now getting sudo permission to perform the GitLab installation."
{
  sudo echo "hi"
} &> /dev/null

# Verify the GitHub user has the required repositories.
printf "\n\n\n Verifying the $GITHUB_STATUS_WEBSITE_GLOBAL and $PUBLIC_GITHUB_TEST_REPO_GLOBAL repositories exist in your GitHub account."
# TODO: include catch for: The requested URL returned error: 403 rate limit exceeded
#assert_required_repositories_exist $GITHUB_USERNAME_GLOBAL

# Get the GitHub personal access code.
printf "\n\n\n Setting and Getting the GitHub personal access token if it does not yet exist."
# TODO: RE-enable, only disabled to speed up debugging.!
#ensure_github_pat_can_be_used_to_set_commit_build_status $GITHUB_USERNAME_GLOBAL $PUBLIC_GITHUB_TEST_REPO_GLOBAL $github_password



# Check if ssh deploy key already exists and can be used to push
# to GitHub, before creating a new one.
printf "\n\n\n Checking to see if you already have ssh push access to the $GITHUB_STATUS_WEBSITE_GLOBAL repository with your ssh-deploy key."
has_ssh_push_access=$(check_if_machine_has_push_access_to_gitlab_build_status_repo_in_github $GITHUB_USERNAME_GLOBAL)
if [ "$has_ssh_push_access" == "NOTFOUND" ]; then
  # Get the GitHub ssh deploy key.
  printf "\n\n\n Ssh access to $GITHUB_STATUS_WEBSITE_GLOBAL was not found. Now creating an ssh deploy key for you and adding it to GitHub."
  ensure_github_ssh_deploy_key_can_be_used_to_push_github_build_status $GITHUB_USERNAME_GLOBAL $github_password
elif [ "$has_ssh_push_access" == "FOUND" ]; then
  # Verify the GitHub ssh deploy key works.
  printf "\n\n\n Verifying you indeed have ssh push access to $GITHUB_STATUS_WEBSITE_GLOBAL using your GitHub ssh-deploy key."
  verify_machine_has_push_access_to_gitlab_build_status_repo_in_github "$GITHUB_SSH_DEPLOY_KEY_NAME"
else
  echo "Error, the output of ssh_check_output did not end in FOUND, nor in NOTFOUND: $ssh_check_output"
  exit 56
fi


# TODO: Verify the GitHub personal access token is in $PERSONAL_CREDENTIALS_PATH file."
# verify_personal_creds_txt_contain_pacs

# Install prerequisites
printf "\n\n\n Checking if jquery is installed."
if [ $(jq --version) != "jq-1.6" ]; then
  printf "\n\n\n Installing jquery."
	yes | sudo apt install jq
fi


# Start gitlab server installation and gitlab runner installation.
if [ "$server_flag" == "true" ]; then
  # TODO: verify required data is in personal_creds.txt 
	# TODO: uncomment
  printf "\n\n\n Installing the GitLab server!"
  install_and_run_gitlab_server "$GITLAB_SERVER_PASSWORD_GLOBAL"
	echo "Installed gitlab server, should be up in a few minutes. You can visit it at:"
  echo "$GITLAB_SERVER_HTTP_URL"
fi

# TODO: Remove, this is done during the installation of the GitLab server.
# Get the GitLab personal access token
#printf "\n\n\n Verifying the GitLab personal access token works."
#ensure_new_gitlab_personal_access_token_works

# Verify all required credentials are in personal_creds.txt
printf "\n\n\n Verifying the GitHub and GitLab personal access tokens are in the $PERSONAL_CREDENTIALS_PATH file."
verify_personal_creds_txt_contain_pacs


# Set GitLab password without displaying it in terminal.
####if [ "$gitlab_personal_access_token_flag" == "true" ]; then
####  printf "\n\n\n Creating and storing GitLab personal access token."
####  create_gitlab_personal_access_token $gitlab_personal_access_token
#### 
####  # Check if token, as loaded from  not "" otherwise throw error
####  # Reload personal_creds.txt
####  source "$PERSONAL_CREDENTIALS_PATH"
####fi
####



# Check if runner is being uninstalled:
if [ "$runner_flag" == "true" ]; then
	# Test if the gitlab server is running
	if [ "$(gitlab_server_is_running | tail -1)" == "RUNNING" ]; then
    printf "\n\n\n Installing the GitLab runner!"
		install_and_run_gitlab_runner
	else
		echo "ERROR, tried to start GitLab runner directly without the GitLab server running."
		exit 1
	fi
fi

# Call run CI on default repository.
# Create method to run on particular user and particular repo



#https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#https://stackoverflow.com/questions/3980668/how-to-get-a-password-from-a-shell-script-without-echoing
