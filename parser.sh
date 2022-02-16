#!/bin/bash
POSITIONAL_ARGS=()

source src/helper_parsing.sh

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
gitlab_personal_access_token_flag='false'
gitlab_email_flag='false'
gitlab_server_url_flag='false'

print_usage() {
  printf "\nDefault usage, write:"
  printf "\n./install_gitlab.sh -s -r -ds -cpat to install GitLab CI and run it on your GitHub repositories."
  printf "\n./install_gitlab.sh -s -r -ds -cpat -user <your GitHub username> -repo <your GitHub repository name> to install GitLab CI and run it on the repository of that user.\n"

  printf "\nSupported options:"
  # TODO: verify if the user can set the value of the GitHub personal access
  # token, or whether the value is given/set by GitHub automatically.
  # If it is given by GitHub automatically, change this into a boolean decision
  # that indicates whether or not the user will set the commit build statuses
  # on GitHub or not.
  
  printf "\n./install_gitlab.sh -ds or: ./install_gitlab.sh --deploy-ssh to start by setting the ssh deploy key to the GitHub build status repository."
  printf "\n./install_gitlab.sh -r or: ./install_gitlab.sh --runner to do an installation of the GitLab runner."
  printf "\n./install_gitlab.sh -s or: ./install_gitlab.sh --server\n to do an installation of the GitLab server."
  
  printf "\n./install_gitlab.sh -hubcpat or: ./install_gitlab.sh --github-commit-status-pat to enable the code to set the build status of GitHub commits using a personal acces token."
  printf "\n./install_gitlab.sh -hubpwd or: ./install_gitlab.sh --github-password\n to pass your GitHub password, to prevent having to wait untill you can enter it in the website."
  printf "\n./install_gitlab.sh -hubuser <your GitHub username> or: ./install_gitlab.sh --github-username <your GitHub username>\n to pass your GitHub username, to prevent having to wait untill you can enter it in the website."
  
  printf "\n./install_gitlab.sh -labemail <your email for GitLab> or: ./install_gitlab.sh --gitlab-email <your email for GitLab>\n to pass your the email address you use for GitLab, and store it in your ../personal_credentials.txt."
  printf "\n./install_gitlab.sh -labpat <your new GitLab personal access token> or: ./install_gitlab.sh --gitlab-personal-access-token <your new GitLab personal access token>\n to pass your new GitLab personal access token, and store it in your ../personal_credentials.txt."
  printf "\n./install_gitlab.sh -labpwd or: ./install_gitlab.sh --gitlab-password\n to pass your new GitLab password,pass your GitLab username, and store it in your ../personal_credentials.txt."
  printf "\n./install_gitlab.sh -laburl <website for your GitLab server> or: ./install_gitlab.sh --gitlab-email <website for your GitLab server>\n to set a custom gitlab server website (default=http://127.0.0.1), and store it in your ../personal_credentials.txt."
  printf "\n./install_gitlab.sh -labuser <your new GitLab username> or: ./install_gitlab.sh --gitlab-username <your GitLab username>\n to set a custom GitLab username(default=root), and store it in your ../personal_credentials.txt."

  printf "\n\nNot yet supported:"
  printf "\n./install_gitlab.sh -hubcssh or: ./install_gitlab.sh --github-commit-status-ssh to enable the code to set the build status of GitHub commits using an ssh key."
  printf "\n./install_gitlab.sh -b or: ./install_gitlab.sh --boot to set up a script/cronjob that runs the GitLab CI on your GitHub repositories in the background after reboots."
  printf "\n./install_gitlab.sh -repo or: ./install_gitlab.sh --repo to run the GitLab CI on a particular GitHub repository."
  printf "\n./install_gitlab.sh -tw or: ./install_gitlab.sh --tor-website to set up tor website for your GitLab server."
  printf "\n./install_gitlab.sh -user or: ./install_gitlab.sh --user to run the GitLab CI on a particular GitHub user/organisation."
  
  printf "you can also combine the separate arguments in different orders, e.g. -r -s -w.\n\n"
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
    -hubuser|--github-username)
      github_username_flag='true'
      github_username="$2"
      assert_is_non_empty_string ${github_username}
      shift # past argument
      shift

      ;;
    -hubpwd|--github-password)
      github_pwd_flag='true'
      #github_pwd="$2" # Don't allow vissibly typing pwd in command line.
      shift # past argument
      ;;
    
    -labuser|--gitlab-username)
      gitlab_username_flag='true'
      gitlab_username="$2"
      assert_is_non_empty_string ${gitlab_username}
      shift # past argument
      shift
      ;;
    -labpwd|--gitlab-password)
      gitlab_pwd_flag='true'
      #gitlab_pwd="$2" # Don't allow vissibly typing pwd in command line.
      shift # past argument
      ;;
    -labpat|--gitlab-personal-access-token)
      gitlab_personal_access_token_flag='true'
      shift # past argument
      ;;
    -labemail|--gitlab-email)
      gitlab_email_flag='true'
      gitlab_email="$2"
      shift # past argument
      shift
      ;;
    -laburl|--gitlab-server-url)
      gitlab_server_url_flag='true'
      gitlab_server_url="$2"
      assert_is_non_empty_string ${gitlab_server_url}
      shift # past argument
      shift
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

if [ "$server_flag" == "true" ]; then
	# TODO: uncomment
  #install_and_run_gitlab_server
	echo "Installed gitlab server, should be up in a few minutes."
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

# Set GitHub personal_access_token without displaying it in terminal.
if [ "$commit_status_personal_access_token_flag" == "true" ]; then
	echo -n "GitHub personal access token, to set the GitHub commit statuses": 
	read -s commit_status_personal_access_token
	echo
	
  # Display commit_status_personal_access_token.
	echo $commit_status_personal_access_token
  assert_string_only_contains_alphanumeric_chars ${commit_status_personal_access_token}
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


# Set GitLab personal access token without displaying it in terminal.
if [ "$gitlab_personal_access_token_flag" == "true" ]; then
	echo -n "Your new personal access token:": 
	read -s gitlab_personal_access_token
	echo
	
  # Display commit_status_personal_access_token.
	echo $gitlab_personal_access_token
  assert_string_only_contains_alphanumeric_chars ${gitlab_personal_access_token}
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
