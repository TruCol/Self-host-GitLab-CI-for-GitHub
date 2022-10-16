#!/bin/bash
# Contains code that is used to verify certain aspects on the GitHub server 
# side.

#######################################
# Asserts the build status is set correctly on a GitHub commit.
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
# TODO: Implement a retry, in case of network issues.  
#######################################
# Run with:
# bash -c 'source src/import.sh && assert_github_build_status_is_set_correctly a-t-0 sponsor_example 02c5fce3500d7b9e2d79cb5b7d886020a403cf58 pending'
# bash -c 'source src/import.sh && assert_github_build_status_is_set_correctly HiveMinds gitlab-ci-multi-runner be2559e534f87377a02faf9f6144e63fbc58f018 pending'
# bash -c 'source src/import.sh && assert_github_build_status_is_set_correctly HiveMinds gitlab-ci-multi-runner be2559e534f87377a02faf9f6144e63fbc58f018 failure'
assert_github_build_status_is_set_correctly() {
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
    if [ "$getting_output_json" == "" ] || [ "$getting_output_json" == " " ]; then
        echo "Error, the output of getting the GitHub commit build status is"
        echo "empty:$getting_output_json."
        exit 5
    else
        # Extract the urls from the json response.
        local urls_in_json="$(echo "${getting_output_json[0]}" | jq ".[].url")"
        local state_in_json="$(echo "${getting_output_json[0]}" | jq ".[].state")"
        echo "urls_in_json=$urls_in_json"
        echo "state_in_json=$state_in_json"

        local expected_url_entry='"url":"'"$expected_url"'",'
        local expected_state_entry='"state":"'"$commit_build_status"'",'
        echo "expected_url_entry=$expected_url_entry"
        echo "expected_state_entry=$expected_state_entry"
        echo "getting_output_json0=${getting_output_json[0]}"
        local found_url_entry="$(string_in_lines "$expected_url_entry" "${getting_output_json[0]}")"
        local found_state_entry="$(string_in_lines "$expected_state_entry" "${getting_output_json[0]}")"
        echo "found_url_entry=$found_url_entry"
        echo "found_state_entry=$found_state_entry"

        # Verify the expected url and state are found in the GitHub response.
        local found_urls="$(string_in_lines "$expected_url" "${urls_in_json}")"
	    local found_state="$(string_in_lines "$expected_state" "${getting_output_json}")"
        
        if [ "$found_urls" != "FOUND" ]; then
            # shellcheck disable=SC2059
		    printf "Error, GitHub commit status Get request did not contain the"
            printf "expected url:"
            printf "$expected_url"
            printf "Instead, the getting output was:"
            printf "$getting_output_json"
            printf "And urls_in_json="
            printf "$urls_in_json."
		    exit 6
        elif [ "$found_state" != "FOUND" ]; then
            printf "Error, the status of the repo did not contain:$expected_state"
            printf "expected url:"
            printf "$expected_url"
            printf "Instead, the getting output was:"
            printf "$getting_output_json"
            printf "And urls_in_json="
            printf "$urls_in_json"
            printf "Instead, and urls_in_json=$found_state."
		    exit 7
        fi
    fi           
}