#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
# https://github.com/bats-core/bats-file#Index-of-all-functions
load 'libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load 'assert_utils'

# source src/import.sh

example_lines=$(cat <<-END
ssh-ed25519 longcode/longcode somename-somename-123
ssh-rsa longcode/longcode+longcode+longcode/longcode/longcode+longcode/longcode+longcode somename@somename-somename-123
ssh-ed25519 longcode somename@somename-somename-123
ssh-ed25519 longcode/longcode+longcode somename@somename.somename
END
)

# Specify expected error message:
expected_error_message=$(cat <<-END
Cloning into 'src/mirrors/GitHub/NON_EXISTANT_REPOSITORY'...
ERROR: Repository not found.
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
END
)
	

example_git_status_output=$(cat <<-END
On branch no_attack_in_filecontent

No commits yet

nothing to commit (create/copy files and use "git add" to track)
END
)

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