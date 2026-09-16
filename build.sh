#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mode="${1:---install}"
if [[ "$mode" != "--install" && "$mode" != "--check" ]]; then
    printf 'Usage: %s [--install|--check]\n' "$0" >&2
    exit 2
fi
# Keep exactly one installed app; Spotlight ignores the intermediate directory.
mkdir -p .build.noindex
compiled=.build.noindex/LookBack
xcrun swiftc -swift-version 5 -O -target "$(uname -m)-apple-macos14.0" Sources/*.swift -o "$compiled" -framework AppKit -framework CoreMotion -framework CoreAudio
plutil -lint Info.plist
if [[ "$mode" == "--check" ]]; then
    printf 'Build verified. Installed application was not changed.\n'
    exit 0
fi
app_path=/Applications/LookBack.app
if pgrep -x LookBack >/dev/null; then
    printf 'Quit LookBack with Command-Q before installing this update.\n' >&2
    exit 1
fi
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$compiled" "$app_path/Contents/MacOS/LookBack"
cp Info.plist "$app_path/Contents/Info.plist"
cp Resources/AppIcon.icns "$app_path/Contents/Resources/AppIcon.icns"
cp LICENSE HeadOrbit-LICENSE "$app_path/Contents/Resources/"
codesign --force --sign - "$app_path"
codesign --verify --deep --strict "$app_path"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app_path"
mdimport "$app_path"
printf 'Installed: %s\n' "$app_path"
