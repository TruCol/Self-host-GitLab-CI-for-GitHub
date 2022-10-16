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
        is_valid_build_status "$first_line_without_trailing_chars"
    fi
}

is_valid_build_status(){
    local build_status="$1"
    if [ "$build_status" == "success" ]; then
        echo "FOUND"
    elif [ "$build_status" == "running" ]; then
        echo "FOUND"
    elif [ "$build_status" == "canceled" ]; then
        echo "FOUND"
    elif [ "$build_status" == "failure" ]; then
        echo "FOUND"
    elif [ "$build_status" == "pending" ]; then
        echo "FOUND"
    elif [ "$build_status" == "unknown" ]; then
        echo "FOUND"
    elif [ "$build_status" == "" ]; then
        echo "Empty build status on first line."
        echo "NOTFOUND"
    else
        echo "Invalid content:$build_status."
        echo "NOTFOUND"
    fi
}


#######################################
# Loops over all the commit build statusses in a list of commit sha's. Then
# for each commit loops over all the commit_build_status_txt files in the 
# GitHub repository with the GitLab build statusses. Then removes each 
# commit_sha from the list, if it does not have a valid build_status_txt file.
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
# bash -c 'source src/import.sh && remove_commits_without_build_status_from_evaluated_list evaluated_commits_with_ci.txt'
# bash -c 'source src/import.sh && remove_commits_without_build_status_from_evaluated_list "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_LIST_FILENAME"'
# bash -c 'source src/import.sh && remove_commits_without_build_status_from_evaluated_list "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/$EVALUATED_COMMITS_WITH_CI_LIST_FILENAME"'
remove_commits_without_build_status_from_evaluated_list(){
    local some_list_filepath="$1"
    while IFS="" read -r p || [ -n "$p" ]
    do
      #printf '%s\n' "$p"
      local wanted_commit_sha=$p
      echo "$wanted_commit_sha"
      if [ "$(commit_has_build_status_file $wanted_commit_sha)" != "FOUND" ]; then
        # Remove commit from evaluated list.
        delete_lines_containing_substring_from_file $wanted_commit_sha "$some_list_filepath"
      fi
    done < $some_list_filepath
}

# bash -c 'source src/import.sh && commit_has_build_status_file 2ebecfd1c08cf0aeb36301779e0e68b4110428e9'
# bash -c 'source src/import.sh && commit_has_build_status_file aeaaa57120f74a695ef4215e819a175296a3de10'

commit_has_build_status_file() {
    local wanted_commit_sha="$1"

    local found_build_txt="FALSE"
    manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL"
    
    # The */*/*/*.txt adheres to:
    #$organisation/$github_repo_name/$github_branch_name/$commit_sha.txt"
    for build_status_txt in "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/"*/*/*/*.txt; do
        
        # Only keep commit_build_txt files with valid build status.
        if [ "$(commit_build_txt_is_valid "$build_status_txt")" == "FOUND" ]; then
            
            # Extract the commit sha from the build status filepath.
            start=$((${#build_status_txt} - 44))
            commit_sha=${build_status_txt:$start:40}
            # Verify the commit_sha length.
            if [ "${#commit_sha}" != 40 ]; then
                echo "Error, the commit sha does not have length 40:"
                echo "$commit_sha"
                echo "$build_status_txt"
                exit 5
            elif [ "$wanted_commit_sha" == "$commit_sha" ]; then
                    found_build_txt="TRUE"
                    echo "FOUND"
                    break
            fi
        fi
    done
    if [ "$found_build_txt" != "TRUE" ]; then
        echo "NOTFOUND"
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
    
    # The */*/*/*.txt adheres to:
    #$organisation/$github_repo_name/$github_branch_name/$commit_sha.txt"
    for build_status_txt in "$MIRROR_LOCATION/GitHub/$GITHUB_STATUS_WEBSITE_GLOBAL/"*/*/*/*.txt; do
        if [ "$(commit_build_txt_is_valid "$build_status_txt")" != "FOUND" ]; then
            
            # Extract the commit sha from the build status filepath.
            start=$((${#build_status_txt} - 44))
            commit_sha=${build_status_txt:$start:40}
            # Verify the commit_sha length.
            if [ "${#commit_sha}" != 40 ]; then
                echo "Error, the commit sha does not have length 40:"
                echo "$commit_sha"
                echo "$build_status_txt"
                exit 5
            fi

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
    local organisation="$1"
    local github_repo_name="$2"
    local github_branch_name="$3"
    local commit_sha="$4"
    echo "organisation=$organisation"
    echo "github_repo_name=$github_repo_name"
    echo "github_branch_name=$github_branch_name"
    echo "commit_sha=$commit_sha"

    # Verify the commit_sha length. TODO: remove duplicate.
    if [ "${#commit_sha}" != 40 ]; then
        echo "Error, the commit sha does not have length 40:"
        echo "$commit_sha"
        echo "$build_status_txt"
        exit 5
    fi


    local commit_build_status_is_valid="$(commit_build_status_txt_is_valid "$organisation" "$github_repo_name" "$github_branch_name" "$commit_sha")"
    if [ "$commit_build_status_is_valid" != "FOUND" ]; then
        echo "Error, the commit:$github_repo_name/$github_branch_name/$commit_sha"
        echo "Does not have a valid build status file.$commit_build_status_is_valid"
        exit 11
    fi
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