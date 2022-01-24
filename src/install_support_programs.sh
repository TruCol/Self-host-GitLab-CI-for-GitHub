#!/bin/bash

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:status
# Returns "FOUND" if the service is found, NOTFOUND otherwise
# TODO: write test for case when apache2 is actually running.
apache2_is_running() {
	status=$(sudo service apache2 --status-all)
	#cmd="$(lines_contain_string "unrecognized service" "\${status}")"
	#"$(lines_contain_string "unrecognized service" "\${status}")"
	lines_contain_string "unrecognized service" "\${status}"
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:status
# Returns "FOUND" if the service is found, NOTFOUND otherwise
# TODO: write test for case when nginx is actually running.
nginx_is_running() {

	status=$(sudo service nginx --status-all)
	#cmd="$(lines_contain_string "unrecognized service" "\${status}")"
	lines_contain_string "unrecognized service" "\${status}"
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:status
# stop ngix service
stop_apache_service() {
	
	if [ "$(apache2_is_running)" == "FOUND" ]; then
		output=$(sudo service apache2 stop)
		echo "$output"
	fi
}

#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): include throwing warning if nginx was not found (but removed).
#######################################
# Structure:status
#source src/helper.sh && stop_nginx_service
stop_nginx_service() {
	local services_list=$(systemctl list-units --type=service)
	if [  "$(lines_contain_string "nginx" "${services_list}")" == "FOUND" ]; then
		output=$(sudo service nginx stop)
		echo "$output"
	fi

}