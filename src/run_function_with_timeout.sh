#!/bin/bash

# Run with:
# bash -c eg_func
# bash -c "source run_function_with_timeout.sh && eg_func"
# or:
# export -f eg_func
# timeout 10s bash -c eg_func
eg_func() {
    local output_path="$1"
	local arg2="$2"
	local arg3="$3"
	
	
    if [ "$TMP_GITLAB_BUILD_STATUS_FILEPATH" != "" ]; then

        ############
        for i in {0..4..1}
        do
           echo "Welcome $i times, "arg1=$arg1" TMP_GITLAB_BUILD_STATUS_FILEPATH=$TMP_GITLAB_BUILD_STATUS_FILEPATH"
           sleep 1
        done
        echo "pending" > "$TMP_GITLAB_BUILD_STATUS_FILEPATH"

        ###### END OF ACTUAL FUNCTION
    else
        echo "ERROR, TMP_GITLAB_BUILD_STATUS_FILEPATH is empty."
    fi
}

# bash -c "source src/run_function_with_timeout.sh && some_func"
some_func() {
 echo "Bash version ${BASH_VERSION}..."
 for i in {0..10..1}; do
        echo "Welcome $i times"
        if test $i -ge 3; then
            break
        fi
 done
}