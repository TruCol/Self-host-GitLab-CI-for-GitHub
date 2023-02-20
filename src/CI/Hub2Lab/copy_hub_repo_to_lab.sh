#!/bin/bash


#######################################
# Copies a complete GitHub repository into GitLab.
#
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
# TODO(a-t-0): Write tests for this method.
#######################################
# Run with: 
# bash -c "source src/import.sh src/CI/call_CI/run_ci_on_github_repo.sh && copy_github_commits_with_yaml_to_gitlab_repo hiveminds renamed_test_repo main b0964a97eb82a3ff533548202b6eecc477039dbb hiveminds"
copy_github_repo_into_gitlab() {
	local github_username="$1"
	local github_repo_name="$2"
	
	# Verify GitHub repository on which the CI is ran, exists locally.
	manual_assert_dir_exists "$MIRROR_LOCATION/GitHub/$github_repo_name"
	# TODO: Assert GitHub build status repository exists.

	# Remove the GitLab repository. # TODO: move this to each branch
	# Similarly for each commit
	remove_the_gitlab_repository_on_which_ci_is_ran

	github2gitlab \
   --gitlab-url http://127.0.0.1 \
   --gitlab-token fe48f5e047397052fdad \
   --github-repo a-t-0/sponsor_example
}
