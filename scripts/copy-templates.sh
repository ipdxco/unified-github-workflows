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
    echo "$f already exists. Skipping."
    continue
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

  tmp="$(mktemp)"

  dependabot update github_actions "$TARGET" --local . --output "$tmp"

  branch="$(git branch --show-current)"
  sha="$(git rev-parse HEAD)"

  while read -r pr; do
    title="$(jq -r '.["pr-title"]' <<< "$pr")"
    git checkout -b "$title" "$branch"
    for f in $(jq -r '.["updated-dependency-files"] | .[] // []' <<< "$pr"); do
      jq -r '.content' <<< "$f" > "$(jq -r '.name' <<< "$f")"
    done
    git add .
    if ! git diff-index --quiet HEAD; then
      git commit -m "$(jq -r '.["commit-message"]' <<< "$pr")"
    fi
    git checkout "$branch"
    git merge "$title" --strategy-option theirs
  done <<< "$(yq -c '.output | map(select(.type == "create_pull_request")) | map(.expect.data) | .[]' "$tmp")"

  git reset "$sha"

  for f in $(jq -r '.config.files[] // []' <<< "$CONTEXT"); do
    if [[ ! -f "$f" ]]; then
      echo "$f does not exist. Skipping."
      continue
    fi

    git add "$f"
    if ! git diff-index --quiet HEAD; then
      git commit -m "chore: update $f"
    fi
  done

  git reset --hard
fi

popd > /dev/null
