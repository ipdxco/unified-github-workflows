#!/bin/bash

# Set the query here
QUERY="author:web3-bot is:pr is:open archived:false"

# Search for matching pull requests
RESPONSE=$(gh api --paginate search/issues -X GET -f q="$QUERY")
echo "$RESPONSE" | jq -r '.items[] | .url' | while read URL; do
  OWNER=$(echo "$URL" | cut -d'/' -f5)
  REPO=$(echo "$URL" | cut -d'/' -f6)
  PR=$(echo "$URL" | cut -d'/' -f8)
  echo "Closing pull request $PR in $OWNER/$REPO"
  gh pr close $PR -R $OWNER/$REPO
done
