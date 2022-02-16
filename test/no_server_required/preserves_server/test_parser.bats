#!./test/libs/bats/bin/bats

load '../../libs/bats-support/load'
load '../../libs/bats-assert/load'

# https://github.com/bats-core/bats-file#Index-of-all-functions
load '../../libs/bats-file/load'
# https://github.com/bats-core/bats-assert#usage
load '../../assert_utils'

# TODO: move to import
# TODO: before moving, verify the function names do not collide.
source test/helper.sh
source test/hardcoded_testdata.txt

# Method that executes all tested main code before running tests.
setup() {
	# print test filename to screen.
	if [ "${BATS_TEST_NUMBER}" = 1 ];then
		echo "# Testfile: $(basename ${BATS_TEST_FILENAME})-" >&3
	fi	
}


print_usage() {
  printf "\nDefault usage, write:"
  printf "\n./install_gitlab.sh -s -r -ds -cpat to install GitLab CI and run it on your GitHub repositories."
  printf "\n./install_gitlab.sh -s -r -ds -cpat -user <your GitHub username> -repo <your GitHub repository name> to install GitLab CI and run it on the repository of that user.\n"

  printf "\nSupported options:"
  # TODO: verify if the user can set the value of the GitHub personal access
  # token, or whether the value is given/set by GitHub automatically.
  # If it is given by GitHub automatically, change this into a boolean decision
  # that indicates whether or not the user will set the commit build statuses
  # on GitHub or not.
  
  printf "\n./install_gitlab.sh -ds or: ./install_gitlab.sh --deploy-ssh to start by setting the ssh deploy key to the GitHub build status repository."
  printf "\n./install_gitlab.sh -r or: ./install_gitlab.sh --runner to do an installation of the GitLab runner."
  printf "\n./install_gitlab.sh -s or: ./install_gitlab.sh --server\n to do an installation of the GitLab server."
  
  printf "\n./install_gitlab.sh -hubcpat or: ./install_gitlab.sh --github-commit-status-pat to enable the code to set the build status of GitHub commits using a personal acces token."
  printf "\n./install_gitlab.sh -hubpwd or: ./install_gitlab.sh --github-password\n to pass your GitHub password, to prevent having to wait untill you can enter it in the website."
  printf "\n./install_gitlab.sh -hubuser <your GitHub username> or: ./install_gitlab.sh --github-username <your GitHub username>\n to pass your GitHub username, to prevent having to wait untill you can enter it in the website."
  
  printf "\n./install_gitlab.sh -labemail <your email for GitLab> or: ./install_gitlab.sh --gitlab-email <your email for GitLab>\n to pass your the email address you use for GitLab, and store it in your ../personal_credentials.txt."
  printf "\n./install_gitlab.sh -labpat <your new GitLab personal access token> or: ./install_gitlab.sh --gitlab-personal_access_token <your new GitLab personal access token>\n to pass your new GitLab personal access token, and store it in your ../personal_credentials.txt."
  printf "\n./install_gitlab.sh -labpwd or: ./install_gitlab.sh --gitlab-password\n to pass your new GitLab password,pass your GitLab username, and store it in your ../personal_credentials.txt."
  printf "\n./install_gitlab.sh -laburl <website for your GitLab server> or: ./install_gitlab.sh --gitlab-email <website for your GitLab server>\n to set a custom gitlab server website (default=http://127.0.0.1), and store it in your ../personal_credentials.txt."
  printf "\n./install_gitlab.sh -labuser <your new GitLab username> or: ./install_gitlab.sh --gitlab-username <your GitLab username>\n to set a custom GitLab username(default=root), and store it in your ../personal_credentials.txt."

  printf "\n\nNot yet supported:"
  printf "\n./install_gitlab.sh -hubcssh or: ./install_gitlab.sh --github-commit-status-ssh to enable the code to set the build status of GitHub commits using an ssh key."
  printf "\n./install_gitlab.sh -b or: ./install_gitlab.sh --boot to set up a script/cronjob that runs the GitLab CI on your GitHub repositories in the background after reboots."
  printf "\n./install_gitlab.sh -repo or: ./install_gitlab.sh --repo to run the GitLab CI on a particular GitHub repository."
  printf "\n./install_gitlab.sh -tw or: ./install_gitlab.sh --tor-website to set up tor website for your GitLab server."
  printf "\n./install_gitlab.sh -user or: ./install_gitlab.sh --user to run the GitLab CI on a particular GitHub user/organisation."
  
  printf "you can also combine the separate arguments in different orders, e.g. -r -s -w.\n\n"
}

@test "Verify invalid arguments throw a warning and usage instructions." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -z"
	assert_failure
	# Assert warning is thrown.
	assert_output --partial "Unknown option -z"
	# Assert instructions are displayed.
	assert_output --partial ${expected_output}
}

@test "Verify valid arguments: -ds is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -ds"
	assert_success
}

@test "Verify valid arguments: --deploy-ssh is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh --deploy-ssh"
	assert_success
}


@test "Verify valid arguments: -hubcssh is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -hubcssh"
	assert_success
}

@test "Verify valid arguments: --github-commit-status-ssh is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh --github-commit-status-ssh"
	assert_success
}


@test "Verify valid arguments: -hubcpat is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "answer-custom-question | ./parser.sh -hubcpat"
	assert_success
}

@test "Verify valid arguments: --github-commit-status-pat is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "example-GitHub-personal-access-token | ./parser.sh --github-commit-status-pat"
	assert_success
}


@test "Verify valid arguments: -b is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -b"
	assert_success
}

@test "Verify valid arguments: --boot is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh --boot"
	assert_success
}


@test "Verify valid arguments: -tw is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -tw"
	assert_success
}

@test "Verify valid arguments: --tor_website is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh --tor_website"
	assert_success
}

@test "Verify valid arguments: -hubuser is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -hubuser example-github-username"
	assert_success
}

@test "Verify valid arguments: --github-username is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh --github-username example-github-username"
	assert_success
}

@test "Verify valid arguments: -hubpwd is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "examplepassword | ./parser.sh -hubpwd"
	assert_success
}

@test "Verify valid arguments: --github-password is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "examplepassword | ./parser.sh --github-password"
	assert_success
}


@test "Verify valid arguments: -labuser is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -labuser some-gitlab-user"
	assert_success
}

@test "Verify valid arguments: --gitlab-username is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh --gitlab-username some-gitlab-user"
	assert_success
}


@test "Verify valid arguments: -labpwd is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "answer-custom-question | ./parser.sh -labpwd"
	assert_success
}

@test "Verify valid arguments: --gitlab-password is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "answer-custom-question | ./parser.sh --gitlab-password"
	assert_success
}


@test "Verify valid arguments: -labpat is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "answer-custom-question | ./parser.sh -labpat"
	assert_success
}

@test "Verify valid arguments: --gitlab-personal-access-token is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "answer-custom-question | ./parser.sh --gitlab-personal-access-token"
	assert_success
}


@test "Verify valid arguments: -labemail is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -labemail"
	assert_success
}

@test "Verify valid arguments: --gitlab-email is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh --gitlab-email"
	assert_success
}


@test "Verify valid arguments: -laburl is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh -laburl some-gitlab-url"
	assert_success
}

@test "Verify valid arguments: --gitlab-server-url is parsed correctly." {
	local expected_output=$(print_usage)
	run bash -c "./parser.sh --gitlab-server-url some-gitlab-url"
	assert_success
}