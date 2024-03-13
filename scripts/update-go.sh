#!/usr/bin/env bash

set -euo pipefail -o nounset

# If the script is run with RUNNER_DEBUG=1, print all statements executed
if [[ "${RUNNER_DEBUG:-}" == "1" ]]; then
  set -x
fi

language="$(jq -r '.github.languages | map(select(. == "Go")) | .[0]' <<< "$CONTEXT")"

if [[ "$language" != "Go" ]]; then
  echo "Not a Go project. Skipping."
  exit 0
fi

expected="$(jq -r '.config.versions.go' <<< "$CONTEXT")"
version="$(curl -sSfL https://go.dev/dl/\?mode\=json | jq -r --arg expected "$expected" 'map(.version) | map(select(startswith("go\($expected)"))) | .[0]')"

tmp="$(mktemp -d)"
pushd "$tmp" > /dev/null
curl -sSfL "https://golang.org/dl/$version.linux-amd64.tar.gz" | tar -xz
export PATH="$tmp/go/bin:$PATH"
export GOPATH=$tmp/go
popd > /dev/null

echo "Go version: $(go version)"
echo "Go path: $(go env GOPATH)"

go install golang.org/x/tools/cmd/goimports@v0.19.0

pushd "$TARGET" > /dev/null

while read file; do
  pushd "$(dirname "$file")" > /dev/null

  current="$(go list -m -json | jq 'select(.Dir == "'"$(pwd)"'")' | jq -r .GoVersion)"

  if [[ "$current" == "$expected" ]]; then
    echo "Go version $expected already in use."
    popd > /dev/null
    continue
  fi

  go mod tidy -go="$current" || true
  go mod tidy -go="$expected"

  # Remove the line starting with toolchain from the go.mod file
  sed -i '/^toolchain/d' go.mod

  go mod tidy

  go fix ./...

  git add .

  if ! git diff-index --quiet HEAD; then
    git commit -m "chore: bump go.mod to Go $expected and run go fix"
  fi

  if [[ -f go.work ]]; then
    go work use
    sed -i '/^toolchain/d' go.work
    go work use
    git add .
    if ! git diff-index --quiet HEAD; then
      git commit -m "chore: bump go.work to Go $expected"
    fi
  fi

  # As of Go 1.19 io/ioutil is deprecated
  # We automate its upgrade here because it is quite a widely used package
  while read file; do
    sed -i 's/ioutil.NopCloser/io.NopCloser/' "$file";
    sed -i 's/ioutil.ReadAll/io.ReadAll/' "$file";
    # ReadDir replacement might require manual intervention (https://pkg.go.dev/io/ioutil#ReadDir)
    sed -i 's/ioutil.ReadDir/os.ReadDir/' "$file";
    sed -i 's/ioutil.ReadFile/os.ReadFile/' "$file";
    sed -i 's/ioutil.TempDir/os.MkdirTemp/' "$file";
    sed -i 's/ioutil.TempFile/os.CreateTemp/' "$file";
    sed -i 's/ioutil.WriteFile/os.WriteFile/' "$file";
    sed -i 's/ioutil.Discard/io.Discard/' "$file";
  done <<< "$(find . -type f -name '*.go')"

  goimports -w .

  git add .
  if ! git diff-index --quiet HEAD; then
    git commit -m "fix: stop using the deprecated io/ioutil package"
  fi

  go mod tidy

  git add .
  if ! git diff-index --quiet HEAD; then
    git commit -m "chore: run go mod tidy"
  fi

  gofmt -s -w .

  git add .
  if ! git diff-index --quiet HEAD; then
    git commit -m "chore: run gofmt -s"
  fi

  popd > /dev/null
done <<< "$(git ls-tree --full-tree --name-only -r HEAD | grep 'go\.mod$')"

popd > /dev/null
