#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'


source src/helper.sh
source test/helper.sh
source src/hardcoded_variables.txt
source test/hardcoded_testdata.txt

# Source: https://docs.gitlab.com/ee/api/personal_access_tokens.html#personal-access-tokens-api
@test "Checking get line containing substring." {
	#curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens"
	
	#curl --header "PRIVATE-TOKEN: <your_access_token>" "$GITLAB_SERVER_HTTP_URL/api/v4/personal_access_tokens"
	identification_str="second li"
	#line=$(get_first_line_containing_substring "test/static_file_with_spaces.txt" "$identification_str")
	line=$(get_first_line_containing_substring "test/static_file_with_spaces.txt" "\${identification_str}")
	EXPECTED_OUTPUT="second line"
		
	assert_equal "$line" "$EXPECTED_OUTPUT"
}