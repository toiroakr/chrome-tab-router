#!/bin/sh
# 使い方: ./install-launchagent.sh [app] （何度実行しても同じ状態に収束する）
# ログイン時に Chrome Tab Router を起動し、落ちたら自動で再起動して、リンクのクリック時にコールド起動にならないようにする。
set -e
app="${1:-$HOME/Applications/Chrome Tab Router.app}"
label="${LABEL:-com.toiroakr.chrome-tab-router}"
plist="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"
cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key><string>$label</string>
	<key>ProgramArguments</key>
	<array><string>$app/Contents/MacOS/ChromeTabRouter</string></array>
	<key>RunAtLoad</key><true/>
	<key>KeepAlive</key><true/>
	<key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
PLIST
launchctl bootout "$domain/$label" 2>/dev/null || true
launchctl bootstrap "$domain" "$plist"
echo "installed: $plist"
