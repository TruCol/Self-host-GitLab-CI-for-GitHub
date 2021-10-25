#!/bin/bash

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'

# Script:
#general_server_output.txt content:
# PWD
repopath="/var/opt/gitlab/git-data/repositories/@hashed/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35.git"
# Build stattus locations
expected_path="/var/opt/gitlab/gitlab-rails/shared/artifacts/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35"
# Commit:(newrev)
commit_sha="9514d16aafc1d741ba6a9ff47718d632fa8d435b"
expected_shortened_commit_sha="9514d16a"
job_log_containing_path="test/example_logs"

receipe() {
	repopath_without_dot_git=$(remove_dot_git "$repopath")
	#echo "repopath_without_dot_git=$repopath_without_dot_git"
	repopath_to_artifacts=$(replace_filepath "$repopath_without_dot_git")
	#echo "repopath_to_artifacts=$repopath_to_artifacts"
	assert_equal "$expected_path" "$repopath_to_artifacts"
	
	shortened_commit_sha=$(get_shortened_commit_sha "$commit_sha")
	assert_equal "$shortened_commit_sha" "$expected_shortened_commit_sha"
	
	#filepath_list=$(find $job_log_containing_path -name "job.log")
	#echo "filepath_list=$filepath_list"
	
	#filepath=$(find_job_of_commit "$filepath_list" "$shortened_commit_sha")
	filepath=$(find_job_of_commit "$job_log_containing_path" "$shortened_commit_sha")
	assert_equal "$job_log_containing_path/234/job.log" "$filepath"
	echo "asserted filepath"
	
	build_status=$(get_build_status "$filepath")
	assert_equal "success" "$build_status"
	echo "asserted build status"
}

remove_dot_git() {
	local some_string=$1
	without_dot_git=${some_string::-4}
	echo "$without_dot_git"
}


#0. remove `.git` at end
#1. replace
#git-data/repositories/@hashed
#2. With:
#gitlab-rails/shared/artifacts
replace_filepath() {
	filepath=$1
	step_one="${filepath/git-data/gitlab-rails}"
	step_two="${step_one/repositories/shared}"
	step_three="${step_two/@hashed/artifacts}"
	echo "$step_three"
}

#/var/opt/gitlab/gitlab-rails/shared/artifacts/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35
#3. Get first n characters of commit sha:
get_shortened_commit_sha() {
	commit=$1
	shortened_commit=${commit::8}
	echo "$shortened_commit"
}

#4. loop through job.log files
#find_job_of_commit() {
#	local search_path=$1
#	local searched_commit=$2
#	filepath_list=$(find $search_path -name "job.log")
#	while IFS= read -r line; do
#		if [ "$line" != "" ]; then
#			job_log_content="$(cat $line)"
#			if [[ "$job_log_content" == *"Checking out $searched_commit"* ]]; then
#				echo "$line"
#			fi
#		fi
#	done <<< "$filepath_list"
#}

#7. Optional, find branch name.

# Get Job build status
get_build_status() {
	local job_log_path=$1
	job_log_content="$(cat $job_log_path)"
	#if [[ "$job_log_content" == *"Job succeeded"* ]]; then
	#	echo "success"
	#elif [[ "$job_log_content" == *"Job failed"* ]]; then
	#	echo "failed"
	#else
	#	echo "NOTFOUND"
	#fi
	status=""
	while [ "$status" == "" ]
	do
		if [[ "$job_log_content" == *"Job succeeded"* ]]; then
			status="success"
			touch "success.txt"
		elif [[ "$job_log_content" == *"Job failed"* ]]; then
			status="failed"
			touch "failed.txt"
		else
			echo "NOTFOUND"
			sleep 2
		fi
	done
	echo "$status"
}


#4. loop through job.log files
find_job_of_commit() {
	local search_path=$1
	local searched_commit=$2
	#query_result=$(while ! find -name "job.log" | xargs grep "Checking out $searched_commit"; do sleep 10 ; done)
	query_result=$(while ! find "$search_path" -name "job.log" | xargs grep "Checking out $searched_commit"; do sleep 10 ; done)
	found_filepath=$(get_lhs_of_line_till_character "$query_result" ":")
	#filepath=""
	#while [ "$filepath" == "" ]
	#do
	#	filepath_list=$(find $search_path -name "job.log")
	#	array=(${filepath_list//$'\n'/ })
	#	filepath=$(get_filepath "$searched_commit" "${array[@]}")
	#	sleep 1
	#done
	echo "$found_filepath"
}

# loops through list of filepaths and checks if they contain a certain substring
get_filepath() {
	local searched_commit=$1
	shift
	file_list=("$@")
	# loop through file list and store search_result_boolean
	for filepath in "${file_list[@]}";
		do
			substring="Checking out $searched_commit"
			found_commit="$(file_contains_string "$substring" "$filepath")"
			if [[ "$found_commit" == "FOUND" ]]; then
				echo "$filepath"
			fi
      done
}

# checks if a file contains a certain substring
# allows a string with spaces, hence allows a line
file_contains_string() {
	STRING=$1
	REL_FILEPATH=$2
	
	if [[ ! -z $(grep "$STRING" "$REL_FILEPATH") ]]; then 
		echo "FOUND"; 
	else
		echo "NOTFOUND";
	fi
}

get_lhs_of_line_till_character() {
	line=$1
	character=$2
	
	# TODO: implement
	#lhs=${line%$character*}
	#read -p "line=$line"
	#read -p "character=$character"

	lhs=$(cut -d "$character" -f1 <<< "$line")
	echo $lhs
}

receipe