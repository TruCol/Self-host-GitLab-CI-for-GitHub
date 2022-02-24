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
  printf "\n./install_gitlab.sh -s -r -hu <your GitHub username> -hp -lp\n                                       to install GitLab CI and run it on your GitHub repositories."

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
    -labpat|--gitlab-personal-access-token)
      gitlab_personal_access_token_flag='true'
      shift # past argument
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



# Set GitHub password without displaying it in terminal.
if [ "$github_pwd_flag" == "true" ]; then
	echo -n Password: 
	read -s password
	echo
	
  # Display password.
	echo $password
  assert_string_only_contains_alphanumeric_chars ${password}
fi

# Set GitLab password without displaying it in terminal.
if [ "$gitlab_pwd_flag" == "true" ]; then
	echo -n "Your new GitLab password:": 
	read -s gitlab_pwd
	echo
	
  # Display commit_status_personal_access_token.
	echo $gitlab_pwd
  assert_string_only_contains_alphanumeric_chars ${gitlab_pwd}
fi



### Verify prerequists
if [ "$github_username" != "" ]; then
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

# TODO: verify required data is in personal_creds.txt


# Reload personal_creds.txt
source "$PERSONAL_CREDENTIALS_PATH"
if [ "$GITHUB_USERNAME_GLOBAL" != "" ]; then
  assert_required_repositories_exist $GITHUB_USERNAME_GLOBAL
else
  echo "Error, was not able to succesfully set the GitHub username in $PERSONAL_CREDENTIALS_PATH."
fi

if [ "$GITHUB_USERNAME_GLOBAL" != "" ] && [ "$PUBLIC_GITHUB_TEST_REPO_GLOBAL" != "" ]; then
  ensure_github_pat_can_be_used_to_set_commit_build_status $GITHUB_USERNAME_GLOBAL $PUBLIC_GITHUB_TEST_REPO_GLOBAL
fi

verify_prerequisite_personal_creds_txt_contain_required_data
verify_prerequisite_personal_creds_txt_loaded


# Raise sudo permission at the start, to prevent requiring user permission half way through tests.
{
  sudo echo "hi"
} &> /dev/null

# Install prerequisites
if [ $(jq --version) != "jq-1.6" ]; then
	yes | sudo apt install jq
fi

if [ "$server_flag" == "true" ]; then
  # TODO: verify required data is in personal_creds.txt 
	# TODO: uncomment
  #install_and_run_gitlab_server
	echo "Installed gitlab server, should be up in a few minutes."
fi


# Create method to set personal access token in GitHub. #80

# Start gitlab server installation and gitlab runner installation.
# Move the "has ssh access to github build status website to the start"
# Move the "has commit status setting access to arbitrary repo of user, to the start."

# Call setting the GitHub personal access token to set commit status
# pass that commit status setting boolean to the ci runner method.
# Call run CI on default repository.
# Create method to run on particular user and particular repo



#https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#https://stackoverflow.com/questions/3980668/how-to-get-a-password-from-a-shell-script-without-echoing
