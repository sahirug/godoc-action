#!/bin/bash

set -eo pipefail

cd "$(dirname "$(find . -name 'go.mod' | head -n 1)")" || exit 1

MODULE_ROOT="$(go list -m)"
echo "Module root is $MODULE_ROOT"
REPO_NAME="$(basename $(echo $GITHUB_REPOSITORY))"
# PR_NUMBER="$(echo $GITHUB_REF | sed 's#refs/heads/\(.*\)/.*#\1#')"
PR_NUMBER="master"

echo "PR number is $PR_NUMBER"

mkdir -p "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
cp -r * "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
(godoc -http localhost:8080 &)

echo "module root is $MODULE_ROOT"
for (( ; ; )); do
  sleep 0.5
  if [[ $(curl -so /dev/null -w '%{http_code}' "http://localhost:8080/pkg/$MODULE_ROOT/") -eq 200 ]]; then
    break
  fi
done

git checkout origin/gh-pages || git checkout -b gh-pages

# wget --quiet --mirror --show-progress --page-requisites --execute robots=off --no-parent "http://localhost:8080/pkg/$MODULE_ROOT/"
wget --no-parent -r -l inf -p -k "http://localhost:8080/pkg/$MODULE_ROOT/"

echo "listing directory"
ls -la

rm -rf doc lib "$PR_NUMBER" # Delete previous documents.
[ -d "$PR_NUMBER" ] || mkdir "$PR_NUMBER" 
mv localhost:8080/* .
mv pkg $PR_NUMBER
rm -rf localhost:8080
# find pkg -type f -exec sed -i "s#/lib/godoc#/$REPO_NAME/lib/godoc#g" {} +
echo "listing $PR_NUMBER"
ls -la $PR_NUMBER

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"

git add "$PR_NUMBER"
git commit -m "Update documentation"

GODOC_URL="https://$(dirname $(echo $GITHUB_REPOSITORY)).github.io/$REPO_NAME/$PR_NUMBER/pkg/$MODULE_ROOT/index.html"
echo "url is $GODOC_URL"

# if ! curl -sH "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" | grep '## GoDoc' > /dev/null; then
#   curl -sH "Authorization: token $GITHUB_TOKEN" \
#     -d '{ "body": "## GoDoc\n'"$GODOC_URL"'" }' \
#     "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments"
# fi
