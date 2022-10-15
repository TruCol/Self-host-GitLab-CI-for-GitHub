#!/bin/bash
# A file that contains functions to make modifications to GitLab
# repositories.

#######################################
# Structure:Configuration
# Returns the GitLab installation package name that matches the architecture
# of the device on which it is installed. Not every package/GitLab source 
# repository works on each computer/architecture. Currently working GitLab
# installation packages have only been found for the amd64 architecture and
# the RaspberryPi 4b architectures have been verified.
# Local variables:
#  architecture
# Globals:
#  None.
# Arguments:
#  None.
# Returns:
#  0 if the GitLab release was found correctly.
#  7 if  
# Outputs:
#  The GitLab release name for the architecture of this device.
#######################################
# TODO: verify if architecture is supported, raise error if not
# TODO: Mention that support for the architecture can be gained by
# downloading the right GitLab Runner installation package and adding
# its verified md5sum into hardcoded_variables.txt (possibly adding an if statement 
# to get_architecture().)
get_gitlab_package() {
	local architecture=$(dpkg --print-architecture)
	if [ "$architecture" == "amd64" ]; then
		echo "$GITLAB_DEFAULT_PACKAGE"
	elif [ "$architecture" == "armhf" ]; then
		echo "$GITLAB_RASPBERRY_PACKAGE"
	fi
}

#######################################
# Deletes the repository if it doesn't exist in the GitLab server.
# Local variables:
#  deleted_repo_is_found
#  gitlab_repo_name
# Globals:
#  None.
# Arguments:
#   Name of the GitLab repository.
# Returns:
#  0 if funciton was evaluated succesfull.
#  7 if the repository was not found.
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
delete_gitlab_repo_if_it_exists() {
  local gitlab_repo_name="$1"

  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
    assert_equal "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" "NOTFOUND"
  elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
    # TODO(a-t-0): change root with Global variable.
    delete_existing_repository "$gitlab_repo_name" "root"
    sleep 5
    local deleted_repo_is_found
	deleted_repo_is_found="$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")"
    assert_equal "$deleted_repo_is_found" "NOTFOUND"
  else
    echo "The repository was not NOTFOUND, nor was it FOUND. "
    exit 7
  fi
}


#######################################
# Determines if the GitLab repository exists locally.
# Local variables:
#  gitlab_repo_name
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  The GitLab repository name.
# Returns:
#  0 if funciton was evaluated succesfull.
# Outputs:
#  FOUND if the GitLab repository exist locally in the mirror location and
#  NOTFOUND if the GitLab repository doesn't exist there.
#######################################
gitlab_repo_exists_locally(){
  local gitlab_repo_name="$1"
  if test -d "$MIRROR_LOCATION/GitLab/$gitlab_repo_name"; then
    echo "FOUND"
  else
    echo "NOTFOUND"
  fi
}


#######################################
# Determines whether the GitLab repository name exists in the GitLab server or
# locally. If it is not found locally, a clone of the GitLab repository is made.
# Local variables:
#  gitlab_username
#  gitlab_repo_name
# Globals:
#  MIRROR_LOCATION
#  GITLAB_SERVER
#  GITLAB_SERVER_ACCOUNT_GLOBAL
#  GITLAB_SERVER_PASSWORD_GLOBAL
# Arguments:
#  The GitLab username.
#  The GitLab repository name.
# Returns:
#  0 if function was evaluated succesfull.
#  8 if mirror directory was not found locally.
#  9 if GitLab repository was not found in the GitLab server.
#  10 if GitLab repository was not found locally and not cloned to the mirror
#  location.
# Outputs:
#  FOUND if the GitLab repository exist in the GitLab server or locally in the
#  mirror location.
#  NOTFOUND if the GitLab repository doesn't exist in the GitLab server or
#  locally.
# TODO(a-t-0): verify local GitLab mirror repo directories are created.
# TODO(a-t-0): verify the repository exists in GitLab, throw error otherwise.
# TODO(a-t-0): do a gitlab pull to get the latest version.
# TODO(a-t-0): Change the use of MIRROR_LOCATION to local input argument.
# TODO(a-t-0): Change the use of GITLAB_SERVER to local input argument.
# TODO(a-t-0): Change the use of GITLAB_SERVER_ACCOUNT_GLOBAL to local input argument.
# TODO(a-t-0): Change the use of GITLAB_SERVER_PASSWORD_GLOBAL to local input argument.
#######################################
get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab() {
  local gitlab_username="$1"
  local gitlab_repo_name="$2"
  

  # TODO(a-t-0): verify local gitlab mirror repo directories are created
  create_mirror_directories

  if [ "$(verify_mirror_directories_are_created)" != "FOUND" ]; then
    echo "ERROR, the GitLab repository was not found locally."
    exit 8
  # TODO(a-t-0): verify the repository exists in GitLab, throw error otherwise.
  elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
    echo "ERROR, the GitLab repository was not found in the GitLab server."
    exit 9
  else
    if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "NOTFOUND" ]; then
      # shellcheck disable=SC2153
	    clone_repository "$gitlab_repo_name" "$gitlab_username" "$GITLAB_SERVER_PASSWORD_GLOBAL" "$GITLAB_SERVER" "$MIRROR_LOCATION/GitLab/"
      manual_assert_equal "$(gitlab_repo_exists_locally "$gitlab_repo_name")" "FOUND"
    elif [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
      echo "FOUND"
      # TODO(a-t-0): do a gitlab pull to get the latest version.
    else
      echo "ERROR, the GitLab repository was not found locally and not cloned."
      exit 10
    fi
  fi
}


#######################################
# Performs a git pull inside the GitLab repository if the GitLab repository
# exists locally.
# Local variables:
#  gitlab_repo_name
#  pwd_before
#  pwd_àfter
# Globals:
#  MIRROR_LOCATION
# Arguments:
#   Name of the GitLab repository.
# Returns:
#  0 if funciton was evaluated succesfull.
#  111 if the current path has't returned to what it origally was.
#  12 if the GitLab repository was not found locally.
# Outputs:
#  FOUND if the GitLab repository exist locally.
#######################################
git_pull_gitlab_repo() {
  gitlab_repo_name="$1"
  if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

    # Get the path before executing the command (to verify it is restored
	# correctly after).
    local pwd_before
	pwd_before="$PWD"

    # Do a git pull inside the gitlab repository.
    cd "$MIRROR_LOCATION/GitLab/$gitlab_repo_name" && git pull
    cd ../../..

    # Get the path after executing the command (to verify it is restored
	# correctly after).
    local pwd_after
	pwd_after="$PWD"

    # Verify the current path is the same as it was when this function started.
    if [ "$pwd_before" != "$pwd_after" ]; then
      echo "The current path is not returned to what it originally was."
      exit 111
    fi
  else
    echo "ERROR, the GitLab repository does not exist locally."
    exit 12
  fi
}


# Structure:gitlab_status
#6.d.1 If the GItHub branch already exists in the GItLab mirror repository does not yet exist, create it.
# source src/import.sh src/helper/GitLab/helper_gitlab_modify.sh && ensure_new_empty_repo_is_created_in_gitlab "sponsor_example" "root"
##run:
# bash -c "source src/import.sh src/helper/GitLab/helper_gitlab_modify.sh && ensure_new_empty_repo_is_created_in_gitlab sponsor_example root"
#######################################
# Checks for a repository in the GitLab server and deletes it if it exists.
# Afterwards, a new empty repository is created.
# How to run:
#  source src/import.sh src/helper/GitLab/helper_gitlab_modify.sh && ensure_new_empty_repo_is_created_in_gitlab "sponsor_example" "root"
# Local variables:
#  gitlab_repo_name
#  gitlab_username
# Globals:
#  GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL
#  MIRROR_LOCATION
#  GITLAB_SERVER_HTTP_URL
# Arguments:
#   Name of the GitLab repository.
#   The GitLab username.
# Returns:
#  0 if funciton was evaluated succesfull.
#  177 if the repository was supposed to be deleted but still exist.
#  178 if the repository was supposed to be created but doesn't exist.
# Outputs:
#  None.
# TODO(a-t-0): Check if GitLab server is running.
# TODO(a-t-0): Capitalize $personal_access_token in all files.
# TODO(a-t-0): Localize $GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL as an argument.
#######################################
# run with:
# bash -c 'source src/import.sh src/helper/GitLab/helper_gitlab_modify.sh && ensure_new_empty_repo_is_created_in_gitlab new_repo root'
ensure_new_empty_repo_is_created_in_gitlab() {
  local gitlab_repo_name="$1"
  local gitlab_username="$2"

   # load personal_access_token (from hardcoded data)
    local personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')

  # TODO(a-t-0): Check if GitLab server is running.

  # Check if repository already exists in GitLab server.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then

    # If it already exists, delete the repository
    delete_existing_repository "$gitlab_repo_name" "$gitlab_username"
    printf "\n Waiting 30 secs untill repo is deleted from GitLab server."
    sleep 30
    # TODO: replace this with a while loop that waits until the repo is deleted.

    # Verify the repository is deleted.
    if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
      # Throw an error if it is not deleted.
      echo "The GitLab repository was supposed to be deleted, yet it still exists."
      exit 177
    fi
  fi

  # Create repository.
  curl --silent -H "Content-Type:application/json" "$GITLAB_SERVER_HTTP_URL/api/v4/projects?private_token=$personal_access_token" -d "{ \"name\": \"$gitlab_repo_name\" }"  > /dev/null 2>&1 &
  sleep 30
  printf "\n Waiting 30 secs untill repo is (re)created in GitLab server."

  # Verify the repository is created.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" != "FOUND" ]; then
    # Throw an error if it is not created succesfully.
    echo "The GitLab repository was supposed to be created, yet it does not yet exists."
    exit 178
  fi
}


#######################################
# Checks if repository exists in the GitLab server and creates a new empty 
# repository if it does not yet exist.
# Local variables:
#  gitlab_repo_name
#  gitlab_username
# Globals:
#  None.
# Arguments:
#  Name of the GitLab repository.
#  The GitLab username.
# Returns:
#  0 if funciton was evaluated succesfull.
#  179 if the GitLab repository name was not found and has not been determined
#  if it exist.
#  180 if the repository was supposed to be created but doesn't exist.
# Outputs:
#  None.
#######################################
create_gitlab_repository_if_not_exists() {
  local gitlab_repo_name="$1"
  local gitlab_username="$2"

  # Check if repository already exists in GitLab server.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
    ensure_new_empty_repo_is_created_in_gitlab "$gitlab_repo_name" "$gitlab_username"
  elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
    echo ""
  else
    echo "ERROR, the GitLab repository: $gitlab_repo_name is not found, nor is
	it determined that it does not exist."
    exit 179
  fi

  # Verify the repository exists.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" != "FOUND" ]; then
    # Throw an error if it is not created succesfully.
    echo "The GitLab repository was supposed to be created, yet it does not yet
	exists."
    exit 180
  fi
}


#######################################
# Checks if repository exists in the GitLab server and deletes the GitLab
# repository if it exists.
# Local variables:
#  gitlab_repo_name
#  gitlab_username
# Globals:
#  None.
# Arguments:
#  Name of the GitLab repository.
#  The GitLab username.
# Returns:
#  0 if funciton was evaluated succesfull.
#  181 if the GitLab repository name was not found and has not been determined
#  if it exist.
#  182 if the repository was supposed to be created but doesn't exist.
# Outputs:
#  None.
#######################################
delete_gitlab_repository_if_it_exists() {
  local gitlab_repo_name="$1"
  local gitlab_username="$2"

  # Check if repository already exists in GitLab server.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
    echo ""
  elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
    # If it exists, delete the repository.
    delete_existing_repository "$gitlab_repo_name" "$gitlab_username"
    sleep 30
  else
    echo "ERROR, the GitLab repository: $gitlab_repo_name is not found, nor is it determined that it does not exist."
    exit 181
  fi

  # Verify the repository does not exists.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" != "NOTFOUND" ]; then
    # Throw an error if it is not created succesfully.
    echo "The GitLab repository was supposed to be created, yet it does not yet exists."
    exit 182
  fi
}


#######################################
# Checks if repository exists in the GitLab server and deletes it. Otherwise, an  
# error is shown.
# How to run:
#  source src/import.sh src/helper/GitLab/helper_gitlab_modify.sh && delete_existing_repository 
#  "sponsor_example" "root"
# Local variables:
#  gitlab_repo_name
#  gitlab_username
#  personal_access_token
# Globals:
#  GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL
#  GITLAB_SERVER_HTTP_URL
# Arguments:
#  Name of the GitLab repository.
#  The GitLab username.
# Returns:
#  0 if funciton was evaluated succesfull.
#  183 if an attempt was made to delete a GitLab repository that did not exist.
# Outputs:
#  None.
#######################################
# run with:
# bash -c 'source src/import.sh src/helper/GitLab/helper_gitlab_modify.sh && delete_existing_repository new_repo root'
delete_existing_repository() {
  local repo_name="$1"
  local repo_username="$2"

  # load personal_access_token
  local personal_access_token
  personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN_GLOBAL" | tr -d '\r')

  local output
  output=$(curl --silent -H 'Content-Type: application/json' -H "Private-Token: $personal_access_token" -X DELETE "$GITLAB_SERVER_HTTP_URL"/api/v4/projects/"$repo_username"%2F"$repo_name")

  if [  "$(lines_contain_string '{"message":"404 Project Not Found"}' "${output}")" == "FOUND" ]; then
    echo "ERROR, you tried to delete a GitLab repository that does not exist."
    exit 183
  fi
}

#
#######################################
# Clones the GitLab repository into the GitLab mirror storage location.
# How to run:
#  source src/run_ci_job.sh && clone_repository
# Local variables:
#  gitlab_repo_name
#  gitlab_username
#  GITLAB_SERVER_PASSWORD_GLOBAL
#  gitlab_server
#  target_directory
#  output
# Globals:
#  None.
# Arguments:
#  Name of the GitLab repository.
#  The GitLab username.
#  The GitLab server password.
#  The GitLab server.
#  The target directory.
# Returns:
#  None.
# Outputs:
#  None.
# TODO (a-t-0): write test to verify the gitlab username and server don't end with a spacebar character.
# TODO (a-t-0): rename to clone_gitlab_repository_from _local_server.
#######################################
clone_repository() {
  local repo_name=$1
  local gitlab_username=$2
  local local_gitlab_server_password=$3
  local gitlab_server=$4
  local target_directory=$5

  # TODO:write test to verify the gitlab username and server don't end with a spacebar character.

  # Clone the GitLab repository into the GitLab mirror storage location.
  output=$(cd "$target_directory" && git clone http://$gitlab_username:$local_gitlab_server_password@$gitlab_server/$gitlab_username/$repo_name.git)
}


# Structure:gitlab_modify
# 6.f.0 Checkout that branch in the local GitHub mirror repository.
#######################################
# Checks if a GitHub repository exists locally. If so, the branch path is 
# verified before and after the command has been executed to check if the
# branch path has changed. if the path has changed, an error is shown.
# Local variables:
#  github_repo_name
#  github_branch_name
#  company
#  pwd_before
#  pwd_after
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  The GitHub repository name.
#  The GitHub branch name.
#  The company.
#  The path before the iniziation of a function.
#  The path after the iniziation of a function.
# Returns:
#  0 if funciton was evaluated succesfull.
#  15 if the current path was not returned to what it origally was before the function 
#  was activated.
#  16 if the GitHub branch did not exist locally before the function started.
#  172 if the GitHub repository did not exist locally before the function started.
# Outputs:
#  None.
#######################################
checkout_branch_in_github_repo() {
  local github_repo_name="$1"
  local github_branch_name="$2"
  local company="$3"

  if [ "$(github_repo_exists_locally $github_repo_name)" == "FOUND" ]; then

    # Verify the branch exists
    branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
    github_branch_is_found=$(assert_ends_in_found_and_not_in_notfound ${branch_check_result})

    if [ "$github_branch_is_found" == "TRUE" ]; then
      # Get the path before executing the command (to verify it is restored correctly after).
      local pwd_before
	    pwd_before="$PWD"

      # Checkout the branch inside the repository.
      cd "$MIRROR_LOCATION/$company/$github_repo_name" && git checkout "$github_branch_name"
      cd ../../../..
      # Get the path after executing the command (to verify it is restored correctly after).
      local pwd_after
	    pwd_after="$PWD"

      # Test to verify the current branch in the GitHub repository is indeed
      # checked out.
      # TODO: check if this passes
      assert_current_github_branch "$github_repo_name" "$github_branch_name"


      # Verify the current path is the same as it was when this function started.
      if [ "$pwd_before" != "$pwd_after" ]; then
        echo "The current path is not returned to what it originally was."
        #echo "pwd_before=$pwd_before"
        #echo "pwd_after=$pwd_after"
        exit 15
      fi
    elif [ "$(github_repo_exists_locally $github_repo_name)" == "NOTFOUND" ]; then
      read -p "ERROR, the GitHub branch:$github_branch_name does not exist locally."
      exit 16 
    else
      read -p "ERROR, function github_branch_exists did not return a valid branch name."
      exit 17
    fi
  else
    echo "ERROR, the GitHub repository does not exist locally."
    exit 172
  fi
}

#######################################
# Checks if a GitHub repository exists locally. If so, the branch path is 
# verified before and after the command has been executed to check if the
# branch path has changed. if the path has changed, an error is shown.
# Local variables:
#  github_repo_name
#  github_branch_name
#  company
#  pwd_before
#  pwd_after
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  The GitHub repository name.
#  The GitHub branch name.
#  The company.
#  The path before the iniziation of a function.
#  The path after the iniziation of a function.
# Returns:
#  0 if funciton was evaluated succesfull.
#  15 if the current path was not returned to what it origally was before the function 
#  was activated.
#  16 if the GitHub branch did not exist locally before the function started.
#  172 if the GitHub repository did not exist locally before the function started.
# Outputs:
#  None.
#######################################
checkout_commit_in_github_repo() {
  local github_repo_name="$1"
  local github_commit_sha="$2"
  local company="$3"

  if [ "$(github_repo_exists_locally $github_repo_name)" == "FOUND" ]; then

    # Get the path before executing the command (to verify it is restored correctly after).
    local pwd_before
    pwd_before="$PWD"

    # Checkout the branch inside the repository.
    cd "$MIRROR_LOCATION/$company/$github_repo_name" && git checkout "$github_commit_sha"
    cd ../../../..
    # Get the path after executing the command (to verify it is restored correctly after).
    local pwd_after
    pwd_after="$PWD"

    # Verify the current path is the same as it was when this function started.
    if [ "$pwd_before" != "$pwd_after" ]; then
      echo "The current path is not returned to what it originally was."
      #echo "pwd_before=$pwd_before"
      #echo "pwd_after=$pwd_after"
      exit 15
    fi
  else
    echo "ERROR, the GitHub repository does not exist locally."
    exit 172
  fi
}


# Structure:gitlab_modify
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# 6.h.1 Checkout that branch in the local GitLab mirror repository if it exists.
# 6.h.2 If the branch does not exist in the GitLab repo, create it.
# 6.h.0 Checkout that branch in the local GitLab mirror repository. (Assuming the GitHub branch contains a gitlab yaml file)
#######################################
# Checks if the desired branch exists in GitLab. Afterwards, the path before 
# and after the function has started to verify if the path is restored correctly.  
# If a branch is not found in the repository a nw one is created
# Local variables:
#  github_repo_name
#  github_branch_name
#  company
#  pwd_before
#  pwd_after
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  The GitHub repository name.
#  The GitHub branch name.
#  The company.
#  The path before the iniziation of a function.
#  The path after the iniziation of a function.
# Returns:
#  0 if funciton was evaluated succesfull.
#  20 if the GitLab repository didn't exist locally.
# Outputs:
#  None.
#######################################
checkout_branch_in_gitlab_repo() {
  local gitlab_repo_name="$1"
  local gitlab_branch_name="$2"
  local company="$3"

  if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

    # Verify the desired branch exists.
    branch_check_result="$(gitlab_branch_exists $gitlab_repo_name $gitlab_branch_name)"
    gitlab_branch_is_found=$(assert_ends_in_found_and_not_in_notfound ${branch_check_result})

    if [ "$gitlab_branch_is_found" == "TRUE" ]; then

      # Get the path before executing the command (to verify it is restored correctly after).
      local pwd_before
	  pwd_before="$PWD"

      # Checkout the branch inside the repository.
      cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git checkout "$gitlab_branch_name"
      cd ../../../..

      # Get the path after executing the command (to verify it is restored correctly after).
      local pwd_after
      pwd_after="$PWD"

      # Verify the current branch in the gitlab repository is indeed checked out.
      # e.g. using git status
      assert_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name"

    else
      # Get the path before executing the command (to verify it is restored correctly after).
      pwd_before="$PWD"

      # Create the branch.
      cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git checkout -b "$gitlab_branch_name"
      cd ../../../..
      # Get the path after executing the command (to verify it is restored correctly after).
      pwd_after="$PWD"

      # Verify the current branch in the gitlab repository is indeed checked out.
      # TODO: Check if this passes.
      assert_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name"
    fi

    # Verify the current path is the same as it was when this function started.
    path_before_equals_path_after_command "$pwd_before" "$pwd_after"
  else
    echo "ERROR, the gitlab repository does not exist locally."
    exit 20
  fi
}


#######################################
# Pushes the changes to the target directory in the GitLab server.
# Local variables:
#  repo_name
#  gitlab_username
#  GITLAB_SERVER_PASSWORD_GLOBAL
#  gitlab_server
#  target_directory
# Globals:
#  None
# Arguments:
#  The name of the repository.
#  The GitLab username.
#  The GitLab server password.
#  The GitLab server.
#  The targer directory.
# Returns:
#  0 if funciton was evaluated succesfull.
# Outputs:
#  None.
#######################################
push_changes() {
  local repo_name=$1
  local gitlab_username=$2
  local gitlab_server_password=$3
  local gitlab_server=$4
  local target_directory=$5

  output=$(cd "$target_directory" && git push http://$gitlab_username:$gitlab_server_password@$gitlab_server/$gitlab_username/$repo_name.git)
}


# Structure:gitlab_modify
#######################################
# Checks if the target folder already exist and then deletes it.  
# How to run:
#  source src/run_ci_job.sh && export_rep
# Local variables:
#  None
# Globals:
#  SOURCE_FOLDERNAME
# Arguments:
#  None
# Returns:
#  0 if funciton was evaluated succesfull.
# Outputs:
#  None.
#######################################
delete_target_folder() {
  # check if target folder already exists
  # delete target folder if it already exists
  if [ -d "../$SOURCE_FOLDERNAME" ] ; then
      sudo rm -r "../$SOURCE_FOLDERNAME"
  fi
  # create target folder
  # copy source folder to target
}


# Structure:gitlab_modify
# 6.k Commit the GitLab branch changes, with the sha from the GitHub branch.
#######################################
# First checks if the GitHub repository exist. Then checks locally if the 
# GitHub branch and yaml file exist. Afterwards, GitLab is checked for existing
# repository and branch. Once checked, the local GitHub branch files are copied 
# to GitLab branch. At the end the files are verified if they were correctly 
# copied from GitHub branch to GitLab branch  by comparing the paths before and
#  after the function was executed. If not, an  error is thrown.    
# Local variables:
#  github_repo_name
#  github_branch_name
#  github_commit_sha
#  gitlab_repo_name
#  gitlab_branch_name
#  github_branch_check_result
#  last_line_github_branch_check_result
#  filepath
#  found_branch_name
# Globals:
#  MIRROR_LOCATION
# Arguments:
#  None
# Returns:
#  0 if funciton was evaluated succesfull.
#  11 if the content in the GitHub branch is not exactly copied into the 
#  GitLab branch, even when excluding the .git directory.
#  12 if the GitLab branch does not exist locally.
#  13 if the GitLab repository does not exist locally.
#  14 if the GitHub branch does contain a yaml file.
#  24 if the GitHub branch does not exist locally.
#  25 if the GitHub repository does not exist locally.
# Outputs:
#  None.
# TODO (a-t-0): Verify the changes were committed to GitLab correctly.(There
# are no remaining files to be added)
# TODO (a-t-0): Verify the changes were committed to GitLab correctly.(There 
# commit message equals the sha)
#######################################
commit_changes_to_gitlab() {
  local github_repo_name="$1"
  local github_branch_name="$2"
  local github_commit_sha="$3"
  local gitlab_repo_name="$4"
  local gitlab_branch_name="$5"

  # If the GitHub repository exists
  if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

    # If the GitHub branch exists
	  local github_branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
    local github_branch_is_found=$(assert_ends_in_found_and_not_in_notfound ${github_branch_check_result})
    if [ "$github_branch_is_found" == "TRUE" ]; then

      # If the GitHub branch contains a gitlab yaml file
      local filepath
	    filepath="$MIRROR_LOCATION/GitHub/$github_repo_name/.gitlab-ci.yml"
      if [ "$(file_exists $filepath)" == "FOUND" ]; then

        # If the GitLab repository exists
        if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

          # If the GitLab branch exists
          found_branch_name="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name "GitLab")"
          if [ "$found_branch_name" == "$gitlab_branch_name" ]; then

            # If there exist differences in the files or folders in the branch (excluding the .git directory)

            # Then copy the files and folders from the GitHub branch into the GitLab branch (excluding the .git directory)
            # That also deletes the files that exist in the GitLab branch that do not exist in the GitHub branch (excluding the .git directory)
            copy_github_files_and_folders_to_gitlab "$MIRROR_LOCATION/GitHub/$github_repo_name" "$MIRROR_LOCATION/GitLab/$github_repo_name"

            # Then verify the checksum of the files and folders in the branches are identical (excluding the .git directory)
            comparison_result="$(two_folders_are_identical_excluding_subdir $MIRROR_LOCATION/GitHub/$github_repo_name $MIRROR_LOCATION/GitLab/$github_repo_name .git)"

            # Verify the files were correctly copied from GitHub branch to GitLab branch.
            if [ "$comparison_result" == "IDENTICAL" ]; then
              #echo "IDENTICAL"

              # Get the path before executing the command (to verify it is restored correctly after).
              pwd_before="$PWD"

              if [[ "$(git_has_changes "$MIRROR_LOCATION/GitLab/$github_repo_name")" == "FOUND" ]]; then

                # Commit the changes to GitLab.
                cd "$MIRROR_LOCATION/GitLab/$github_repo_name" && git add -A && git commit -m \"$github_commit_sha\"
                cd ../../../..
              fi

              # Get the path after executing the command (to verify it is restored correctly after).
              pwd_after="$PWD"

              # Verify the current path is the same as it was when this function started.
              path_before_equals_path_after_command "$pwd_before" "$pwd_after"

              # TODO: Verify the changes were committed to GitLab correctly. (There are no remaining files to be added)
              #git status
              # TODO: Verify the changes were committed to GitLab correctly. (There commit message equals the sha)
              #git log

            else
              echo "ERROR, the content in the GitHub branch is not exactly copied into the GitLab branch, even when excluding the .git directory."
              exit 11
            fi

          else
            echo "ERROR, the GitLab branch does not exist locally."
            exit 12
          fi
        else
          echo "ERROR, the GitLab repository does not exist locally."
          exit 13
        fi
      else
        echo "ERROR, the GitHub branch does contain a yaml file."
        exit 14
      fi
    else
      echo "ERROR, the GitHub branch does not exist locally."
      exit 24
    fi
  else
    echo "ERROR, the GitHub repository does not exist locally."
    exit 25
  fi
}


commit_changes_to_gitlab_for_commit() {
  local github_repo_name="$1"
  local github_branch_name="$2"
  local github_commit_sha="$3"
  local gitlab_repo_name="$4"
  local gitlab_branch_name="$5"

  # If the GitHub repository exists
  if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

      # If the GitHub branch contains a gitlab yaml file
      local filepath
	    filepath="$MIRROR_LOCATION/GitHub/$github_repo_name/.gitlab-ci.yml"
      if [ "$(file_exists $filepath)" == "FOUND" ]; then

        # If the GitLab repository exists
        if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

          # If the GitLab branch exists
          found_branch_name="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name "GitLab")"
          if [ "$found_branch_name" == "$gitlab_branch_name" ]; then

            # If there exist differences in the files or folders in the branch (excluding the .git directory)

            # Then copy the files and folders from the GitHub branch into the GitLab branch (excluding the .git directory)
            # That also deletes the files that exist in the GitLab branch that do not exist in the GitHub branch (excluding the .git directory)
            copy_github_files_and_folders_to_gitlab "$MIRROR_LOCATION/GitHub/$github_repo_name" "$MIRROR_LOCATION/GitLab/$github_repo_name"

            # Then verify the checksum of the files and folders in the branches are identical (excluding the .git directory)
            comparison_result="$(two_folders_are_identical_excluding_subdir $MIRROR_LOCATION/GitHub/$github_repo_name $MIRROR_LOCATION/GitLab/$github_repo_name .git)"

            # Verify the files were correctly copied from GitHub branch to GitLab branch.
            if [ "$comparison_result" == "IDENTICAL" ]; then
              #echo "IDENTICAL"

              # Get the path before executing the command (to verify it is restored correctly after).
              pwd_before="$PWD"

              if [[ "$(git_has_changes "$MIRROR_LOCATION/GitLab/$github_repo_name")" == "FOUND" ]]; then

                # Commit the changes to GitLab.
                cd "$MIRROR_LOCATION/GitLab/$github_repo_name" && git add -A && git commit -m \"$github_commit_sha\"
                cd ../../../..
              fi

              # Get the path after executing the command (to verify it is restored correctly after).
              pwd_after="$PWD"

              # Verify the current path is the same as it was when this function started.
              path_before_equals_path_after_command "$pwd_before" "$pwd_after"

              # TODO: Verify the changes were committed to GitLab correctly. (There are no remaining files to be added)
              #git status
              # TODO: Verify the changes were committed to GitLab correctly. (There commit message equals the sha)
              #git log

            else
              echo "ERROR, the content in the GitHub branch is not exactly copied into the GitLab branch, even when excluding the .git directory."
              exit 11
            fi

          else
            echo "ERROR, the GitLab branch does not exist locally."
            exit 12
          fi
        else
          echo "ERROR, the GitLab repository does not exist locally."
          exit 13
        fi
      else
        echo "ERROR, the GitHub branch does contain a yaml file."
        exit 14
      fi
  else
    echo "ERROR, the GitHub repository does not exist locally."
    exit 25
  fi
}

#######################################
# Checks if a GitHub repository and branch exists. If the repository contains 
# a GitLab  yaml file, the code checks if a GitLab repository and branch exist.
# Then files and folders are copied from GitHub to GitLab. Afterwards, the files 
# and folders are verified if they are identical. At the end the changes are 
# pushed  to Gitlab and verified. Errors are thrown if one of the steps cannot 
# be completed.
# Local variables:
#  github_repo_name
#  github_branch_name
#  github_commit_sha
#  gitlab_repo_name
#  gitlab_branch_name
#  github_branch_check_result
#  last_line_github_branch_check_result
#  comparison_result
#  found_branch_name
# Globals:
#  MIRROR_LOCATION
#  GITLAB_SERVER_HTTP_URL
# Arguments:
#  The GitHub repository name.
#  The GitHub branch name.
#  The GitHub commit.
#  The name of the GitLab branch.
#  Name of the GitLab repository.
# Returns:
#  0 if funciton was evaluated succesfull.
#  11 if the content in the GitHub branch was not exactly copied into the
#  GitLab branch, even when excluding the .git directory.
#  12 if the GitLab branch didn't exist locally.
#  13 if the GitLab repository didn't exist locally.
#  14 if the GitHub branch didn't contain a yaml file.
#  24 if the GitHub branch didn't exist locally.
#  25 if the GitHub repository didn't exist locally.
# Outputs:
#  None.
#######################################
push_changes_to_gitlab() {
  # Verify the GitLab repo was downloaded.
  # Verify the GitLab branch was checked out.

  # Verify the GitLab repo was downloaded.
  # Verify the GitLab branch was checked out.

  # Verify the files were correctly copied from GitHub branch to GitLab branch.

  # Verify the changes were committed to GitLab correctly.

  # Push the changes to GitLab.

  # Verify the changes were pushed to GitLab correctly.
  local github_repo_name="$1"
  local github_branch_name="$2"
  local github_commit_sha="$3"
  local gitlab_repo_name="$4"
  local gitlab_branch_name="$5"

  # If the GitHub repository exists
  if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

    # If the GitHub branch exists
    #local github_branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
    #github_branch_is_found=$(assert_ends_in_found_and_not_in_notfound ${github_branch_check_result})
    
    #if [ "$github_branch_is_found" == "TRUE" ]; then

      # If the GitHub branch contains a gitlab yaml file
      local filepath
	    filepath="$MIRROR_LOCATION/GitHub/$github_repo_name/.gitlab-ci.yml"
      if [ "$(file_exists $filepath)" == "FOUND" ]; then

        # If the GitLab repository exists
        if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

          # If the GitLab branch exists

          local found_branch_name
          #read -p "get_current_gitlab_branch\n\n\n"
		      found_branch_name=$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name "GitLab")
          if [ "$found_branch_name" == "$gitlab_branch_name" ]; then

            # If there exist differences in the files or folders in the branch (excluding the .git directory)

            # Then copy the files and folders from the GitHub branch into the GitLab branch (excluding the .git directory)
            # That also deletes the files that exist in the GitLab branch that do not exist in the GitHub branch (excluding the .git directory)
            #read -p "copy_github_files_and_folders_to_gitlab\n\n\n"
            copy_github_files_and_folders_to_gitlab "$MIRROR_LOCATION/GitHub/$github_repo_name" "$MIRROR_LOCATION/GitLab/$github_repo_name"

            # Then verify the checksum of the files and folders in the branches are identical (excluding the .git directory)
            local comparison_result
            #read -p "two_folders_are_identical_excluding_subdir\n\n\n"
			      comparison_result="$(two_folders_are_identical_excluding_subdir $MIRROR_LOCATION/GitHub/$github_repo_name $MIRROR_LOCATION/GitLab/$github_repo_name .git)"

            # Verify the files were correctly copied from GitHub branch to GitLab branch.
            if [ "$comparison_result" == "IDENTICAL" ]; then
              #echo "IDENTICAL"

              # Get the path before executing the command (to verify it is restored correctly after).
              local pwd_before
			        pwd_before="$PWD"

              # TODO: Verify the changes were committed to GitLab correctly. (There are no remaining files to be added)
              #git status
              # TODO: Verify the changes were committed to GitLab correctly. (There commit message equals the sha)
              #git log

              # Commit the changes to GitLab.
              #read -p "PUSH to GITLAB\n\n\n"
              cd "$MIRROR_LOCATION/GitLab/$github_repo_name" && git push --set-upstream origin "$gitlab_branch_name"
              cd ../../../..
              #read -p "Done path"
              # Get the path after executing the command (to verify it is
			  # restored correctly after).
              local pwd_after
              pwd_after="$PWD"

              # Verify the current path is the same as it was when this function started.
              path_before_equals_path_after_command "$pwd_before" "$pwd_after"

            else
              echo "ERROR, the content in the GitHub branch is not exactly
			  copied into the GitLab branch, even when excluding the .git directory."
			  END
              exit 11
            fi

          else
            echo "ERROR, the GitLab branch does not exist locally."
            exit 12
          fi
        else
          echo "ERROR, the GitLab repository does not exist locally."
          exit 13
        fi
      #else
      #  echo "ERROR, the GitHub branch does contain a yaml file."
      #  exit 14
      #fi
    else
      echo "ERROR, the GitHub branch does not exist locally."
      exit 24
    fi
  else
    echo "ERROR, the GitHub repository does not exist locally."
    exit 25
  fi
}









#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:gitlab_status
delete_all_gitlab_files() {
	source_dir="$1"
	
	for f in $source_dir
	do
	if [ -f "$f" ]; then
		rm "$f"
	fi
	done
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:gitlab_status
delete_all_gitlab_folders() {
	source_dir="$1"
	
	for f in $source_dir
	do
	if [ -d "$f" ]; then
		if [[ "${f: -2}" != "/." && "${f: -3}" != "/.." && "${f: -5}" != "/.git" ]]; then
			rm -r "$f"
		else
			echo "Dir EXCLUDE FROM DELETE $f"
		fi
	fi
	done
}




#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:gitlab_status
copy_all_gitlab_files() {
	source_dir="$1"
	target_dir="$2"
	
	for f in $source_dir
	do
	if [ -f "$f" ]; then
		cp -r "$f" "$target_dir"
	fi
	done
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:gitlab_status
copy_all_gitlab_folders() {
	source_dir="$1"
	target_dir="$2"
	
	for f in $source_dir
	do
	if [ -d "$f" ]; then
		if [[ "${f: -2}" != "/." && "${f: -3}" != "/.." && "${f: -5}" != "/.git" ]]; then
			cp -r "$f" "$target_dir"
			#cp "$f" "$target_dir"
		else
			echo "Dir EXCLUDE FROM COPY $f"
		fi
	fi
	done
}

remove_the_gitlab_repository_on_which_ci_is_ran() {
  # Delete GitLab repo at start of test.
	remove_dir "$MIRROR_LOCATION/GitLab"
	manual_assert_dir_not_exists "$MIRROR_LOCATION/GitLab"
}