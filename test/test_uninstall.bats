#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'



source uninstall_gitlab.sh


@test "If error is thrown for arguments -s and -y." {
	run bash -c "./uninstall_gitlab.sh -s -y"
	assert_failure
	assert_output --partial "ERROR, you chose to manually override the prompt for the soft uninstallation, but the soft uninstallation does not not prompt for confirmation."
	assert_output "ERROR, you chose to manually override the prompt for the soft uninstallation, but the soft uninstallation does not not prompt for confirmation."
}
@test "If error is thrown for arguments -y and -s." {
	run bash -c "./uninstall_gitlab.sh -y -s"
	assert_failure
	assert_output --partial "ERROR, you chose to manually override the prompt for the soft uninstallation, but the soft uninstallation does not not prompt for confirmation."
	assert_output "ERROR, you chose to manually override the prompt for the soft uninstallation, but the soft uninstallation does not not prompt for confirmation."
}
@test "If error is thrown for arguments -y, -r and -s." {
	run bash -c "./uninstall_gitlab.sh -y  -r -s"
	assert_failure
	assert_output --partial "ERROR, you chose to manually override the prompt for the soft uninstallation, but the soft uninstallation does not not prompt for confirmation."
	assert_output "ERROR, you chose to manually override the prompt for the soft uninstallation, but the soft uninstallation does not not prompt for confirmation."
}


@test "If error is thrown for incorrect follow up answer: 'something' on  argument -h." {
	run bash -c "./uninstall_gitlab.sh -h  <<< something"
	assert_failure
	assert_output "Please answer yes or no."
}
@test "If correct output message is given for correct follow up answer: 'n' on  argument -h." {
	run bash -c "./uninstall_gitlab.sh -h  <<< n"
	assert_output "The GitLab server was NOT uninstalled"
}

# TODO: verify output message for incorrect argument usage