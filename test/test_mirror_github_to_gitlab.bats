#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

source src/mirror_github_to_gitlab.sh
source src/helper.sh
source src/hardcoded_variables.txt

# Method that executes all tested main code before running tests.
setup() {
	# print test filename to screen.
	if [ "${BATS_TEST_NUMBER}" = 1 ];then
		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
	fi
	
	if [ $(gitlab_server_is_running | tail -1) == "RUNNING" ]; then
		true
	else
		read -p "Now re-installing GitLab."
		#+ uninstall and re-installation by default
		# Uninstall GitLab Runner and GitLab Server
		run bash -c "./uninstall_gitlab.sh -h -r -y"
	
		# Install GitLab Server
		run bash -c "./install_gitlab.sh -s -r"
	fi
}

@test "Trivial test." {
	assert_equal "True" "True"
}

@test "Test that is skipped." {
	skip
	some_function
}


@test "Check if mirror directories are created." {
	create_mirror_directories
	assert_not_equal "$MIRROR_LOCATION" ""
	assert_file_exist "$MIRROR_LOCATION"
	assert_file_exist "$MIRROR_LOCATION/GitHub"
	assert_file_exist "$MIRROR_LOCATION/GitLab"
}

@test 'assert_not_equal()' {
  
  # run activation function:
  #activate_ssh_account
  
  # Get list of activated ssh-accounts:
  ssh-accounts=$(ssh-add -L)
  
  # Split each line into 3 segments based on spaces
  
  
  # Test whether the github ssh account is activated in 3rd segment
  # Do not allow partial match but only allow complete match.
}