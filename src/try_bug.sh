#!/bin/bash
# Run with
# bash -c 'source src/try_bug.sh && assert_github_build_status_is_set_correctly_retry HiveMinds gitlab-ci-multi-runner 325297dc179a7622b2e70e9beefaabe35e999ea6 failure'
# bash -c 'source src/import.sh && assert_github_build_status_is_set_correctly_retry HiveMinds gitlab-ci-multi-runner 325297dc179a7622b2e70e9beefaabe35e999ea6 failure'
assert_github_build_status_is_set_correctly_retry() {
    local github_username="$1"
	local github_repo_name="$2"
	local github_commit_sha="$3"
	local commit_build_status="$4"

    # Define the expected response contents.
    local expected_url="https://api.github.com/repos/$github_username/$github_repo_name/statuses/$github_commit_sha"
    local expected_state="\"state\":\"$commit_build_status\","

    # Get the json containing the GitHub build statusses.
    local getting_output_json=$(GET https://api.github.com/repos/"$github_username"/"$github_repo_name"/commits/"$github_commit_sha"/statuses)
        
    # Verify the build status json/response is not empty.
    if [ "$getting_output_json" == "" ] || [ "$getting_output_json" == " " ] || [ "$getting_output_json" == "[]" ]; then
        printf "Error, the output of getting the GitHub commit build status is empty:\n"
        printf "$getting_output_json.\n"
        exit 5
    else
        # Extract the urls from the json response.
        local urls_in_json="$(echo "${getting_output_json[0]}" | jq ".[].url")"
        local state_in_json="$(echo "${getting_output_json[0]}" | jq ".[].state")"
        first_line=$(echo $urls_in_json 2>&1 | head -n 1)
        
        for word in $urls_in_json
        do
            first_url=$word
            break
        done
        
        read -p "first_line=$first_line"
        retry=$(get_first_space_delimted_item_in_line "$first_line")
        read -p "retry=$retry"

        read -p "urls_in_json="
        read -p "$urls_in_json"
        read -p "AND"
        read -p "${urls_in_json[0]}"
        read -p "$state_in_json"
        
        local expected_url_entry='"url":"'"$expected_url"'",'
        local expected_state_entry='"state":"'"$commit_build_status"'",'

        
        local found_url_entry="$(command_output_contains_copy "$expected_url_entry" "${getting_output_json[0]}")"
        local found_url_entry_two="$(command_output_contains_copy "$expected_url" "$urls_in_json")"
        #local found_state_entry="$(command_output_contains_copy "$expected_state_entry" "${getting_output_json[0]}")"
        local found_state_entry="$(command_output_contains_copy "$expected_state_entry" "${getting_output_json[0]}")"
        local found_state_entry_two="$(command_output_contains_copy "$expected_state_entry" "$state_in_json")"
        
        # Verify the expected url and state are found in the GitHub response.
        if [ "$found_url_entry" != "FOUND" ]; then
            # shellcheck disable=SC2059
		    printf "Error, GitHub commit status Get request did not contain expected_url_entry:\n"
            printf "$expected_url_entry\n\n"
            printf "Instead, the getting output was:\n"
            printf "${getting_output_json[0]}\n\n"
		    exit 6
        elif [ "$found_state_entry" != "FOUND" ]; then
            printf "Error, the status of the repo did not contain expected_state_entry:\n"
            printf "$expected_state_entry\n\n"
            printf "Instead, the getting output was:\n"
            printf "${getting_output_json[0]}\n\n"
		    exit 7
        fi
    fi
}


# Works
command_output_contains_copy() {
	local substring="$1"
	shift
	local command_output="$@"
	if grep -q "$substring" <<< "$command_output"; then
	#if "$command" | grep -q "$substring"; then
        read -p "FOUDN"
   		echo "FOUND"
	else
		echo "NOTFOUND"
	fi
}

# Assumed working.
string_in_lines_retry() {
    local substring="$1"
    shift
    local lines="$1"
	if [[ $lines = *"$substring"* ]] ; then
        read -p "FOUND"
        echo "FOUND"
    else
        read -p "NOTFOUND"
        echo "NOTFOUND"
    fi
}