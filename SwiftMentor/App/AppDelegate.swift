import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
            .environmentObject(AppState.shared)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window?.minSize = NSSize(width: 1200, height: 800)
        window?.title = "SwiftMentor"
        window?.center()
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)
        window?.titlebarAppearsTransparent = false
        window?.toolbarStyle = .unified

        setupMainMenu()
        setupToolbar()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "About SwiftMentor", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit SwiftMentor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu

        fileMenu.addItem(withTitle: "New Playground", action: #selector(newPlayground), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open Lesson...", action: #selector(openLesson), keyEquivalent: "o")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu

        viewMenu.addItem(withTitle: "Dashboard", action: #selector(showDashboard), keyEquivalent: "1")
        viewMenu.addItem(withTitle: "Learning Paths", action: #selector(showLearningPaths), keyEquivalent: "2")
        viewMenu.addItem(withTitle: "Playground", action: #selector(showPlayground), keyEquivalent: "3")
        viewMenu.addItem(withTitle: "Progress", action: #selector(showProgress), keyEquivalent: "4")
        viewMenu.addItem(withTitle: "AI Assistant", action: #selector(showAIAssistant), keyEquivalent: "5")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Toggle Sidebar", action: #selector(toggleSidebar), keyEquivalent: "s")

        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")

        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)
        let helpMenu = NSMenu(title: "Help")
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "SwiftMentor Help", action: #selector(showHelp), keyEquivalent: "?")

        NSApp.mainMenu = mainMenu
    }

    private func setupToolbar() {
        guard let window = window else { return }

        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        window.toolbar = toolbar
    }

    @objc func openSettings() {
        AppState.shared.selectedSection = .settings
    }

    @objc func newPlayground() {
        AppState.shared.selectedSection = .playground
    }

    @objc func openLesson() {
        AppState.shared.selectedSection = .learningPaths
    }

    @objc func showDashboard() {
        AppState.shared.selectedSection = .dashboard
    }

    @objc func showLearningPaths() {
        AppState.shared.selectedSection = .learningPaths
    }

    @objc func showPlayground() {
        AppState.shared.selectedSection = .playground
    }

    @objc func showProgress() {
        AppState.shared.selectedSection = .progress
    }

    @objc func showAIAssistant() {
        AppState.shared.showAIAssistant = true
    }

    @objc func toggleSidebar() {
        AppState.shared.showSidebar.toggle()
    }

    @objc func showHelp() {
        if let url = URL(string: "https://github.com/swiftmentor/help") {
            NSWorkspace.shared.open(url)
        }
    }
}

extension AppDelegate: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .toggleSidebar,
            .flexibleSpace,
            .init("search"),
            .init("progress"),
            .init("aiAssistant"),
            .space,
            .init("settings")
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "search":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Search"
            item.paletteLabel = "Search"
            item.toolTip = "Search lessons and content"
            item.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Search")
            item.action = #selector(handleSearch)
            return item
        case "progress":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Progress"
            item.paletteLabel = "Progress"
            item.toolTip = "View your learning progress"
            item.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Progress")
            item.action = #selector(handleProgress)
            return item
        case "aiAssistant":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "AI Assistant"
            item.paletteLabel = "AI Assistant"
            item.toolTip = "Open AI coding assistant"
            item.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "AI Assistant")
            item.action = #selector(showAIAssistant)
            return item
        case "settings":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Settings"
            item.paletteLabel = "Settings"
            item.toolTip = "Open settings"
            item.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: "Settings")
            item.action = #selector(openSettings)
            return item
        default:
            return nil
        }
    }

    @objc func handleSearch() {
        AppState.shared.showingSearch = true
    }

    @objc func handleProgress() {
        AppState.shared.selectedSection = .progress
    }
}