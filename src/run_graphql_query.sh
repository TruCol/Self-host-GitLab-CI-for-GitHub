#!/usr/bin/env bash
# Runs graphql query on GitHub. Execute with:
# src/./run_graphql_query.sh src/examplequery14.gql

source src/import.sh

if [ $# -ne 1 ]; then
    echo "usage of this script is incorrect."
    exit 1
fi

if [ ! -f $1 ];then
    echo "usage of this script is incorrect."
    exit 1
fi

# Form query JSON
QUERY=$(jq -n \
           --arg q "$(cat $1 | tr -d '\n')" \
           '{ query: $q }')


curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $GITHUB_PERSONAL_ACCESS_TOKEN_GLOBAL" \
  --data "$QUERY" \
  https://api.github.com/graphql
