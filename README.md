# Description to set up a GitLab server, Website and SSH over tor (for a Raspberry Pi 4b)

This repository first sets up wifi on a Raspberry Pi 4b (with 4gb ram) and then it starts the following services:
 - A GitLab server
 - A GitLab runner
 - A website
 - An SSH connection
 all accessible over tor. These services are started using a cronjob.
 
 ## First-time usage Raspberry Pi 4B
 Copy the `first_time_rpi_4b.sh` script to the Raspberry Pi 4B via a USB stick with code:
```
```
TODO: automatically download this GitHub and automatically set up the cronjob to establish the Tor connection upon boot.
TODO: Scan for private input data to claim accompanying domains.
TODO: Ensure that the SSH access is set up automatically towards the parent pc.

## Establish Tor connection upon boot:
Create a cronjob that runs the file:
`torssh.sh`

## Setup GitLab server
TODO: Run script that sets up GitLab server once the tor connection is enabled.
TODO: Create script to restore complete repositories with a single command, from a running GitLab docker (with an older/newer version of that repository).
TODO: Create script to restore complete repositories with a single command, from a running GitLab docker (without that repository).
TODO: Create script to restore complete repositories with a single command, from a new installation.
TODO: Create script that detects once the GitLab repository has been established, continuously monitor and reboot upon failure.

## Setup Website
TODO: Run script that sets up website server once the tor connection is enabled.
TODO: Create script that detects once the Website has been established, continuously monitor and reboot upon failure.

## Setup SSH service upon boot
TODO: Create script that adds a cronjob for this task.
TODO: Create script that verifies the SSH is available.