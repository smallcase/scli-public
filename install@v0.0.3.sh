#!/bin/bash

set -e

# Determine platform (mac or linux)
PLATFORM="unknown"
case "$(uname -s)" in
    Darwin*)    PLATFORM="darwin";;
    Linux*)     PLATFORM="linux";;
esac

if [ "$PLATFORM" = "unknown" ]; then
    echo "Unsupported platform."
    exit 1
fi

# Check if an access token was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <access-token>"
    exit 1
fi

REPO="smallcase/scli"
TAG="v0.0.3"
ASSET_NAME="scli-$PLATFORM.tar.gz"
GH_PERSONAL_TOKEN=$1

ASSET_ID=$(curl -sH "Authorization: token $GH_PERSONAL_TOKEN" "https://api.github.com/repos/$REPO/releases/tags/$TAG" | grep -C3 "\"name\": \"$ASSET_NAME\"" | grep "\"id\":" | grep -o '[0-9]\+')

curl -L -H "Authorization: token $GH_PERSONAL_TOKEN" -H "Accept: application/octet-stream" "https://api.github.com/repos/$REPO/releases/assets/$ASSET_ID" -o $ASSET_NAME

# Extract the tarball
echo "Extracting the tarball..."
tar -xzvf $ASSET_NAME

# Make the binary executable
chmod +x "scli-$PLATFORM"

ROOT_BINARY_PATH=/usr/local/bin/scli

# Move the binary to a bin directory
sudo mv "scli-$PLATFORM" /usr/local/bin/scli

# Check if the ROOT_BINARY_PATH has the com.apple.quarantine attribute
if xattr "$ROOT_BINARY_PATH" | grep -q "com.apple.quarantine"; then
    echo "com.apple.quarantine attribute found. Attempting to remove..."
    xattr -d com.apple.quarantine "$ROOT_BINARY_PATH"

    # Verify if removal was successful
    if xattr "$ROOT_BINARY_PATH" | grep -q "com.apple.quarantine"; then
        echo "Failed to remove the com.apple.quarantine attribute."
    else
        echo "com.apple.quarantine attribute successfully removed."
    fi
else
    echo "No com.apple.quarantine attribute found on $ROOT_BINARY_PATH."
fi

echo "Installation completed successfully."
echo "You can now run 'scli' from the command line."
