# Run this file to run all the tests, once
source src/import.sh
#./test/libs/bats/bin/bats test/*.bats

# Long tests (failing)
#./test/libs/bats/bin/bats test/helper/long_test_helper.bats
#./test/libs/bats/bin/bats test/Tor_support/long_test_boot_tor.bats
#./test/libs/bats/bin/bats test/Selenium/test_get_gitlab_server_runner_token.bats

###./test/libs/bats/bin/bats test/Selenium/test_create_personal_access_token.bats

# Test status unknown
####./test/libs/bats/bin/bats test/CI/GitLab_runner/modular_test_runner.bats
# Test status unknown
#./test/libs/bats/bin/bats test/CI/GitLab_runner/test_runner_works.bats

# Short tests (failing):
#./test/libs/bats/bin/bats test/Tor_support/test_install_ssh_over_tor.bats


# TODO: move into right files
# Fail: Docker image name is recognised correctly.
# Fail: Docker container is reported as stopped correctly.

############### no_server_required - preserves_server##########################
#2 Fails:
# Docker image name is recognised correctly.
# Docker container is reported as stopped correctly.
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_docker.bats
# 1 Fail:
# Check if mirror directories are created.
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_helper_dir_edit.bats


#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_parser.bats
#exit 4
# 7/38 tests fail on lines contain string function:
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_parsing.bats
#exit 4

## Succeeding:
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_helper_ssh.bats

#./test/libs/bats/bin/bats test/helper/test_helper_asserts.bats
#./test/libs/bats/bin/bats test/helper/test_helper_file_dir_related.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_logging.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_boot_tor.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_file_dir_related.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_support_programs.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_uninstall.bats
#./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_install_and_boot_gitlab_server.bats
./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_parsing.bats

############### no_server_required - breaks_server##########################
# Works (Takes 45 sec)
# TODO: move into right folder
# 1 Fail:
# Checking Docker version response fails if docker is removed.
###./test/libs/bats/bin/bats test/test_docker.bats

############### server_required - preserves_server##########################
# New test
# TODO: move into right folder
# TODO: (if needed) separate into: requires installation, does not require installation.
#./test/libs/bats/bin/bats test/CI/call_CI/test_run_ci_on_github_repo.bats

### Partially working (requires installation)
# TODO: separate into: requires installation, does not require installation.
###./test/libs/bats/bin/bats test/server_required/preserves_server/test_helper_github_status.bats
###./test/libs/bats/bin/bats test/server_required/breaks_server/test_docker.bats

# Fail: Verify apache2 is not found.
###./test/libs/bats/bin/bats test/no_server_required/preserves_server/test_support_programs.bats


############### server_required - breaks_server##########################






#### # Does not work, it seems to be hanging
##./test/libs/bats/bin/bats test/helper/GitHub/test_helper_github_modify.bats

# TODO:
#### Works # Test status unknown
###./test/libs/bats/bin/bats test/helper/GitLab/helper/GitLab/test_helper_gitlab_modify.bats
#### Works # Test status unknown
###./test/libs/bats/bin/bats test/helper/GitHub/helper/GitHub/test_helper_gitlab_status.bats
#### Works # Test status unknown
###./test/libs/bats/bin/bats test/helper/git_neutral/helper/git_neutral/test_helper_git_neutral.bats
#### Works # Test status unknown
###./test/libs/bats/bin/bats test/helper/verification/helper/verification/test_sha256_checksum.bats
