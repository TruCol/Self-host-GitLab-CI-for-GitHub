#!/bin/bash
POSITIONAL_ARGS=()

source src/stacktrace.sh
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
hub_prerequistes_only_flag='false'
lab_prerequistes_only_flag='false'

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
  
  printf "\n-p | --prereq                          to verify prerequisites."
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
    -b|--boot)
      setup_boot_script_flag='true'
      shift # past argument
      ;;
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
    -eu|--external-url)
      HTTPS_EXTERNAL_URL="$2"
      shift # past argument
      shift
      ;;
    -hubcssh|--github-commit-status-ssh)
      commit_status_ssh_flag='true'
      shift # past argument
      ;;
    -hubcpat|--github-commit-status-pat)
      commit_status_personal_access_token_flag='true'
      shift # past argument
      ;;
    -gs|--gitlab-server)
      GITLAB_SERVER="$2"
      GITLAB_SERVER_HTTPS_URL="https://$GITLAB_SERVER"
      shift # past argument
      shift
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
    -hpre|--hubprereq)
      hub_prerequistes_only_flag='true'
      shift # past argument
      ;;
    -lpre|--labprereq)
      lab_prerequistes_only_flag='true'
      shift # past argument
      ;;
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
assert_is_non_empty_string ${HTTPS_EXTERNAL_URL}
assert_is_non_empty_string ${GITLAB_SERVER}

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

# Set GitHub password without displaying it in terminal.
if [ "$hub_prerequistes_only_flag" == "true" ]; then
	ensure_github_prerequisites_compliance
fi

# Set GitLab password without displaying it in terminal.
if [ "$lab_prerequistes_only_flag" == "true" ]; then
	ensure_gitlab_prerequisites_compliance
fi


# Start gitlab server installation and gitlab runner installation.
if [ "$server_flag" == "true" ]; then
  printf "\n Ensuring prequisites are satisfied."
  ensure_gitlab_prerequisites_compliance
  printf "\n Installing the GitLab server!"
  printf "\n TODO: SEPARATE INTERACTION WITH GITHUB FROM: install_and_run_gitlab_server!"
  install_and_run_gitlab_server "$GITLAB_SERVER_PASSWORD_GLOBAL"
	echo "Installed gitlab server, should be up in a few minutes. You can visit it at:"
  echo "$GITLAB_SERVER_HTTPS_URL"
fi




# Set GitLab password without displaying it in terminal.
####if [ "$gitlab_personal_access_token_flag" == "true" ]; then
####  printf "\n Creating and storing GitLab personal access token."
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
    printf "\nInstalling the GitLab runner!"
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
