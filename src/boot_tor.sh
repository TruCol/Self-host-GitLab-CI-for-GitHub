#!/bin/bash

## Description
# This script sets up a tor connection. Once the tor connection is established, 
# it starts monitoring whether the tor connection is maintained. 
# If the tor-connection is dropped, it automatically kills the two jobs that are created
# WITHIN this script. (jobs can only be created in a single shell, not from one script/shell to the other)
# The first job is the tor_connection job. The second job is currently unidentified.
# Note. This is not a script that calls other scripts and services, it only maintains a tor connection.


## Usage
# Set up this script as a crondjob with the following commands(first put it in the ~/startup/` folder):
# sudo crontab -e
# @reboot bash /home/ubuntu/startup/torssh.sh >1 /dev/null 2> /home/ubuntu/startup/some_job.er


source src/install_and_boot_gitlab_server.sh
source src/install_and_boot_gitlab_runner.sh
source src/helper.sh
source src/hardcoded_variables.txt

# TODO: verify the reboot script is executable, otherwise throw a warning



get_tor_status() {
	tor_status=$(curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs)
	echo $tor_status
}

connect_tor() {
	tor_connection=$(nohup sudo tor > sudo_tor.out &)
	sleep 10 3>- &
	echo $tor_connection
}

start_gitlab_server() {
	timestamp_filepath=$1
	export_timestamp $timestamp_filepath
	install_and_run_gitlab_server
}

start_gitlab_runner() {
	timestamp_filepath=$1
	export_timestamp $timestamp_filepath
	install_and_run_gitlab_runner
}

export_timestamp() {
	filepath=$1
	int_time_in_second=$[$(date +%s)]
	echo "$int_time_in_second" > "$filepath"
}

started_less_than_n_seconds_ago() {
	timestamp_filepath=$1
	n_seconds=$2
	
	if [ -f "$timestamp_filepath" ] ; then
		# get results and specify expected result.
		timestamp_time=$(cat "$timestamp_filepath")
		current_time=$[$(date +%s)]
		timestamp_age="$(echo $current_time $timestamp_time-p | dc)"
		
		# Was the timestamp created less than n_seconds ago?
		if [ "$timestamp_age" -lt $n_seconds ]; then
			echo "YES"
		else
			echo "NO"
		fi
	else
		echo "NO"
	fi
}

deploy_gitlab() {
	# assume this function is called every minute or so
	
	# Check if GitLab server is running, if no: 
	if [ $(gitlab_server_is_running | tail -1) == "NOTRUNNING" ]; then
		started_server_n_sec_ago=$(started_less_than_n_seconds_ago $SERVER_TIMESTAMP_FILEPATH "$SERVER_STARTUP_TIME_LIMIT")
		echo "The gitlab server is not running. started_server_n_sec_ago=$started_server_n_sec_ago"
		
		# Check if GitLab server has been started in the last 10 minutes, if yes:
		if [ "$started_server_n_sec_ago" == "YES" ]; then
			# wait
			sleep 1 3>- &
		# Check if GitLab server has been started in the last 10 minutes, if no:
		elif [ "$started_server_n_sec_ago" == "NO" ]; then
			# TODO: check when the last start of the server was initiated, whether the device has been live since, and raise error if server is still not running by now.
			echo "Starting gitlab server"
			# start GitLab server
			output=$(start_gitlab_server "$SERVER_TIMESTAMP_FILEPATH")
			read -p "server start output=$output"
		fi
	# Check if GitLab server is running, if yes: 
	elif [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
		# TODO: wait untill gitlab server is installed and running correctly/responsively
		echo "The gitlab server is running."
		
		# Check if GitLab runner is running, if yes:
		if [ $(gitlab_runner_is_running | tail -1) == "RUNNING" ]; then
			echo "RUNNING"
		# Check if GitLab runner is running, if no:
		elif [ $(gitlab_runner_is_running | tail -1) == "NOTRUNNING" ]; then
			# Check if GitLab server has been started in the last 2 minutes, if yes:
			echo "runner is not yet running"
			if [ $(started_less_than_n_seconds_ago $RUNNER_TIMESTAMP_FILEPATH "$RUNNER_STARTUP_TIME_LIMIT") == "YES" ]; then
				# wait
				sleep 1 3>- &
				echo "started less than n seconds ago"
			# Check if GitLab server has been started in the last 2 minutes, if no:
			elif [ $(started_less_than_n_seconds_ago $RUNNER_TIMESTAMP_FILEPATH "$RUNNER_STARTUP_TIME_LIMIT") == "NO" ]; then
				# TODO: check when the last start of the server was initiated, whether the device has been live since, and raise error if runner is still not running by now.
				# start GitLab runner
				start_gitlab_runner "$RUNNER_TIMESTAMP_FILEPATH" &
				echo "STARTING RUNNER"
			fi
		fi	
	fi
	# TODO throw error if output is not either NOTRUNNING or RUNNING
}

run_deployment_script_for_n_seconds() {
	duration=$1
	echo "duration=$duration"
	running="false"
	end=$(("$SECONDS" + "$duration"))
	while [ $SECONDS -lt $end ]; do
		if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
			if [ $(gitlab_runner_is_running | tail -1) == "RUNNING" ]; then
				running="true"
				echo "RUNNING";
				break;
			else 
				deploy_gitlab
			fi
		else
			deploy_gitlab
		fi
	done
	if [ "$running" == "false" ]; then
		echo "ERROR, did not find the GitLab server running within $duration seconds!"
		#exit 1
	fi
}

start_and_monitor_tor_connection(){
	# TODO: verify the tor script and sites have been deployed before proceeding, send message otherwise
	echo "To get the onion domain to ssh into, run:"
	echo "sudo cat /var/lib/tor/other_hidden_service/hostname"

	# Start infinite loop that keeps system connected to vpn
	while [ "false" == "false" ]
	do
		# Get tor connection status
		tor_status_outside=$(get_tor_status)
		echo "tor_status_outside=$tor_status_outside" >&2
		sleep 1 3>- &
		
		# Reconnect tor if the system is disconnected
		if [[ "$tor_status_outside" != *"Congratulations"* ]]; then
			echo "Is Disconnected"
			# Kill all jobs
			jobs -p | xargs -I{} kill -- -{}
			sudo killall tor
			tor_connections=$(connect_tor)
		elif [[ "$tor_status_outside" == *"Congratulations"* ]]; then
			echo "Is connected"
			
			# Verify the correct amount of jobs are running
			if [ `jobs|wc -l` == 2 ]
				then
				echo 'There are TWO jobs'
				# Start GitLab service
				deploy_gitlab
			else
				echo 'There are NOT CORRECT AMOUNT OF jobs'
				# Kill all jobs
				jobs -p | xargs -I{} kill -- -{}
				# restart jobs
				echo "Killed all jobs"
				sleep 6 &
				echo "\n\n\n Job 1"
				sleep 5 &
				echo "started Job 2"
			fi
		fi
	done
}
