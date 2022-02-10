#!/bin/bash

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:html
# Downloads the source code of an incoming website into a file.
# TODO: ensure/verify curl is installed before calling this method.
downoad_website_source() {
	site=$1
	output_path=$2
	
	output=$(curl "$site" > "$output_path")
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:Configuration
visudo_contains() {
	local line="$1"
	#echo "line=$line"
	local visudo_content=$(sudo cat /etc/sudoers)
	#echo $visudo_content
	#nr_of_lines=${#visudo_content} 
	#nr_of_lines=$(wc -l $visudo_content)
	nr_of_lines=$(echo "$visudo_content" | wc -l)
	#echo "nr_of_lines=$nr_of_lines"
	
	#actual_result=$(lines_contain_string "$line" "\"${visudo_content}")
	actual_result=$(lines_contain_string_for_visudo "$line" "\"${visudo_content}")
	echo "$actual_result"
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:Parsing
get_array() {
	json=$1
	identifier=$2
	# shellcheck disable=SC2034
	nr_of_elements=$(echo "$json" | jq 'length')
	
	readarray -t commit_array <  <(echo "$json" | jq ".[].$identifier")
	# loop through elements
	#for i in {0.."$nr_of_elements"}
	#do
	#	echo "Welcome $i times"
	#	sleep 1
	#done
	#echo "$commit_array"
	echo  "${commit_array[@]}"
}