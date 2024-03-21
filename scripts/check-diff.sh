#!/usr/bin/env bash

set -euo pipefail -o nounset

# If the script is run with RUNNER_DEBUG=1, print all statements executed
if [[ "${RUNNER_DEBUG:-}" == "1" ]]; then
  set -x
fi

language="$(jq -r '.github.languages | .[0]' <<< "$CONTEXT")"

default_branch="$(jq -r '.github.default_branch' <<< "$CONTEXT")"

pushd "$TARGET" > /dev/null

actual="$(git diff "origin/$default_branch" | grep '^[+-]')"
expected=""

if [[ "$language" == "Go" ]]; then
  expected='--- a/.github/workflows/go-check.yml
+++ b/.github/workflows/go-check.yml
-    uses: pl-strflt/uci/.github/workflows/go-check.yml@v0.0
+    uses: ipdxco/unified-github-workflows/.github/workflows/go-check.yml@v1.0
--- a/.github/workflows/go-test.yml
+++ b/.github/workflows/go-test.yml
-    uses: pl-strflt/uci/.github/workflows/go-test.yml@v0.0
+    uses: ipdxco/unified-github-workflows/.github/workflows/go-test.yml@v1.0
+    secrets:
+      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
--- a/.github/workflows/release-check.yml
+++ b/.github/workflows/release-check.yml
-    uses: pl-strflt/uci/.github/workflows/release-check.yml@v0.0
+    uses: ipdxco/unified-github-workflows/.github/workflows/release-check.yml@v1.0
--- a/.github/workflows/releaser.yml
+++ b/.github/workflows/releaser.yml
-    uses: pl-strflt/uci/.github/workflows/releaser.yml@v0.0
+    uses: ipdxco/unified-github-workflows/.github/workflows/releaser.yml@v1.0
--- a/.github/workflows/tagpush.yml
+++ b/.github/workflows/tagpush.yml
-    uses: pl-strflt/uci/.github/workflows/tagpush.yml@v0.0
+    uses: ipdxco/unified-github-workflows/.github/workflows/tagpush.yml@v1.0'
elif [[ "$language" == "JavaScript" ]]; then
  expected='--- a/.github/workflows/js-test-and-release.yml
+++ b/.github/workflows/js-test-and-release.yml
+  id-token: write
+  pull-requests: write
-    uses: pl-strflt/uci/.github/workflows/js-test-and-release.yml@v0.0
+    uses: ipdxco/unified-github-workflows/.github/workflows/js-test-and-release.yml@v1.0
+      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}'
else
  echo "Unknown language: $language"
  exit 1
fi

if [[ "$actual" == "$expected" ]]; then
  echo "No diff found"
  exit 0
else
  echo "Diff found"
  echo "$actual"
  echo "---"
  echo "$expected"
  exit 1
fi
