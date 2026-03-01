#!/usr/bin/env bash

set -euo pipefail -o nounset

# If the script is run with RUNNER_DEBUG=1, print all statements executed
if [[ "${RUNNER_DEBUG:-}" == "1" ]]; then
  set -x
fi

pushd "$TARGET" > /dev/null

npm install
npm install "aegir@^v47.0.26" --save-dev

git add .

if ! git diff-index --quiet HEAD; then
  git commit -m "chore(deps): update aegir to v47.0.26" --no-verify
fi

popd > /dev/null
