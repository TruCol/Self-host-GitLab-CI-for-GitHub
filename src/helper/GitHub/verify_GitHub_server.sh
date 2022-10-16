#!/bin/bash
# Contains code that is used to verify certain aspects on the GitHub server 
# side.

# Tries to verify the GitHub commit build status 5 times, if no valid build
# status is found, it throws an error.
# bash -c 'source src/import.sh && manage_github_build_status_check HiveMinds gitlab-ci-multi-runner 907cfa5e0682e938691ba5f5d665ff8147833a89 failure'
manage_github_build_status_check(){
    local github_username="$1"
	local github_repo_name="$2"
	local github_commit_sha="$3"
	local commit_build_status="$4"
    
    # Specify how many retries are allowed.
    local nr_of_retries=6
    local termination_limit="$((nr_of_retries-2))"
    local i="0"

    while [ $i -lt $nr_of_retries ]; do
        local found_valid_build_status="$(github_build_status_is_set_correctly "$github_username" "$github_repo_name" "$github_commit_sha" "$commit_build_status")"
        i=$[$i+1]
        if [ "$found_valid_build_status" == "FOUND" ]; then
            break
        elif [[ "$i" == "$termination_limit" ]]; then
            assert_github_build_status_is_set_correctly "$github_username" "$github_repo_name" "$github_commit_sha" "$commit_build_status"
            break
        fi
    done
}

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
# bash -c 'source src/import.sh && assert_github_build_status_is_set_correctly HiveMinds gitlab-ci-multi-runner 907cfa5e0682e938691ba5f5d665ff8147833a89 failure'
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
    if [ "$getting_output_json" == "" ] || [ "$getting_output_json" == " " ] || [ "$getting_output_json" == "[]" ]; then
        printf "Error, the output of getting the GitHub commit build status is empty:\n"
        printf "$getting_output_json.\n"
        exit 5
    else
        # Extract the urls from the json response.
        local urls_in_json="$(echo "${getting_output_json[0]}" | jq ".[].url")"
        local state_in_json="$(echo "${getting_output_json[0]}" | jq ".[].state")"
        
        local expected_url_entry='"url":"'"$expected_url"'",'
        local expected_state_entry='"state":"'"$commit_build_status"'",'

        local found_url_entry="$(string_in_lines "$expected_url_entry" "${getting_output_json[0]}")"
        local found_state_entry="$(string_in_lines "$expected_state_entry" "${getting_output_json[0]}")"
        
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

# bash -c 'source src/import.sh && github_build_status_is_set_correctly HiveMinds gitlab-ci-multi-runner 907cfa5e0682e938691ba5f5d665ff8147833a89 failure'
github_build_status_is_set_correctly(){
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
        echo "NOTFOUND"
    else
        # Extract the urls from the json response.
        local urls_in_json="$(echo "${getting_output_json[0]}" | jq ".[].url")"
        local state_in_json="$(echo "${getting_output_json[0]}" | jq ".[].state")"
        
        local expected_url_entry='"url":"'"$expected_url"'",'
        local expected_state_entry='"state":"'"$commit_build_status"'",'

        local found_url_entry="$(string_in_lines "$expected_url_entry" "${getting_output_json[0]}")"
        local found_state_entry="$(string_in_lines "$expected_state_entry" "${getting_output_json[0]}")"
        
        # Verify the expected url and state are found in the GitHub response.
        if [ "$found_url_entry" != "FOUND" ]; then
		    echo "NOTFOUND"
        elif [ "$found_state_entry" != "FOUND" ]; then
            echo "NOTFOUND"
        elif [ "$found_url_entry" == "FOUND" ] && [ "$found_state_entry" == "FOUND" ]; then
            echo "FOUND"
        fi
    fi
}