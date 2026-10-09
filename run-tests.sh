#!/bin/sh
set -e
cd "$(dirname "$0")"
out=$(mktemp -d)
swiftc -o "$out/tests" Sources/URLNormalizer.swift Sources/RouteLog.swift Sources/Config.swift Tests/main.swift -module-name tests
"$out/tests"
