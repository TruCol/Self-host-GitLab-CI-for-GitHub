mkdir -p test/libs

git submodule add -f https://github.com/bats-core/bats test/libs/bats
git submodule add -f https://github.com/bats-core/bats-support test/libs/bats-support
git submodule add -f https://github.com/bats-core/bats-assert test/libs/bats-assert
git submodule add -f https://github.com/bats-core/bats-file test/libs/bats-file