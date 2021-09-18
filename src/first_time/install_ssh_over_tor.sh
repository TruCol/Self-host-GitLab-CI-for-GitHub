#!/bin/bash
# Sets up SSH over tor and helps you copy the onion address 
# at which you can ssh into this RPI to your host device/pc. 

source src/helper.sh

echo_hello() {
	echo "hello"
}

echo_hello_input() {
	input=$1
	input_two=$2
	echo "hello$input$input_two"
}

read_three_args() {
	arg1=$1
	arg2=$2
	arg3=$3
	arg4=$4
	echo "arg4=$arg4"
}



# Ensure the SSH service is contained in the tor configuration.
has_two_consecutive_lines() {
	first_line=$1
	second_line=$2
	REL_FILEPATH=$3	

	if [ "$(file_contains_string "$first_line" "$REL_FILEPATH")" == "FOUND" ]; then
		if [ "$(file_contains_string "$second_line" "$REL_FILEPATH")" == "FOUND" ]; then
			# get line_nr first_line
			first_line_line_nr="$(get_line_nr "$first_line" "$REL_FILEPATH")"
			
			# get next line number
			next_line_number=$((first_line_line_nr + 1))
			
			# get next line
			next_line=$(get_line_by_nr "$next_line_number" "test/samplefile_with_spaces.txt")
			
			# verify next line equals the second line
			if [ "$next_line" == "$second_line" ]; then
				echo "FOUND"
			else
				echo "NOTFOUND"
			fi			
		fi
	else
		echo "NOTFOUND"
	fi
}

# TODO: remove
has_either_block_of_two_consecutive_lines() {
	first_line=$1
	second_line_option_I=$2
	second_line_option_II=$3
	REL_FILEPATH=$4
	
	has_first_block=$(has_two_consecutive_lines "$first_line"  "$second_line_option_I" "$REL_FILEPATH")
	#echo "has_first_block=$has_first_block"
	
	has_second_block=$(has_two_consecutive_lines "$first_line"  "$second_line_option_II" "$REL_FILEPATH")
	#echo "has_second_block=$has_second_block"
	if [ "$has_first_block" == "FOUND" ] || [ "$has_second_block" == "FOUND" ]; then
		echo "FOUND"
	else
		if [ "$(file_contains_string "$first_line" "$REL_FILEPATH")" == "FOUND" ]; then
			echo "ERROR"
		else
			echo "NOTFOUND"
		fi
	fi
}

append_lines_if_not_found() {
	first_line=$1
	second_line=$2
	REL_FILEPATH=$3
	echo "REL_FILEPATH=$REL_FILEPATH"
	has_block=$(has_two_consecutive_lines "$first_line"  "$second_line" "$REL_FILEPATH")
	if  [ "$has_block" == "NOTFOUND" ]; then
		#echo "$first_line" >> "$REL_FILEPATH"
		echo "$first_line" | sudo tee -a "$REL_FILEPATH"
		echo "$second_line" | sudo tee -a "$REL_FILEPATH"
	fi
}

# append ssh service to torrc
#first_line="HiddenServiceDir $HIDDENSERVICEDIR_SSH$HIDDENSERVICENAME_SSH/"
#second_line_option_I="HiddenServicePort 22"
#second_line_option_II="HiddenServicePort 22 127.0.0.1:22"
# Note option 2 is used (in the old environment).
#$(append_lines_if_not_found "$first_line" "$second_line_option_II" "$TOR_CONFIG_LOCATION")

# append ssh service to /etc/ssh/sshd_config
#last_two_lines=$(sudo tail -n 2 /etc/ssh/sshd_config)
#second_last_line=$(echo $last_two_lines | sudo head -n 1)
#last_line=$(sudo tail -n 1 /etc/ssh/sshd_config)
#if [ "$second_last_line" != "Port 22" ]; then
#	if [ "$last_line" != "Port 23" ]; then
#		echo 'Port 22' | sudo tee -a /etc/ssh/sshd_config
#		echo 'Port 23' | sudo tee -a /etc/ssh/sshd_config
#		service sshd restart
#	fi
#fi

#first_line="Port 22"
#second_line="Port 23"
#$(append_lines_if_not_found "$first_line" "$second_line" "$SSH_CONFIG_LOCATION")
#service sshd restart


# TODO: set up cronjob that starts tor service upon boot.
# TODO: start cronjob manually
# TODO: verify tor is started
# TODO: verify one can ssh into the server over tor
# TODO: share ssh key