# Run this file to run all the tests, once
#./test/libs/bats/bin/bats test/*.bats


# Long tests (failing)
#./test/libs/bats/bin/bats test/long_test_helper.bats
#./test/libs/bats/bin/bats test/long_test_boot_tor.bats
#./test/libs/bats/bin/bats test/test_get_gitlab_server_runner_token.bats
#./test/libs/bats/bin/bats test/test_install_and_boot_gitlab_runner.bats


###./test/libs/bats/bin/bats test/test_create_personal_access_token.bats

# Long tests (passing)
####./test/libs/bats/bin/bats test/modular_test_runner.bats
#./test/libs/bats/bin/bats test/test_runner_works.bats

# Short tests (failing):
#./test/libs/bats/bin/bats test/test_install_ssh_over_tor.bats
# Short tests (passing):
#./test/libs/bats/bin/bats test/test_boot_tor.bats
#./test/libs/bats/bin/bats test/test_src_helper.bats
#./test/libs/bats/bin/bats test/test_uninstall.bats
#./test/libs/bats/bin/bats test/test_install_and_boot_gitlab_server.bats



# Set up post script
###./test/libs/bats/bin/bats test/test_post_receive.bats
# Test example post-receive
###./test/libs/bats/bin/bats test/example_post-receive.bats

# Test mirroring GitHub to GitLab
#./test/libs/bats/bin/bats test/test_mirror_github_to_gitlab.bats
#./test/libs/bats/bin/bats test/test_helper_dir_edit.bats
#./test/libs/bats/bin/bats test/test_helper_github_modify.bats
./test/libs/bats/bin/bats test/test_helper_github_status.bats
#./test/libs/bats/bin/bats test/test_helper_gitlab_modify.bats
#./test/libs/bats/bin/bats test/test_helper_gitlab_status.bats
#./test/libs/bats/bin/bats test/test_helper_git_neutral.bats
#./test/libs/bats/bin/bats test/test_helper_ssh.bats