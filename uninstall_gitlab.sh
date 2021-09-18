server_soft_flag='false'
server_hard_flag='false'
server_hard_yes_flag='false'
runner_flag='false'

#verbose='false'

print_usage() {
  printf "\nUsage: write:"
  printf "\n\n ./uninstall -s\n to do a soft uninstall of the GitLab server (preserves repositories etc.)."
  printf "\n./uninstall -h\n to do a hard uninstallation and removal of the GitLab server (DELETES repositories, user accounts etc.)."
  printf "\n./uninstall -y\n to do a hard uninstallation and removal of the GitLab server without prompting for confirmation (DELETES repositories, user accounts etc.)."
  printf "\n./uninstall -r \n to uninstall the GitLab runners,"
  printf "\n./uninstall -s -r \n to uninstall the GitLab server and runners.\n"
  printf "you can also combine the separate arguments in different orders, e.g. -r -y -h etc.\n\n"
}

while getopts 'shyr' flag; do
  case "${flag}" in
    s) server_soft_flag='true' ;;
    h) server_hard_flag='true' ;;
    y) server_hard_yes_flag='true' ;;
    r) runner_flag='true' ;;
    *) print_usage
       exit 1 ;;
  esac
done

# print the usage if no arguments are given
[ $# -eq 0 ] && { print_usage; exit 1; }

#echo "server_soft_flag=$server_soft_flag";
#echo "server_hard_flag=$server_hard_flag";
#echo "server_hard_yes_flag=$server_hard_yes_flag";
#echo "runner_flag=$runner_flag";

source src/uninstall_gitlab_server.sh
source src/uninstall_gitlab_runner.sh
source src/hardcoded_variables.txt

## argument parsing logic:
if [ "$server_hard_yes_flag" == "true" ] && [ "$server_soft_flag" == "true" ]; then
	echo "ERROR, you chose to manually override the prompt for the soft uninstallation, but the soft uninstallation does not not prompt for confirmation."
	exit 1
fi

# Check if runner is being uninstalled:
if [ "$runner_flag" == "true" ]; then
	uninstall_gitlab_runner
fi

if [ "$server_soft_flag" == "true" ]; then
	uninstall_gitlab_runner
fi

if [ "$server_hard_flag" == "true" ] && [ "$server_hard_yes_flag" == "false" ]; then
	read -p "Do you wish to uninstall GitLab and remove all its repositories, issues, users and server settings?" yn
	case $yn in
		[Yy]* ) uninstall_gitlab_server "true";;
		[Nn]* ) echo "The GitLab server was NOT uninstalled"; exit 0;;
		* ) echo "Please answer yes or no."
		exit 1;;
	esac
fi

if [ "$server_hard_flag" == "true" ] && [ "$server_hard_yes_flag" == "true" ]; then
	uninstall_gitlab_server "true"
	echo "Performed hard uninstallation of GitLab server and all its repositories, settings etc."
fi


# TODO: 
# call the script that installs tor and ssh for the username
# Create a cronjob that starts the tor ssh service at startup
# TODO: remove the infintely growing list of responses in the tor_ssh script
# TODO: reboot the device if the Gitlab server is down.
# TODO: reboot the device if the Gitlab runner is down.
