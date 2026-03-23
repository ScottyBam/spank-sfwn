import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var config: SpankConfig = .defaults
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        loadConfigOrWait()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let img = NSImage(systemSymbolName: "hand.raised.fill", accessibilityDescription: "spank") {
            img.isTemplate = true
            statusItem.button?.image = img
        } else {
            statusItem.button?.title = "spank"
        }
        statusItem.button?.toolTip = "spank"
    }

    // MARK: - Config loading

    private func loadConfigOrWait() {
        if FileManager.default.fileExists(atPath: SpankConfig.configURL.path) {
            reloadConfig()
            rebuildMenu()
        } else {
            showWaitingMenu()
            startWaitingPoll()
        }
    }

    private func reloadConfig() {
        config = (try? SpankConfig.read()) ?? .defaults
    }

    private func saveConfig() {
        try? config.write()
    }

    // MARK: - Waiting state

    private func showWaitingMenu() {
        let menu = NSMenu()
        let item = NSMenuItem(title: "Waiting for daemon…", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
        menu.addItem(.separator())
        menu.addItem(quitItem())
        statusItem.menu = menu
    }

    private func startWaitingPoll() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            if FileManager.default.fileExists(atPath: SpankConfig.configURL.path) {
                self.pollTimer?.invalidate()
                self.pollTimer = nil
                self.reloadConfig()
                self.rebuildMenu()
            }
        }
    }

    // MARK: - Menu construction

    func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        // Enabled toggle
        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = config.enabled ? .on : .off
        menu.addItem(enabledItem)
        menu.addItem(.separator())

        // Nikke characters (dynamic)
        let nikkeChars = SpankConfig.discoverNikkeCharacters()
        for char in nikkeChars {
            let packValue = "nikke/\(char)"
            let item = NSMenuItem(title: char, action: #selector(selectPack(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = packValue
            item.state = config.pack == packValue ? .on : .off
            menu.addItem(item)
        }
        if !nikkeChars.isEmpty { menu.addItem(.separator()) }

        // Embedded packs
        for (title, value) in [("Pain", "pain"), ("Sexy", "sexy"), ("Halo", "halo")] {
            let item = NSMenuItem(title: title, action: #selector(selectPack(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = config.pack == value ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())

        // Toggles
        menu.addItem(toggleItem("Escalation", keyPath: \.escalate, action: #selector(toggleEscalate)))
        menu.addItem(toggleItem("Fast mode", keyPath: \.fast, action: #selector(toggleFast)))
        menu.addItem(toggleItem("Volume scaling", keyPath: \.volumeScaling, action: #selector(toggleVolumeScaling)))
        menu.addItem(.separator())

        // Submenus
        menu.addItem(submenuItem("Sensitivity", items: [
            ("0.05 (default)", 0.05), ("0.10", 0.10), ("0.15", 0.15), ("0.25", 0.25), ("0.40", 0.40)
        ], current: config.sensitivity, action: #selector(selectSensitivity(_:))))

        menu.addItem(submenuItem("Speed", items: [
            ("0.5×", 0.5), ("0.75×", 0.75), ("1× (default)", 1.0), ("1.5×", 1.5), ("2×", 2.0)
        ], current: config.speed, action: #selector(selectSpeed(_:))))

        menu.addItem(submenuItem("Cooldown", items: [
            ("350ms", 350.0), ("500ms", 500.0), ("750ms (default)", 750.0), ("1000ms", 1000.0)
        ], current: Double(config.cooldown), action: #selector(selectCooldown(_:))))

        menu.addItem(.separator())
        menu.addItem(quitItem())

        statusItem.menu = menu
    }

    private func toggleItem(_ title: String, keyPath: KeyPath<SpankConfig, Bool>, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = config[keyPath: keyPath] ? .on : .off
        return item
    }

    private func submenuItem(_ title: String, items: [(String, Double)], current: Double, action: Selector) -> NSMenuItem {
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for (label, value) in items {
            let item = NSMenuItem(title: label, action: action, keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = abs(current - value) < 0.001 ? .on : .off
            sub.addItem(item)
        }
        parent.submenu = sub
        return parent
    }

    private func quitItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return item
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        config.enabled.toggle()
        saveConfig()
        rebuildMenu()
    }

    @objc private func selectPack(_ sender: NSMenuItem) {
        guard let pack = sender.representedObject as? String else { return }
        config.pack = pack
        saveConfig()
        rebuildMenu()
    }

    @objc private func toggleEscalate() {
        config.escalate.toggle(); saveConfig(); rebuildMenu()
    }

    @objc private func toggleFast() {
        config.fast.toggle(); saveConfig(); rebuildMenu()
    }

    @objc private func toggleVolumeScaling() {
        config.volumeScaling.toggle(); saveConfig(); rebuildMenu()
    }

    @objc private func selectSensitivity(_ sender: NSMenuItem) {
        guard let v = sender.representedObject as? Double else { return }
        config.sensitivity = v; saveConfig(); rebuildMenu()
    }

    @objc private func selectSpeed(_ sender: NSMenuItem) {
        guard let v = sender.representedObject as? Double else { return }
        config.speed = v; saveConfig(); rebuildMenu()
    }

    @objc private func selectCooldown(_ sender: NSMenuItem) {
        guard let v = sender.representedObject as? Double else { return }
        config.cooldown = Int(v); saveConfig(); rebuildMenu()
    }
}

// Rebuild menu on open so it reflects current config (catches external changes)
extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        reloadConfig()
        rebuildMenu()
    }
}
