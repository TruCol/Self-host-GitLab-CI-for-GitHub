#!/bin/bash
# Contains function that verify that the reported build statuses in the GitHub
# repository that stores the GitLab build statusses, are valid.

#######################################
# Checks whether the commit in the GitHub repository with the GitLab CI build
# status results, is valid.
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
#  FOUND - if the commit sha has a valid value.
#  NOTFOUND - if the commit sha does not have a valid value.
#######################################
# Run with: 
# bash -c 'source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && commit_build_status_txt_is_valid hiveminds renamed_test_repo no_attack_in_filecontent 51d8783648feebf7e793c010d5878e08360e856b'
# bash -c 'source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && commit_build_status_txt_is_valid hiveminds renamed_test_repo main dab083a58ab6eea71b2738bf938e076061e2b0fa'
commit_build_status_txt_is_valid(){
    local organisation="$1"
    local github_repo_name="$2"
    local github_branch_name="$3"
    local commit_sha="$4"
    

    local build_status_txt_filepath="$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$organisation/$github_repo_name/$github_branch_name/$commit_sha.txt"
    # Verify GitHub repository on which the CI is ran, exists locally.
	local build_status_txt_exists=$(file_exists "$build_status_txt_filepath")
    
    if [ "$build_status_txt_exists" != "FOUND" ]; then
        echo "NOTFOUND"
    else
        # File is found, verify it contains: "passed, pending,success,failed,.."
        local first_line=$(head -n 1 "$build_status_txt_filepath")
        local first_line_without_trailing_chars=$(echo "$first_line" | tr -d '\r')
        if [ "$first_line_without_trailing_chars" == "success" ]; then
            echo "FOUND"
        elif [ "$first_line_without_trailing_chars" == "running" ]; then
            echo "FOUND"
        elif [ "$first_line_without_trailing_chars" == "canceled" ]; then
            echo "FOUND"
        elif [ "$first_line_without_trailing_chars" == "failure" ]; then
            echo "FOUND"
        elif [ "$first_line_without_trailing_chars" == "pending" ]; then
            echo "FOUND"
        elif [ "$first_line_without_trailing_chars" == "unknown" ]; then
            echo "FOUND"
        elif [ "$first_line_without_trailing_chars" == "" ]; then
            echo "Empty build status on first line."
            echo "NOTFOUND"
        else
            echo "Invalid content:$first_line_without_trailing_chars"
            echo "NOTFOUND"
        fi
    fi
}

#######################################
# Loops over all the commit build status txts in the GitHub repository with the
# GitLab build statusses, and deletes all the txts with invalid build statusses.
# Then removes those from BOTH evaluated lists. And adds them to a "erroneous"
# list.
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
#######################################
# Run with: 
# bash -c "source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && assert_commit_build_status_txt_is_valid
delete_invalid_commit_txts(){
    echo "pass"
}

#######################################
# Verfies the GitHub repository with the GitLab CI build status results,
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
#######################################
# Run with: 
# bash -c "source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && assert_commit_build_status_txt_is_valid
assert_commit_build_status_txt_is_valid(){
    echo "pass"
}

#######################################
# Verfies the GitHub repository with the GitLab CI build status results,
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
#######################################
# Run with: 
# bash -c "source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && assert_commit_build_status_txt_is_valid
assert_all_commit_build_statusses_txts_are_valid(){
    echo "pass"
}

#######################################
# Verfies the GitHub repository with the GitLab CI build status results,
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
#######################################
# Run with: 
# bash -c "source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && assert_commit_build_status_txt_is_valid
assert_all_commits_with_gitlab_yml_have_valid_commit_status_txt(){
    echo "pass"
}

#######################################
# Verfies the GitHub repository with the GitLab CI build status results,
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
#######################################
# Run with: 
# bash -c "source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && assert_commit_build_status_txt_is_valid
assert_all_commit_build_status_txts_are_in_some_list(){
    echo "pass"
}

#######################################
# Verfies the GitHub repository with the GitLab CI build status results,
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
#######################################
# Run with: 
# bash -c "source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && assert_commit_build_status_txt_is_valid
assert_all_commit_build_status_txts_are_in_evaluated_list(){
    echo "pass"
}

#######################################
# Verfies the GitHub repository with the GitLab CI build status results,
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
#######################################
# Run with: 
# bash -c "source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && assert_commit_build_status_txt_is_valid
assert_all_commit_build_status_txts_are_in_evaluated_with_yml_list(){
    echo "pass"
}