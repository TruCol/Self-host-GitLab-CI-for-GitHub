#!/bin/bash

source src/helper.sh
source src/hardcoded_variables.txt
source src/creds.txt
source src/create_personal_access_token.sh

# Source: https://docs.gitlab.com/ee/administration/server_hooks.html
# To create a Git hook that applies to all of the repositories in your instance, set a global server hook. The default global server hook directory is in the GitLab Shell directory. Any hook added there applies to all repositories.
# For an installation from source is usually /home/git/gitlab-shell/hooks. For this installer it is ASSUMED to be in:
# /home/name/gitlab/data/gitlab-shell/hooks
# However, that directory does not exist, and the /home/name/gitlab/data/gitlab-shell/ directory is owned by: 
#user #998
# According to: https://askubuntu.com/questions/651408/why-does-the-file-owner-appear-as-user-1004 ans by A.B. the user of this number can be found with:
# grep ':998' /etc/passwd
# Which returns:
# gitlab-runner:x:998:997:GitLab Runner:/home/gitlab-runner:/bin/bash
# Hence it is assumed the /home/name/gitlab/data/gitlab-shell/ directory is owned by user: gitlab-runner
# TODO A: Write test that verifies the /home/name/gitlab/data/gitlab-shell directory exists

# TODO B: make directory 
# /home/name/gitlab/data/gitlab-shell/hooks
# TODO C: write test that verifies this directory is created
# TODO D: make the hooks directory owned by user: gitlab-runner
# TODO E: write test that verifies this directory is owned by user: gitlab-runner 

# TODO F: Create by user: gitlab-runner directory: 
# /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d
# TODO G: write test that verifies this directory is created
# TODO H: make the hooks directory owned by user: gitlab-runner
# TODO I: write test that verifies this directory is owned by user: gitlab-runner

# TODO J: Create file named post-receive in directory: 
# /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d
# Yielding:
# /home/name/gitlab/data/gitlab-shell/hooks/post-receive.d/post-receive
# TODO K: write test that verifies this file is created
# TODO L: Add content:
# #!/bin/bash
# echo "helloworld" | sudo tee ~/Desktop/helloworld.txt
# TODO M: verify content is created
# TODO N: make the post-receive file owned by user: gitlab-runner
# TODO I: write test that verifies this post-receive file is owned by user: gitlab-runner