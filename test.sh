# Run this file to run all the tests, once
#source src/import.sh
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

### Short tests (passing):
## Works again
#./test/libs/bats/bin/bats test/test_boot_tor.bats

## Partially working (2 tests still fail)
# One test needs to be moved into after installation.
#./test/libs/bats/bin/bats test/test_src_helper.bats

## Works Again
#./test/libs/bats/bin/bats test/test_uninstall.bats

### Working again
#./test/libs/bats/bin/bats test/test_install_and_boot_gitlab_server.bats



# Test mirroring GitHub to GitLab
#### Works Again
#./test/libs/bats/bin/bats test/test_helper_dir_edit.bats
#### Partially working (requires installation)
#./test/libs/bats/bin/bats test/test_helper_github_status.bats
#### Works
./test/libs/bats/bin/bats test/test_helper_github_modify.bats
#### Works
###./test/libs/bats/bin/bats test/test_helper_gitlab_modify.bats
#### Works
###./test/libs/bats/bin/bats test/test_helper_gitlab_status.bats
#### Works
###./test/libs/bats/bin/bats test/test_helper_git_neutral.bats
##### Semi-works
####./test/libs/bats/bin/bats test/test_helper_ssh.bats
#### Works
###./test/libs/bats/bin/bats test/test_sha256_checksum.bats

# New test
###./test/libs/bats/bin/bats test/test_run_ci_on_github_repo.bats
###./test/libs/bats/bin/bats test/test_helper_asserts.bats