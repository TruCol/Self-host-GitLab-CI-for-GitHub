
# Assert that values are not equal.
# Fail and display details if the expected and actual values do
# equal. Details include both values.
#
# Globals:
#   none
# Arguments:
#   $1 - actual value
#   $2 - unexpected value
# Returns:
#   0 - values do not equal
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_not_equal() {
  if [[ $1 == "$2" ]]; then
    batslib_print_kv_single_or_multi 8 \
        'expected not' "$2" \
        'actual      ' "$1" \
      | batslib_decorate 'values do not equal' \
      | fail
  fi
}

# Assert that the first value contains the second value.
# Otherwise fail and display details. Details include both values.
#
# Globals:
#   none
# Arguments:
#   $1 - value to test
#   $2 - content
# Returns:
#   0 - $1 contains $2
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_contain() {
  if [[ $1 != *$2* ]]; then
    batslib_print_kv_single_or_multi 8 \
        'value            ' "$1" \
        'expected content ' "$2" \
      | batslib_decorate 'assertion failed' \
      | fail
  fi
}

# Assert that the first value starts with the second value.
# Otherwise fail and display details. Details include both values.
#
# Globals:
#   none
# Arguments:
#   $1 - value to test
#   $2 - expected prefix
# Returns:
#   0 - $1 starts with $2
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_start_with() {
  if [[ $1 != $2* ]]; then
    batslib_print_kv_single_or_multi 8 \
        'value           ' "$1" \
        'expected prefix ' "$2" \
      | batslib_decorate 'assertion failed' \
      | fail
  fi
}

# Assert that the first value ends with the second value.
# Otherwise fail and display details. Details include both values.
#
# Globals:
#   none
# Arguments:
#   $1 - value to test
#   $2 - expected postfix
# Returns:
#   0 - $1 ends with $2
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_end_with() {
  if [[ $1 != *$2 ]]; then
    batslib_print_kv_single_or_multi 8 \
        'value            ' "$1" \
        'expected postfix ' "$2" \
      | batslib_decorate 'assertion failed' \
      | fail
  fi
}