#!/bin/bash
set -e

function cleanUp {
    if [[ -d "publish" ]]; then
        git worktree remove --force publish
    fi
}
trap cleanUp EXIT

dart run build_runner build --delete-conflicting-outputs
webdev build

git worktree add publish gh-pages
cp -R build/* publish

pushd publish
git add .
git commit -m "Publish" --allow-empty
git push
popd
