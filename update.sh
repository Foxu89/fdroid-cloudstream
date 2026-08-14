#!/bin/bash

cd metascoop
echo "::group::Building metascoop executable"
go build -o metascoop
echo "::endgroup::"

echo "::group::Downloading CloudStream pre-release APK"
PRERELEASE_ASSET_URL=$(curl -fsSL -H "Authorization: Bearer $GH_ACCESS_TOKEN" https://api.github.com/repos/recloudstream/cloudstream/releases/tags/pre-release | python3 -c "import sys,json; data=json.load(sys.stdin); apk=[a for a in data['assets'] if a['name'].endswith('.apk')][0]; print(apk['browser_download_url'])")
curl -fL --retry 3 -o ../fdroid/repo/cloudstream-prerelease_pre-release.apk "$PRERELEASE_ASSET_URL" || { echo "Failed to download CloudStream pre-release APK"; exit 1; }
echo "::endgroup::"

./metascoop -ap=../apps.yaml -rd=../fdroid/repo -pat="$GH_ACCESS_TOKEN" $1
EXIT_CODE=$?
cd ..

echo "Scoop had an exit code of $EXIT_CODE"

set -e

if [ $EXIT_CODE -eq 2 ]; then
    # Exit code 2 means that there were no significant changes
    echo "This means that there were no significant changes"
    exit 0
elif [ $EXIT_CODE -eq 0 ]; then
    # Exit code 0 means that we can commit everything & push

    echo "This means that we now have changes we should push"

    git config --global user.name 'github-actions'
    git config --global user.email '41898282+github-actions[bot]@users.noreply.github.com'

    git add .
    git commit -m"Automated update"
    git push "https://x-access-token:${GH_ACCESS_TOKEN}@github.com/Foxu89/fdroid-cloudstream.git" HEAD:main
else 
    echo "This is an unexpected error"

    exit $EXIT_CODE
fi
