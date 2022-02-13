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
# Structure:Parsing
get_last_n_lines_without_spaces() {
	number=$1
	relative_filepath=$2
	
	# get last number lines of file
	last_number_of_lines=$(sudo tail -n "$number" "$relative_filepath")
	
	# Output true or false to pass the equality test result to parent function
	echo "$last_number_of_lines"
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
# allows a string with spaces, hence allows a line
file_contains_string() {
	STRING=$1
	relative_filepath=$2
	
	if grep -q "$STRING" "$relative_filepath" ; then
		echo "FOUND"; 
	else
		echo "NOTFOUND";
	fi
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
# TODO(a-t-0): Determine why it does not work in:
#if [ "$(lines_contain_string "$CONDA_ENVIRONMENT_NAME" "\${conda_environments}")" == "FOUND" ]; then
# TODO(a-t-0): Determine why it does not work in:
# @test "Substring in first line is found in lines by lines_contain_string." {
# In essence, determine why it does not work when the substring contains spaces, like:
# First line
# TODO(a-t-0): rename to: lines_contain_substring_without_spaces() {
# TODO(a-t-0): create a working modified duplicate named: lines_contain_substring_with_spaces() {
#######################################
lines_contain_string() {
	local substring="$1"
	shift
	local lines=("$@")
	
	local found_substring="NOTFOUND"

	for i in "${lines[@]}"; do
		if [[ $i == *"$substring"* ]]; then
			echo "FOUND"
			local found_substring="FOUND"
		fi
	done

	if [ "$found_substring" == "NOTFOUND" ]; then
		echo "NOTFOUND"
	fi
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
#######################################
lines_contain_string_with_space() {
	local substring="$1"
	local lines="$@"
	if [ "$lines" == "" ]; then
		echo "NOTFOUND"
	# shellcheck disable=SC2154
	elif [[ "$lines" =~ "$substring" ]]; then
		echo "FOUND"; 
	else
		echo "NOTFOUND";
	fi
}


string_in_lines() {
    local substring=$1
    shift
    local lines=$1
    if [[ $lines = *"$substring"* ]] ; then
        echo FOUND
    else
        echo NOTFOUND
    fi
}

#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
# Source: https://stackoverflow.com/questions/70597896/check-if-conda-env-exists-and-create-if-not-in-bash
find_in_conda_env(){
    conda env list | grep "${@}" >/dev/null 2>/dev/null
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
conda_env_exists() {
	local some_envirionment="$1"
	if find_in_conda_env ".*$some_envirionment.*" ; then
   		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
lines_contain_string_for_visudo() {
	local substring="$1"
	shift
	local lines="$@"
	local some_line
	nr_of_lines=$(echo "$lines" | wc -l)
		
	for i in $( eval echo {0..$nr_of_lines} )
	do 
		# do whatever on "$i" here
		#echo "i=$i"
		custom_line=$(get_line_by_nr_from_variable "$i"  "\${lines}")
		#echo "custom_line=$custom_line"
		if [[ "$custom_line" != "" ]]; then
			if [[ "$custom_line" == *"$substring"* ]]; then
				local found_substring="FOUND"
				echo "FOUND"
				#echo "some_line=$some_line"
				#echo "substring=$substring"
			fi
		fi
	done
	if [[ "$found_substring" != "FOUND" ]]; then
		echo "NOTFOUND"
	fi
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
get_line_nr() {
	eval STRING="$1"
	relative_filepath=$2
	line_nr=$(awk "/$STRING/{ print NR; exit }" "$relative_filepath")
	echo "$line_nr"
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
get_line_by_nr() {
	number=$1
	relative_filepath=$2
	#read -p "number=$number"
	#read -p "relative_filepath=$relative_filepath"
	the_line=$(sed "${number}q;d" "$relative_filepath")
	echo "$the_line"
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
get_line_by_nr_from_variable() {
	local number=$1
	eval lines="$2"
	
	local count=0
	while IFS= read -r line; do
		count=$((count+1))
		if [ "$count" -eq "$number" ]; then
			echo "$line"
		fi
	done <<< "$lines"
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
get_first_line_containing_substring() {
	# Returns the first line in a file that contains a substring, silent otherwise.
	eval relative_filepath="$1"
	eval identification_str="$2"
	
	# Get line containing <code id="registration_token">
	if [ "$(file_contains_string "$identification_str" "$relative_filepath")" == "FOUND" ]; then
		line_nr=$(get_line_nr "\${identification_str}" "$relative_filepath")
		if [ "$line_nr" != "" ]; then
			line=$(get_line_by_nr "$line_nr" "$relative_filepath")
			echo "$line"
		else
			#read -p "ERROR, did find the string in the file but did not find the line number, identification str =\${identification_str} And filecontent=$(cat $relative_filepath)"
			#exit 1
			true #equivalent of Python pass
		fi
	else
		#read -p "ERROR, did not find the string in the file identification str =\${identification_str} And filecontent=$(cat $relative_filepath)"
		#exit 1
		true #equivalent of Python pass
	fi
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
get_lhs_of_line_till_character() {
	line=$1
	character=$2
	
	# TODO: implement
	#lhs=${line%$character*}
	#read -p "line=$line"
	#read -p "character=$character"

	lhs=$(cut -d "$character" -f1 <<< "$line")
	echo "$lhs"
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
get_rhs_of_line_till_character() {
	# TODO: include space right after character, e.g. return " with" instead of "width" on ": with".
	line=$1
	character=$2
	
	rhs=$(cut -d "$character" -f2- <<< "$line")
	echo "$rhs"
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
get_nr_of_lines_in_var() {
	eval lines="$1"
	echo "$lines" | wc -l
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
# TODO(a-t-0): Include detection for empty variable: lines and return "" accordingly.
# https://stackoverflow.com/a/42399738/7437143
#######################################
# Structure:Parsing
get_last_line_of_set_of_lines() {
	#eval lines="$1"
	eval lines="$@"
	nr_of_lines=$(echo "$lines" | wc -l)
	last_line=$(get_line_by_nr_from_variable "$nr_of_lines" "\${lines}")
	echo "$last_line"
}

get_last_line_of_set_of_lines_without_evaluation_of_arg() {
	#eval lines="$1"
	lines="$@"
	nr_of_lines=$(echo "$lines" | wc -l)
	last_line=$(get_line_by_nr_from_variable "$nr_of_lines" "\${lines}")
	echo "$last_line"
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
get_last_space_delimted_item_in_line() {
	line="$1"
	IFS=' ' # let's make sure we split on newline chars
	var=("${lines}") # parse the lines into a variable that is countable
	stringarray=("$line")
	echo "${stringarray[-1]}"
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
function stringStripNCharsFromStart {
    echo ${1:$2:${#1}}
    #echo ${1:$2}
}


#######################################
# 
# Local variables:
#  
# Globals:
#  
# Arguments:
#  
# Returns:
#  0 If function was evaluated succesfull.
# Outputs:
#  
# TODO(a-t-0):
#######################################
assert_first_four_chars_are_sshd() {
	local string="$"
	
	if [ "${string:0:4}" == "sshd" ]; then
		echo "FOUND"
	else
		echo "The response to the lsof command does not start with:sshd"
		exit 7
	fi
}