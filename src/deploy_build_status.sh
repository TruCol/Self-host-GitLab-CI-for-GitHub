#!/bin/bash

source src/helper.sh
source src/hardcoded_variables.txt
#source src/creds.txt
source src/create_personal_access_token.sh

# 0. Check if deployment ssh-key is generated
# 1. Generate deployment ssh-key if not generated
# 2. Ask user to add deployment key to github repo.
# 3. Verify the deployment ssh-key works
# 4. Pull https://github.com/a-t-0/website-build-statuses
# 5. Check if the repo already contains the test file. If not:
# 5.not: Add example file
# 5.yes remove the example file
# 6. Push changes
# 7. Delete repository
# 8. Clone repository
# 9.not: check if file is added
# 10.not: check if file is removed

# After that get the gitlab repository, 