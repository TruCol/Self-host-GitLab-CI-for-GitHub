#######################################
# Sets the default value for Global in personal_creds.txt if the user does not
# manually specify this url in the command line arguments.
# Globals:
#  GITLAB_SERVER_HTTP_URL.
#  PERSONAL_CREDENTIALS_PATH
# Arguments:
#  The GitLab server that was originally passed as input argument to this 
#  program by the user.
# Returns:
#  0 if the function is set correctly.
#  5 If the GitLab server url is not set in the personal_creds.txt file at 
#  the end of the function.
# Outputs:
#  Nothing
# TODO(a-t-0): Move into different file.
#######################################
# Run with: 
# bash -c "source src/import.sh && add_entry_to_personal_cred_file GITLAB_SERVER_HTTP_URL gitlab_url"
add_entry_to_personal_cred_file(){
	local identifier="$1"
	local incoming_value="$2"
	
	if [ "$incoming_value" != "" ]; then
		# Ensure the PERSONAL_CREDENTIALS_PATH file exists(create if not).
		ensure_file_exists "$PERSONAL_CREDENTIALS_PATH"
		ensure_global_is_in_file "$identifier" "$incoming_value" "$PERSONAL_CREDENTIALS_PATH"
	else
		ensure_global_is_in_file "$identifier" "$GITLAB_SERVER_HTTP_URL" "$PERSONAL_CREDENTIALS_PATH"
		# Assert the PERSONAL_CREDENTIALS_PATH contains GITLAB_SERVER_HTTP_URL.
	    assert_file_contains_string "$identifier=$GITLAB_SERVER_HTTP_URL" "$PERSONAL_CREDENTIALS_PATH" > /dev/null 2>&1 &
	fi
	# Assert the PERSONAL_CREDENTIALS_PATH contains GITLAB_SERVER_HTTP_URL.
	assert_file_contains_string "$identifier" "$PERSONAL_CREDENTIALS_PATH" > /dev/null 2>&1 &
	
}