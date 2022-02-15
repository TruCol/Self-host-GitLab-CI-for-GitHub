#!/bin/bash
POSITIONAL_ARGS=()

print_usage() {
  printf "\nUsage, write:"
  printf "\n./install_gitlab.sh -s -r -ds -cpat to install GitLab CI and run it on your GitHub repositories."
  printf "\n./install_gitlab.sh -s -r -ds -cpat -user <your GitHub username> -repo <your GitHub repository name> to install GitLab CI and run it on the repository of that user.\n"
  printf "\nSupported options:"
  printf "\n./install_gitlab.sh -cpat or: ./install_gitlab.sh --commit-status-pat to enable the code to set the build status of GitHub commits using a personal acces token."
  printf "\n./install_gitlab.sh -cssh or: ./install_gitlab.sh --commit-status-ssh to enable the code to set the build status of GitHub commits using an ssh key."
  printf "\n./install_gitlab.sh -ds or: ./install_gitlab.sh --deploy-ssh to start by setting the ssh deploy key to the GitHub build status repository."
  printf "\n./install_gitlab.sh -r or: ./install_gitlab.sh --runner to do an installation of the GitLab runner."
  printf "\n./install_gitlab.sh -s or: ./install_gitlab.sh --server\n to do an installation of the GitLab server."
  printf "\n\nNot yet supported:"
  printf "\n./install_gitlab.sh -b or: ./install_gitlab.sh --boot to set up a script/cronjob that runs the GitLab CI on your GitHub repositories in the background after reboots."
  printf "\n./install_gitlab.sh -repo or: ./install_gitlab.sh --repo to run the GitLab CI on a particular GitHub repository."
  printf "\n./install_gitlab.sh -tw or: ./install_gitlab.sh --tor-website to set up tor website for your GitLab server."
  printf "\n./install_gitlab.sh -user or: ./install_gitlab.sh --user to run the GitLab CI on a particular GitHub user/organisation."
  
  
  #printf "\n./install_gitlab -w\n to do an installation of the GitLab runner that waits untill the GitLab server is running."
  
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
	-cssh|--commit-status-ssh)
      commit_status_ssh_flag='true'
      shift # past argument
      ;;
	-cpat|--commit-status-pat)
      commit_status_personal_access_token_flag='true'
      shift # past argument
      ;;
	-b|--boot)
      setup_boot_script_flag='true'
      shift # past argument
      ;;
	-tw|--tor_website)
      set_up_tor_website_for_gitlab_server_flag='true'
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