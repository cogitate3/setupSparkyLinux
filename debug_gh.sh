#!/usr/bin/env bash
source lib/log.sh
source lib/cmd.sh
source lib/gh.sh

repo="pot-app/pot-desktop"
regex=".*amd64.*\.deb$"

echo "Testing gh_latest_asset_url for $repo with regex $regex..."
url=$(gh_latest_asset_url "$repo" "$regex")
ret=$?

if [ $ret -eq 0 ]; then
    echo "SUCCESS: $url"
else
    echo "FAILED with code $ret"
fi
