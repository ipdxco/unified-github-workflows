#!/usr/bin/env bash

set -euo pipefail -o nounset

# If the script is run with RUNNER_DEBUG=1, print all statements executed
if [[ "${RUNNER_DEBUG:-}" == "1" ]]; then
  set -x
fi

force="$(jq -r '.config.force' <<< "$CONTEXT")"

root="$(pwd)"

pushd "$TARGET" > /dev/null

for f in $(jq -r '.config.files[] // []' <<< "$CONTEXT"); do
  if [[ -f "$f" && "$force" != "true" ]]; then
    if [[ "$f" != ".github/workflows/stale-issue.yml" && "$f" != ".github/workflows/semantic-pull-request.yml" ]]; then
      echo "$f already exists. Skipping."
      continue
    fi
  fi

  dir="$(dirname "$f")"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
  fi

  echo "Rendering template $f..."
  $root/$SOURCE/scripts/render-template.sh "$root/$SOURCE/templates/$f" "$CONTEXT" "$f"

  git add "$f"
  if ! git diff-index --quiet HEAD; then
    git commit -m "chore: add or force update $f"
  fi
done

if [[ "$force" != "true" ]]; then
  if [[ -f ".github/dependabot.yml" ]]; then
    gha="$(yq '.updates | map(select(.["package-ecosystem"] == "github-actions")) | length' .github/dependabot.yml)"
    if [[ "$gha" -gt 0 ]]; then
      echo "Dependabot is already configured to update GitHub Actions. Skipping."
      exit 0
    fi
  fi

  # https://gist.github.com/mattt/e09e1ecd76d5573e0517a7622009f06f
  gh gist view --raw e09e1ecd76d5573e0517a7622009f06f | bash

  plan="$(mktemp)"
  file1="$(mktemp)"
  file2="$(mktemp)"
  file3="$(mktemp)"

  dependabot update github_actions "$TARGET" --local . --output "$plan"

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

  for f in $(jq -r '.config.files[] // []' <<< "$CONTEXT"); do
    if [[ ! -f "$f" ]]; then
      echo "$f does not exist. Skipping."
      continue
    fi

    git add "$f"
    if ! git diff-index --quiet HEAD -- "$f"; then
      git commit -m "chore: update $f"
    fi
  done

  git reset --hard
fi

popd > /dev/null
