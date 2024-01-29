# Function to display error message and exit
error_exit() {
    echo "$1" >&2
    exit 1
}

# Check if gh is installed
if ! command -v gh &> /dev/null; then
  type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
fi

# Check if gh is installed
if ! command -v gh &> /dev/null; then
  error_exit "gh is not installed, make sure you run 'make init' (see README.md)."
fi

PACKAGE_NAME=$(grep 'applicationId' app/build.gradle | awk -F\" {'print $2'})
PACKAGE_VERSION=$(grep 'versionName' app/build.gradle | awk -F\" {'print $2'})
REPO=sentry-demos/android

# Check if current version was already released
currentVersion=$(gh release list | awk '{print $1}' | grep -x "$PACKAGE_VERSION")
if [ "$currentVersion" != "" ]; then
  error_exit "Version $PACKAGE_VERSION was already released."
fi

# Build the release bundle
echo "Building the release bundle..."
./gradlew assemble


echo "Releasing to Github..."
gh release create $PACKAGE_VERSION app/build/outputs/apk/debug/app-debug.apk app/build/outputs/apk/release/app-release.apk -t "$PACKAGE_VERSION" --generate-notes || error_exit "Failed to create GitHub release."

echo "Release created successfully with version $PACKAGE_VERSION!"


