#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'
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
	#assert_not_equal "True" "True"
	assert_not_equal 'foobar' 'foobar'
	assert_not_equal "True" ""
}

@test 'assert_not_equal()' {
  assert_not_equal 'foobar' 'foobar'
}