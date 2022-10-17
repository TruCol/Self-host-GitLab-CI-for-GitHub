#!/bin/bash
# This script contains the receipe that verifies the prerequisites are 
# satisfied.
ensure_prerequisites_compliance() {
    local no_credentials_check="$1"
    ### Verify prerequistes
    if [ "$github_username" != "" ]; then
      echo "Storing your GitHub username:$github_username in a personal cred file."
      add_entry_to_personal_cred_file "GITHUB_USERNAME_GLOBAL" $github_username
    fi
    # GitHub password is not stored.

    if [ "$gitlab_username" != "" ]; then
      echo "Storing your GitLab username:$gitlab_username in a personal cred file."
    	add_entry_to_personal_cred_file "GITLAB_SERVER_ACCOUNT_GLOBAL" $gitlab_username
    fi
    if [ "$gitlab_pwd" != "" ]; then
      echo "Storing your GitLab password in a personal cred file."
      set_gitlab_pwd $gitlab_pwd
    fi
    if [ "$gitlab_email" != "" ]; then
      echo "Storing your GitLab email:$gitlab_email in a personal cred file."
    	add_entry_to_personal_cred_file "GITLAB_ROOT_EMAIL_GLOBAL" "$gitlab_email"
    fi
    # TODO: verify required data is in personal_creds.txt

    if [ "$no_credentials_check" == "" ]; then
      verify_personal_credentials
    fi

    # Reload personal_creds.txt
    source "$PERSONAL_CREDENTIALS_PATH"

    # Verify the initial personal credits are stored correctly.
    verify_prerequisite_personal_creds_txt_contain_required_data
    verify_prerequisite_personal_creds_txt_loaded


    # Raise sudo permission at the start, to prevent requiring user permission half way through tests.
    printf "\n\n1. Now getting sudo permission to perform the GitLab installation."
    {
      sudo echo "hi"
    } &> /dev/null

    # Ensuring the Firefox installation is performed with ppa/apt instead of snap.
    # This is such that the browser can be controlled automatically.
    printf "\n2. Now ensuring the firefox is installed with ppa and apt instead."
    printf "of snap."
    swap_snap_firefox_with_ppa_apt_firefox_installation

    # Ensure jq is installed correctly.
    printf "\n\n3. Now ensuring jquery is installed."
    install_jquery_using_apt

    # Verify the GitHub user has the required repositories.
    printf "\n\n4. Verifying the $GITHUB_STATUS_WEBSITE_GLOBAL and "
    printf "$PUBLIC_GITHUB_TEST_REPO_GLOBAL repositories exist in your GitHub"
    printf " account."
    # TODO: include catch for: The requested URL returned error: 403 rate limit exceeded
    assert_required_repositories_exist_in_github_server "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL"
    assert_required_repositories_exist_in_github_server "$GITHUB_USERNAME_GLOBAL" "$PUBLIC_GITHUB_TEST_REPO_GLOBAL"

    # Verifying the GitHub repositories exist locally.
    download_github_repo_to_mirror_location "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL"

    # Verify the GitHub user has ssh-access to GitHub.
    assert_user_has_ssh_access_to_github "$GITHUB_USERNAME_GLOBAL"

    # Get the GitHub personal access code.
    printf "\n\n5. Setting and Getting the GitHub personal access token if it "
    printf "does not yet exist."
    ensure_github_pat_is_added_to_github $GITHUB_USERNAME_GLOBAL $github_password
    # After setting the GitHub pat, verify it is stored correctly locally.
    verify_personal_creds_txt_contain_pacs    

    # Check if ssh deploy key already exists and can be used to push
    # to GitHub, before creating a new one.
    printf "\n\n6. Ensuring you have ssh push access to the "
    printf "$GITHUB_STATUS_WEBSITE_GLOBAL repository with your ssh-deploy key."
    ensure_github_ssh_deploy_key_has_access_to_build_status_repo $GITHUB_USERNAME_GLOBAL $github_password $GITHUB_STATUS_WEBSITE_GLOBAL

    assert_required_repositories_exist_in_github_server "$GITHUB_USERNAME_GLOBAL" "$GITHUB_STATUS_WEBSITE_GLOBAL"
}
