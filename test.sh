# Run this file to run all the tests, once
#source src/import.sh
#./test/libs/bats/bin/bats test/*.bats

# Long tests (failing)
#./test/libs/bats/bin/bats test/long_test_helper.bats
#./test/libs/bats/bin/bats test/long_test_boot_tor.bats
#./test/libs/bats/bin/bats test/test_get_gitlab_server_runner_token.bats
#./test/libs/bats/bin/bats test/test_install_and_boot_gitlab_runner.bats

###./test/libs/bats/bin/bats test/test_create_personal_access_token.bats

# Test status unknown
####./test/libs/bats/bin/bats test/modular_test_runner.bats
# Test status unknown
#./test/libs/bats/bin/bats test/test_runner_works.bats

# Short tests (failing):
#./test/libs/bats/bin/bats test/test_install_ssh_over_tor.bats



############### no_server_required - preserves_server##########################
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_logging.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_boot_tor.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_docker.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_parsing.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_file_dir_related.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_support_programs.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_uninstall.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_install_and_boot_gitlab_server.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_helper_dir_edit.bats

############### no_server_required - breaks_server##########################
# Works (Takes 45 sec)
./test/libs/bats/bin/bats test/test_helper_docker.bats
exit 1

############### server_required - preserves_server##########################
### Partially working (requires installation)
./test/libs/bats/bin/bats test/server_required/preserves_server/test_helper_github_status.bats

# FAIL
./test/libs/bats/bin/bats test/server_required/breaks_server/test_docker.bats
# New test
./test/libs/bats/bin/bats test/test_run_ci_on_github_repo.bats
############### server_required - breaks_server##########################






#### # Does not work, it seems to be hanging
##./test/libs/bats/bin/bats test/test_helper_github_modify.bats

# TODO:
#### Works # Test status unknown
###./test/libs/bats/bin/bats test/test_helper_gitlab_modify.bats
#### Works # Test status unknown
###./test/libs/bats/bin/bats test/test_helper_gitlab_status.bats
#### Works # Test status unknown
###./test/libs/bats/bin/bats test/test_helper_git_neutral.bats
##### Semi-works # Test status unknown
####./test/libs/bats/bin/bats test/test_helper_ssh.bats
#### Works # Test status unknown
###./test/libs/bats/bin/bats test/test_sha256_checksum.bats

# New test

###./test/libs/bats/bin/bats test/test_helper_asserts.bats


# Long tests (passing)
