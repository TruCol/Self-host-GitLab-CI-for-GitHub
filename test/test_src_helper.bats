#!./test/libs/bats/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

source src/import.sh
#source src/boot_tor.sh

example_lines=$(cat <<-END
First line
second line 
third line 
sometoken
END
)


