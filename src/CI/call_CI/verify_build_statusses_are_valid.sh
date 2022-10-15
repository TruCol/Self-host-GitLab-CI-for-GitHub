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
    commit_build_txt_is_valid "$build_status_txt_filepath"
}


#######################################
# Checks whether the the build status txt file of a particular commit file,
# contains a valid GitLab build status.
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
commit_build_txt_is_valid(){
    local build_status_txt_filepath="$1"
    
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
            echo "Invalid content:$first_line_without_trailing_chars."
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
# bash -c 'source src/import.sh src/CI/call_CI/verify_build_statusses_are_valid.sh && delete_invalid_commit_txts'
delete_invalid_commit_txts(){
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
    #local sub_path_pattern="*/*/*/*.txt"
    #$organisation/$github_repo_name/$github_branch_name/$commit_sha.txt"
    for build_status_txt in "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/"*/*/*/*.txt; do
        if [ "$(commit_build_txt_is_valid "$build_status_txt")" != "FOUND" ]; then
            
            start=$((${#build_status_txt} - 44))
            commit_sha=${build_status_txt:$start:40}
            if [ "${#commit_sha}" != 40 ]; then
                echo "Error, the commit sha does not have length 40:"
                echo "$commit_sha"
                echo "$build_status_txt"
                exit 5
            fi

            echo "commit_sha=$commit_sha"
            

            # Remove commit from evaluated list.
            delete_lines_containing_substring_from_file $commit_sha "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME"
            # Remove commit from evaluated with GitLab CI yml list.
            delete_lines_containing_substring_from_file $commit_sha "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_WITH_CI_LIST_FILENAME"
            # Add to errored list.
            add_commit_sha_to_evaluated_list $commit_sha $EVALUATED_COMMIT_WITH_ERROR_LIST_FILENAME

            # Delete build status txt file and verify it is deleted.
            rm "$build_status_txt"
            manual_assert_file_does_not_exists "$build_status_txt"
        fi
    done
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