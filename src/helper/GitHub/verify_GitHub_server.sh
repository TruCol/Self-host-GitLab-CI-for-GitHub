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
        echo "empty: $getting_output_json."
        exit 5
    else
        # Extract the urls from the json response.
        local urls_in_json="$(echo "${getting_output_json[0]}" | jq ".[].url")"

        # Verify the expected url and state are found in the GitHub response.
        local found_urls="$(string_in_lines "$expected_url" "${urls_in_json}")"
	    local found_state="$(string_in_lines "$expected_state" "${getting_output_json}")"
        
        if [ "$found_urls" != "FOUND" ]; then
            # shellcheck disable=SC2059
		    printf "Error, GitHub commit status Get request did not contain the"
            printf "expected url:$expected_url \n"
            printf "Instead, the getting output was: $getting_output"
		    exit 6
        elif [ "$found_state" != "FOUND" ]; then
            echo "Error, the status of the repo did not contain:$expected_state"
            echo "Instead, we found:$getting_output_json"
		    exit 7
        fi
    fi           
}