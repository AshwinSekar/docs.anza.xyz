#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

LATEST_AGAVE_RELEASE_VERSION=v4.3.0-rc.0
VERSION_FOR_DOCS_RS="${LATEST_AGAVE_RELEASE_VERSION:1}"

set -x
if [[ -n $CI ]]; then
  sed --version || { echo "Error: Incompatible version of sed, use gnu sed"; exit 1; }
  find src/ -name \*.md -exec sed -i "s/LATEST_AGAVE_RELEASE_VERSION/$LATEST_AGAVE_RELEASE_VERSION/g" {} \;
  find src/ -name \*.md -exec sed -i "s/VERSION_FOR_DOCS_RS/$VERSION_FOR_DOCS_RS/g" {} \;
fi
