#!/usr/bin/env bash

set -euo pipefail -o nounset

# If ACTIONS_RUNNER_DEBUG or ACTIONS_STEP_DEBUG is set to true, print all commands
if [[ "${ACTIONS_RUNNER_DEBUG:-}" == "true" || "${ACTIONS_STEP_DEBUG:-}" == "true" ]]; then
  set -x
fi

language="$(jq -r '.github.languages | map(select(. == "Go")) | .[0]' <<< "$CONTEXT")"

if [[ "$language" != "Go" ]]; then
  echo "Not a Go project. Skipping."
  exit 0
fi

expected="$(jq -r '.config.versions.go' <<< "$CONTEXT")"

tmp="$(mktemp -d)"
pushd "$tmp" > /dev/null
curl -sSfL "https://golang.org/dl/go$expected.linux-amd64.tar.gz" | tar -xz
export PATH="$tmp/go/bin:$PATH"
export GOPATH=$tmp/go
popd > /dev/null

echo "Go version: $(go version)"
echo "Go path: $(go env GOPATH)"

pushd "$TARGET" > /dev/null

while read file; do
  pushd "$(dirname "$file")" > /dev/null

  if go list -m -json all | jq -se 'map(select(.Path == "github.com/libp2p/go-libp2p")) | length != 0' > /dev/null; then
    go get -u github.com/libp2p/go-libp2p
  elif go list -m -json all | jq -se 'map(select(.Path == "github.com/quic-go/quic-go")) | length != 0' > /dev/null; then
    go get -u github.com/quic-go/quic-go
  fi

  git add .

  if ! git diff-index --quiet HEAD; then
    git commit -m "chore: bump go-libp2p and/or quic-go to latest version"
  fi

  popd > /dev/null
done <<< "$(git ls-tree --full-tree --name-only -r HEAD | grep 'go\.mod$')"

popd > /dev/null
