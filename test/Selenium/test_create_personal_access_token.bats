#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

# source src/import.sh


# Source: https://docs.gitlab.com/ee/api/personal_access_tokens.html#personal-access-tokens-api
@test "Checking get line containing substring." {
	#curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens"
	
	#curl --header "PRIVATE-TOKEN: <your_access_token>" "$GITLAB_SERVER_HTTPS_URL/api/v4/personal_access_tokens"
	identification_str="second li"
	#line=$(get_first_line_containing_substring "test/static_file_with_spaces.txt" "$identification_str")
	line=$(get_first_line_containing_substring "test/static_file_with_spaces.txt" "\${identification_str}")
	EXPECTED_OUTPUT="second line"
		
	assert_equal "$line" "$EXPECTED_OUTPUT"
}

 
@test "Checking decision logic." {
	output=$(gitlab_personal_access_token_exists "Filler")
	EXPECTED_OUTPUT="FOUND"
	assert_equal "$output" "$EXPECTED_OUTPUT"
}


@test "Checking list of existing personal-access-tokens." {
	output=$(get_personal_access_token_list "Filler")
	echo "output=$output"
	assert_equal "$(lines_contain_string "$GITLAB_PERSONAL_ACCESS_TOKEN_NAME_GLOBAL" "\${output}")" "FOUND"
}