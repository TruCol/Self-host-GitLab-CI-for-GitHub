#! /bin/bash

TRACE=""
CP=$$ # PID of the script itself [1]

while true
do
        CMDLINE=$(cat /proc/$CP/cmdline)
        PP=$(grep PPid /proc/$CP/status | awk '{ print $2; }') # [2]
        TRACE="$TRACE [$CP]:$CMDLINE\n"
        if [ "$CP" == "1" ]; then # reach 'init' [PID 1] => backtrace end
                break
        fi
        CP=$PP
done
echo "Backtrace of '$0'"
echo -en "$TRACE" | tac | grep -n ":" # using tac to "print in reverse" [3]
