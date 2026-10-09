import Foundation

var failures = 0
func expect(_ name: String, _ actual: String, _ expected: String) {
    if actual == expected {
        print("ok   \(name)")
    } else {
        failures += 1
        print("FAIL \(name)\n  expected: \(expected)\n  actual:   \(actual)")
    }
}

expect("フラグメントを取り除く",
       baseURL("https://github.com/a/b/issues/1#issuecomment-9"),
       "https://github.com/a/b/issues/1")
expect("クエリ文字列を取り除く",
       baseURL("https://x.slack.com/archives/C1/p123?thread_ts=1.2"),
       "https://x.slack.com/archives/C1/p123")
expect("#と?が両方あれば先に現れた方で切る",
       baseURL("https://a.com/p#h?x=1"),
       "https://a.com/p")
expect("パスが空の http(s) URL には / を補う",
       baseURL("https://example.com"),
       "https://example.com/")
expect("クエリだけ付いたホスト URL にも / を補う",
       baseURL("https://example.com?x=1"),
       "https://example.com/")
expect("GitHub PR は /files 以降を切り捨てる",
       baseURL("https://github.com/o/r/pull/1179/files"),
       "https://github.com/o/r/pull/1179")
expect("GitHub PR は /changes とフラグメントも同じ PR にそろえる",
       baseURL("https://github.com/o/r/pull/1179/changes#diff-abc"),
       "https://github.com/o/r/pull/1179")
expect("番号だけの GitHub PR URL はそのまま",
       baseURL("https://github.com/o/r/pull/12"),
       "https://github.com/o/r/pull/12")
expect("/pull/ を含まない GitHub URL はそのまま",
       baseURL("https://github.com/o/r/pulls"),
       "https://github.com/o/r/pulls")
expect("GitHub 以外の /pull/ は切り捨てない",
       baseURL("https://example.com/pull/1/files"),
       "https://example.com/pull/1/files")
expect("file URL は # 以降だけ取り除き、/ は補わない",
       baseURL("file:///tmp/a%20b.html#top"),
       "file:///tmp/a%20b.html")

expect("計測ログは経路・合計・各ステップ・前面アプリの遷移を1行にする",
       routeLogLine(route: "focus",
                    sinceLaunchMs: 73,
                    steps: [("windows", 2.4), ("tabs", 33.6), ("select", 18)],
                    totalMs: 55.2,
                    frontBefore: "com.mitchellh.ghostty",
                    frontAfter: "com.google.Chrome"),
       "focus total=55ms sinceLaunch=73ms windows=2ms tabs=34ms select=18ms com.mitchellh.ghostty -> com.google.Chrome")
expect("ステップが無い経路でもログ行が崩れない",
       routeLogLine(route: "chrome-not-running",
                    sinceLaunchMs: 4800,
                    steps: [],
                    totalMs: 4.9,
                    frontBefore: "",
                    frontAfter: ""),
       "chrome-not-running total=5ms sinceLaunch=4800ms  ->")

expect("設定の profile を読む",
       parseProfile(Data(#"{"profile":"Profile 2"}"#.utf8)) ?? "nil",
       "Profile 2")
expect("profile が無い設定は nil",
       parseProfile(Data("{}".utf8)) ?? "nil",
       "nil")
expect("壊れた JSON は nil",
       parseProfile(Data("not json".utf8)) ?? "nil",
       "nil")
expect("空文字の profile は nil",
       parseProfile(Data(#"{"profile":""}"#.utf8)) ?? "nil",
       "nil")

exit(failures == 0 ? 0 : 1)
