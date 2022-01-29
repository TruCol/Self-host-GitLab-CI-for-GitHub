#!./test/libs/bats/bin/bats

load '../../libs/bats-support/load'
load '../../libs/bats-assert/load'
load '../../libs/bats-file/load'

# Test that an error is thrown if user decides to do a soft-uninstallation 
# (which does not have a y/n prompt), while trying to override the y/n 
# prompt.
@test "If error is thrown for arguments -p and -y." {
	run bash -c "./uninstall_gitlab.sh -p -y"
	assert_failure
	assert_output --partial "ERROR, you chose to manually override the y/n prompt for the soft uninstallation, but the soft uninstallation does not have a y/n prompt for confirmation."
	#assert_output "ERROR, you chose to manually override the y/n prompt for the soft uninstallation, but the soft uninstallation does not have a y/n prompt for confirmation."
}

# Test that an error is thrown if user decides to override y/n prompt for 
# uninstallation whilst doing a soft-uninstallation which does not have
# a y/n prompt. 
@test "If error is thrown for arguments -y and -p." {
	run bash -c "./uninstall_gitlab.sh -y -p"
	assert_failure
	assert_output --partial "ERROR, you chose to manually override the y/n prompt for the soft uninstallation, but the soft uninstallation does not have a y/n prompt for confirmation."
	#assert_output "ERROR, you chose to manually override the y/n prompt for the soft uninstallation, but the soft uninstallation does not have a y/n prompt for confirmation."
}

# Test that an error is thrown if user decides to override y/n prompt for 
# uninstallation whilst doing a soft-uninstallation which does not have
# a y/n prompt.
@test "If error is thrown for arguments -y, -r and -p." {
	run bash -c "./uninstall_gitlab.sh -y  -r -p"
	assert_failure
	assert_output --partial "ERROR, you chose to manually override the y/n prompt for the soft uninstallation, but the soft uninstallation does not have a y/n prompt for confirmation."
	#assert_output "ERROR, you chose to manually override the y/n prompt for the soft uninstallation, but the soft uninstallation does not have a y/n prompt for confirmation."
}

# Verify the code throws a "please enter a yes or no" to a non-yes/no answer
# on the yes/no prompt for a hard uninstallation.
@test "If error is thrown for incorrect follow up answer: 'something' on  argument -h." {
	run bash -c "./uninstall_gitlab.sh -h  <<< something"
	assert_failure
	#assert_output "Please answer yes or no."
	assert_output --partial "Please answer yes or no."
	
}

# Verify the code does not perfrom an uninstallation of GitLab if the user 
# first gives the argument for a hard uninstallation, followed by a "no" 
# as answer to the "are you sure?" yes/no prompt.
@test "If correct output message is given for correct follow up answer: 'n' on  argument -h." {
	run bash -c "./uninstall_gitlab.sh -h  <<< n"
	assert_output --partial "The GitLab server was NOT uninstalled"
	#assert_output "The GitLab server was NOT uninstalled"
}

# TODO: verify output message for incorrect argument usage
