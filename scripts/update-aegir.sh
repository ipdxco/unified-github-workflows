#!/usr/bin/env bash

set -euo pipefail -o nounset

# If the script is run with RUNNER_DEBUG=1, print all statements executed
if [[ "${RUNNER_DEBUG:-}" == "1" ]]; then
  set -x
fi

language="$(jq -r '.github.languages | map(select(. == "JavaScript")) | .[0]' <<< "$CONTEXT")"

if [[ "$language" != "JavaScript" ]]; then
  echo "Not a Node project. Skipping."
  exit 0
fi

pushd "$TARGET" > /dev/null
if [[ ! -f .github/workflows/js-test-and-release.yml ]]; then
  echo "No .github/workflows/js-test-and-release.yml file found. Skipping."
  exit 0
fi
popd > /dev/null

pushd "$TARGET" > /dev/null

npm install
npm install "aegir@^v47.0.26" --save-dev

git add .

if ! git diff-index --quiet HEAD; then
  git commit -m "chore(deps): update aegir to v47.0.26" --no-verify
fi

popd > /dev/null
