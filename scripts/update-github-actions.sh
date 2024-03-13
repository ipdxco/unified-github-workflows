#!/usr/bin/env bash

set -euo pipefail -o nounset

# If the script is run with RUNNER_DEBUG=1, print all statements executed
if [[ "${RUNNER_DEBUG:-}" == "1" ]]; then
  set -x
fi

plan="$(mktemp)"
file1="$(mktemp)"
file2="$(mktemp)"
file3="$(mktemp)"

dependabot update github_actions org/repo --local . --output "$plan"

while read -r pr; do
  if [[ -z "$pr" ]]; then
    continue
  fi
  while read -r f; do
    if [[ -z "$f" ]]; then
      continue
    fi
    name="$(jq -r '.name' <<< "$f")"
    cp -f "$name" "$file1"
    jq -j '.content' <<< "$f" > "$file2"
    git show HEAD:"$name" > "$file3"
    for i in $(seq 1 "$(wc -l < "$file3")"); do
      line1="$(sed -n "${i}p" "$file1")"
      line2="$(sed -n "${i}p" "$file2")"
      line3="$(sed -n "${i}p" "$file3")"
      if [[ "$line1" == "$line3" ]]; then
        echo "$line2"
      elif [[ "$line2" == "$line3" ]]; then
        echo "$line1"
      else
        echo "$line3"
      fi
    done > "$name"
  done <<< "$(jq -c '.["updated-dependency-files"] | .[] // []' <<< "$pr")"
done <<< "$(yq -c '.output | map(select(.type == "create_pull_request")) | map(.expect.data) | .[]' "$plan")"
