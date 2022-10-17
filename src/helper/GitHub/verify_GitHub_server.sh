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
    
    echo "github_username=$github_username"
	echo "github_repo_name=$github_repo_name"
	echo "github_commit_sha=$github_commit_sha"
	echo "commit_build_status=$commit_build_status"

    # Specify how many retries are allowed.
    local nr_of_retries=6
    local termination_limit="$((nr_of_retries-2))"
    local i="0"

    while [ $i -lt $nr_of_retries ]; do
        local found_valid_build_status="$(github_build_status_is_set_correctly "$github_username" "$github_repo_name" "$github_commit_sha" "$commit_build_status")"
        i=$[$i+1]
        if [ "$found_valid_build_status" == "FOUND" ]; then
            echo "FOUND IT"
            break
        elif [[ "$i" == "$termination_limit" ]]; then
            echo "DID NOT FIND IT, now ASSERTING"
            assert_github_build_status_is_set_correctly "$github_username" "$github_repo_name" "$github_commit_sha" "$commit_build_status"
            break
        fi
        sleep 4
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
    local expected_url_with_quotations='"'"https://api.github.com/repos/$github_username/$github_repo_name/statuses/$github_commit_sha"'"'
    #local expected_state='"'"\"state\":\"$commit_build_status\","
    local expected_state_with_quotations='"'"$commit_build_status"'"'

    # Get the json containing the GitHub build statusses.
    local getting_output_json=$(GET https://api.github.com/repos/"$github_username"/"$github_repo_name"/commits/"$github_commit_sha"/statuses)
        
    # Verify the build status json/response is not empty.
    if [ "$getting_output_json" == "" ] || [ "$getting_output_json" == " " ] || [ "$getting_output_json" == "[]" ]; then
        printf "Error, the output of getting the GitHub commit build status is empty:\n"
        printf "$getting_output_json.\n"
        exit 5
    else
        # Extract the urls from the json response and get the first url.
        local urls_in_json="$(echo "${getting_output_json[0]}" | jq ".[].url")"
        for word in $urls_in_json
        do
            local first_url_in_json=$word
            break
        done
        # Get the commit form the first url from the json response.
        local commit_of_first_url_with_end_quotation=${first_url_in_json: -41}
        local commit_of_first_url=${commit_of_first_url_with_end_quotation:0:40}

        # Verify the GitHub resonse concerns the right commit.
        if [ "$github_commit_sha" != "$commit_of_first_url" ]; then
            read -p "Different urls:"
            read -p "$expected_url_with_quotations"
            read -p "$first_url_in_json"
            exit 6
        fi
        
        # Extract the states from the json response and get the first state.
        local state_in_json="$(echo "${getting_output_json[0]}" | jq ".[].state")"
        for word in $state_in_json
        do
            local first_state_in_json=$word
            break
        done
        
        # Verify the GitHub resonse has the expected build status.
        if [ "$expected_state_with_quotations" != "$first_state_in_json" ]; then
            read -p "Different states:"
            read -p "$expected_state_with_quotations"
            read -p "$first_state_in_json"
		    exit 6
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
    local expected_url_with_quotations='"'"https://api.github.com/repos/$github_username/$github_repo_name/statuses/$github_commit_sha"'"'
    #local expected_state='"'"\"state\":\"$commit_build_status\","
    local expected_state_with_quotations='"'"$commit_build_status"'"'

    # Get the json containing the GitHub build statusses.
    local getting_output_json=$(GET https://api.github.com/repos/"$github_username"/"$github_repo_name"/commits/"$github_commit_sha"/statuses)
        
    # Verify the build status json/response is not empty.
    if [ "$getting_output_json" == "" ] || [ "$getting_output_json" == " " ] || [ "$getting_output_json" == "[]" ]; then
        echo "NOTFOUND"
    else
        # Extract the urls from the json response and get the first url.
        local urls_in_json="$(echo "${getting_output_json[0]}" | jq ".[].url")"
        for word in $urls_in_json
        do
            local first_url_in_json=$word
            break
        done
        # Get the commit form the first url from the json response.
        local commit_of_first_url_with_end_quotation=${first_url_in_json: -41}
        local commit_of_first_url=${commit_of_first_url_with_end_quotation:0:40}

        
        
        # Extract the states from the json response and get the first state.
        local state_in_json="$(echo "${getting_output_json[0]}" | jq ".[].state")"
        for word in $state_in_json
        do
            local first_state_in_json=$word
            break
        done
        # Verify the expected url and state are found in the GitHub response.
        if [ "$expected_state_with_quotations" == "$first_state_in_json" ] && [ "$github_commit_sha" == "$commit_of_first_url" ]; then
		    echo "FOUND"
        
        # Verify the GitHub resonse concerns the right commit.
        elif [ "$github_commit_sha" != "$commit_of_first_url" ]; then
            echo "NOTFOUND"
        # Verify the GitHub resonse has the expected build status.
        elif [ "$expected_state_with_quotations" != "$first_state_in_json" ]; then
            echo "NOTFOUND"
        fi
    fi
}