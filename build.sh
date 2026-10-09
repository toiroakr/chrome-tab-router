#!/bin/sh
# 使い方: ./build.sh [出力先.app]（省略時は ~/Applications/Chrome Tab Router.app）
# 署名 ID は SIGN_IDENTITY で指定できる。省略時は有効な Apple Development 証明書を使う。
# ad-hoc 署名はビルドごとに cdhash が変わり、Chrome 操作の許可（TCC）が再ビルドで失効するため、証明書が無い場合のみ使う。
set -e
cd "$(dirname "$0")"
app="${1:-$HOME/Applications/Chrome Tab Router.app}"
identity="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/^ *[0-9]*) \([0-9A-F]\{40\}\) "Apple Development:.*/\1/p' | head -1)}"
if [ -z "$identity" ]; then
  echo "warning: 署名用証明書が見つからないため ad-hoc 署名にする（再ビルドのたびに Chrome 操作の許可が失効する）" >&2
  identity="-"
fi
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
swiftc -O -o "$app/Contents/MacOS/ChromeTabRouter" Sources/URLNormalizer.swift Sources/RouteLog.swift Sources/Config.swift Sources/main.swift
cp Info.plist "$app/Contents/Info.plist"
[ -f AppIcon.icns ] && cp AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
codesign --force --deep -s "$identity" "$app"
echo "built: $app (signed with: $identity)"
