import AppKit
import ScriptingBridge

let chromeBundleID = "com.google.Chrome"
let chromeBinary = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
let logPath = "/tmp/chrome-router-activation.txt"
let processStart = DispatchTime.now()

func milliseconds(from start: DispatchTime, to end: DispatchTime = .now()) -> Double {
    Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
}

final class Router: NSObject, NSApplicationDelegate {
    private var chromePID: pid_t = 0
    private var chromeApplication: SBApplication?
    private var route = ""
    private var steps: [(String, Double)] = []
    private var lapStart = DispatchTime.now()

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            let start = DispatchTime.now()
            let sinceLaunch = milliseconds(from: processStart, to: start)
            let before = frontmostBundleID()
            route = ""
            steps = []
            lapStart = start
            openOrFocus(url.absoluteString)
            appendLog(routeLogLine(route: route,
                                   sinceLaunchMs: sinceLaunch,
                                   steps: steps,
                                   totalMs: milliseconds(from: start),
                                   frontBefore: before,
                                   frontAfter: frontmostBundleID()))
        }
    }

    private func lap(_ name: String) {
        let now = DispatchTime.now()
        steps.append((name, milliseconds(from: lapStart, to: now)))
        lapStart = now
    }

    private func openOrFocus(_ url: String) {
        let chromeProcess = normalChromeProcess()
        lap("lookup")
        guard let chrome = chromeProcess else {
            route = "chrome-not-running"
            launchChrome(url)
            lap("launch")
            return
        }
        let windows = chromeApplication(for: chrome).value(forKey: "windows") as? NSArray
        lap("windows")
        guard let windows, windows.count > 0 else {
            route = "no-window"
            launchChrome(url)
            lap("launch")
            return
        }
        let target = baseURL(url)
        let urlsPerWindow = windows.value(forKeyPath: "tabs.URL") as? [[Any]] ?? []
        lap("tabs")
        for (w, tabURLs) in urlsPerWindow.enumerated() {
            for (t, tabURL) in tabURLs.enumerated() {
                guard let tabURL = tabURL as? String, baseURL(tabURL) == target else { continue }
                let window = windows[w] as! NSObject
                if tabURL != url {
                    ((window.value(forKey: "tabs") as! NSArray)[t] as! NSObject).setValue(url, forKey: "URL")
                }
                window.setValue(t + 1, forKey: "activeTabIndex")
                window.setValue(1, forKey: "index")
                let raised = window.value(forKey: "index") as? Int == 1
                lap("select")
                route = raised ? "focus" : "focus-behind-pip"
                bringToFront(chrome)
                lap("front")
                return
            }
        }
        route = "no-matching-tab"
        launchChrome(url)
        lap("launch")
        bringToFront(chrome)
        lap("front")
    }

    private func bringToFront(_ chrome: NSRunningApplication) {
        chrome.activate(options: [.activateAllWindows])
        chromeApplication(for: chrome).activate()
    }

    private func chromeApplication(for chrome: NSRunningApplication) -> SBApplication {
        if let app = chromeApplication { return app }
        let app = SBApplication(processIdentifier: chrome.processIdentifier)!
        chromeApplication = app
        return app
    }

    private func normalChromeProcess() -> NSRunningApplication? {
        if chromePID != 0,
           let cached = NSRunningApplication(processIdentifier: chromePID),
           !cached.isTerminated {
            return cached
        }
        chromePID = 0
        chromeApplication = nil
        for process in NSRunningApplication.runningApplications(withBundleIdentifier: chromeBundleID) {
            let command = commandLine(of: process.processIdentifier)
            if !command.contains("--user-data-dir") && !command.contains("--remote-debugging") {
                chromePID = process.processIdentifier
                return process
            }
        }
        return nil
    }

    private func commandLine(of pid: pid_t) -> String {
        var mib = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 4 else { return "" }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else { return "" }
        let argc = buffer.withUnsafeBytes { $0.load(as: Int32.self) }
        var fields = buffer[4..<size].split(separator: 0, omittingEmptySubsequences: true)
        fields = Array(fields.prefix(Int(argc) + 1))
        return fields.map { String(decoding: $0, as: UTF8.self) }.joined(separator: " ")
    }

    private func launchChrome(_ url: String) {
        let chrome = Process()
        chrome.executableURL = URL(fileURLWithPath: chromeBinary)
        chrome.arguments = (loadProfile().map { ["--profile-directory=\($0)"] } ?? []) + [url]
        chrome.standardOutput = FileHandle.nullDevice
        chrome.standardError = FileHandle.nullDevice
        try? chrome.run()
    }

    private func frontmostBundleID() -> String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
    }

    private func appendLog(_ line: String) {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        let line = "\(formatter.string(from: Date())) \(line)"
        if !FileManager.default.fileExists(atPath: logPath) {
            FileManager.default.createFile(atPath: logPath, contents: nil)
        }
        guard let handle = FileHandle(forWritingAtPath: logPath) else { return }
        handle.seekToEndOfFile()
        handle.write(Data((line + "\n").utf8))
        handle.closeFile()
    }
}

let application = NSApplication.shared
let router = Router()
application.delegate = router
application.setActivationPolicy(.accessory)
application.run()
