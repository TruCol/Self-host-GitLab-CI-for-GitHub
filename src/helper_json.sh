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
# Run with:
# bash -c "source src/import.sh && get_repos_from_api_query_json"
get_repos_from_api_query_json() {
	filepath="src/eg_query.json"
	
	json=$(cat $filepath)
	#echo "json=$json"

	# First repo:
	#echo "$(echo "$json" | jq ".[][].repositories[][0]")"
	# Second repo
	#echo "$(echo "$json" | jq ".[][].repositories[][1]")"
	
	echo "$(echo "$json" | jq ".[][].repositories[][55]")"
	exit 4
	readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories") # works
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories[][].nameWithOwner")
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories[][][].nameWithOwner") # Gets first repo
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][][][][][].nameWithOwner") # Gets first repo
	
	readarray -t branch_commits_arr <  <(echo "$json" | jq ".[].oid")
	echo "branch_names_arr=${branch_names_arr[@]}"
	echo "branch_commits_arr=${branch_commits_arr[@]}"
	
	# Loop through branches using a mutual index i.
	#for i in "${!branch_names_arr[@]}"; do
	#	echo "${branch_names_arr[i]}" 
	#	echo "i=$i"
	#done

}



get_repos_from_api_query_json() {
	filepath="src/eg_query.json"
	
	json=$(cat $filepath)
	#echo "json=$json"

	# First repo:
	#echo "$(echo "$json" | jq ".[][].repositories[][0]")"
	# Second repo
	#echo "$(echo "$json" | jq ".[][].repositories[][1]")"
	
	echo "$(echo "$json" | jq ".[][].repositories[][55]")"
	exit 4
	readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories") # works
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories[][].nameWithOwner")
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories[][][].nameWithOwner") # Gets first repo
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][][][][][].nameWithOwner") # Gets first repo
	
	readarray -t branch_commits_arr <  <(echo "$json" | jq ".[].oid")
	echo "branch_names_arr=${branch_names_arr[@]}"
	echo "branch_commits_arr=${branch_commits_arr[@]}"
	
	# Loop through branches using a mutual index i.
	#for i in "${!branch_names_arr[@]}"; do
	#	echo "${branch_names_arr[i]}" 
	#	echo "i=$i"
	#done
	 
}