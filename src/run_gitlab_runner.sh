#!/bin/bash
#output=$(nohup sudo gitlab-runner run &>/dev/null &)
#bash --rcfile <(echo '. ~/.bashrc; sudo gitlab-runner run')
bash --rcfile <(echo '. ~/.bashrc; nohup sudo gitlab-runner run &>/dev/null &')
#sudo gitlab-runner run