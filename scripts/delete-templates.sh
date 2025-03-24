#!/usr/bin/env bash

set -euo pipefail -o nounset

for f in $(jq -r '.config.files // [] | .[]' <<< "$CONTEXT"); do
  echo -e "\nProcessing $f."
  if [[ ! -f "$TARGET/$f" ]]; then
    echo "$f does not exist. Skipping.\n"
    continue
  fi

  rm -rf "$TARGET/$f"
done

pushd $TARGET > /dev/null

git add .

if ! git diff-index --quiet HEAD; then
  git commit -m "chore: delete templates [skip ci]"
fi

popd > /dev/null
