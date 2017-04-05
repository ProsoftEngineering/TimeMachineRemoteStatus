// Copyright © 2016, Prosoft Engineering, Inc. (A.K.A "Prosoft")
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Prosoft nor the names of its contributors may be
//       used to endorse or promote products derived from this software without
//       specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PROSOFT ENGINEERING, INC. BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    var statusImage: NSImage!
    let fmt = DateFormatter()
    let backupsManager = BackupsManager()
    var prefsController: PreferencesController!
    var scheduleTimer: Timer!
    var nextScheduledUpdate: Date!
    var lastUpdatedItem: NSMenuItem!
    var updateCount = 0
    var backups: [String: BackupHost] = [:]
    var lastUpdate: Date?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: ["WarningNumDays": 1])

        statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        statusImage = NSImage(named: "img")
        statusItem?.alternateImage = colorizeImage(image: statusImage, color: NSColor.white)

        fmt.doesRelativeDateFormatting = true
        fmt.timeStyle = .short
        fmt.dateStyle = .short
        
        NotificationCenter.default.addObserver(forName: PreferencesController.hostsDidUpdateNotification, object: nil, queue: nil, using: {(_) in
            self.startUpdate()
        })
        NSWorkspace.shared().notificationCenter.addObserver(forName: .NSWorkspaceDidWake, object: nil, queue: nil, using: {(_) in
            self.updateCycle()
        })
        
        updateCycle()
    }
    
    func colorizeImage(image: NSImage, color: NSColor) -> NSImage {
        let newImage = NSImage(size: image.size)
        newImage.lockFocus()
        let rect = NSMakeRect(0, 0, image.size.width, image.size.height)
        image.draw(in: rect, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
        color.setFill()
        NSRectFillUsingOperation(rect, .sourceAtop)
        newImage.unlockFocus()
        return newImage
    }
    
    func updateCycle() {
        startUpdate()
        scheduleNextUpdate()
    }
    
    func startUpdate() {
        updateCount = updateCount + 1
        
        if let hosts = UserDefaults().value(forKey: "Hosts") as? [String] {
            backupsManager.hosts = hosts
        }
        
        buildMenu() // to show "Updating..."
        backupsManager.update { (backups: [String : BackupHost]) -> (Void) in
            self.updateCount = self.updateCount - 1
            self.lastUpdate = Date()
            self.backups = backups
            self.buildMenu()
        }
    }
    
    func buildMenu() {
        let menu = NSMenu()
        var error = false
        let now = NSDate()
        var warning = false
        let secondsInADay = 86400
        let warningNumDays = Double(secondsInADay * UserDefaults.standard.integer(forKey: "WarningNumDays"))
        
        // Sort backup keys (hosts) based on their order in the original hosts array
        let backupsKeys = backups.keys.sorted { (s1: String, s2: String) -> Bool in
            // Indexes can be nil if a host is removed or renamed
            let index1 = backupsManager.hosts.index(of: s1)
            let index2 = backupsManager.hosts.index(of: s2)
            let s1 = index1 != nil ? index1! : Int.max
            let s2 = index2 != nil ? index2! : Int.max
            return s1 < s2
        }

        for host in backupsKeys {
            let backupHost = backups[host]
            let hostItem = NSMenuItem(title: host, action: nil, keyEquivalent: "")
            menu.addItem(hostItem)
            if let backups = backupHost?.backups.sorted(by: { $0.date > $1.date }), backups.count > 0 {
                let item = backups[0]
                let dateStr = fmt.string(from: item.date)
                let titleStr = String(format: NSLocalizedString("Latest Backup to \"%@\":", comment: ""), item.volumeName)
                let titleItem = NSMenuItem(title: titleStr, action: nil, keyEquivalent: "")
                let dateItem = NSMenuItem(title: dateStr, action: nil, keyEquivalent: "")
                titleItem.indentationLevel = 1
                dateItem.indentationLevel = 1
                menu.addItem(titleItem)
                menu.addItem(dateItem)
                if now.timeIntervalSince(item.date) > warningNumDays {
                    warning = true
                }
            } else {
                let errorItem = NSMenuItem(title: NSLocalizedString("Error", comment: ""), action: #selector(showError), keyEquivalent: "")
                errorItem.target = self
                errorItem.representedObject = backupHost!
                menu.addItem(errorItem)
                error = true
            }
            menu.addItem(NSMenuItem.separator())
        }

        let lastUpdateItemTitle: String
        if lastUpdate == nil {
            lastUpdateItemTitle = NSLocalizedString("Updated: Never", comment: "")
        } else {
            lastUpdateItemTitle = String(format: NSLocalizedString("Updated: %@", comment: ""), fmt.string(from: lastUpdate!))
        }
        lastUpdatedItem = NSMenuItem(title: lastUpdateItemTitle, action: nil, keyEquivalent: "")
        updateLastUpdatedItemToolTip()
        let updateItem: NSMenuItem
        if updateCount == 0 {
            updateItem = NSMenuItem(title: NSLocalizedString("Update Now", comment: ""), action: #selector(startUpdate), keyEquivalent: "")
        } else {
            updateItem = NSMenuItem(title: NSLocalizedString("Updating…", comment: ""), action: nil, keyEquivalent: "")
        }
        updateItem.target = self
        menu.addItem(lastUpdatedItem)
        menu.addItem(updateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: NSLocalizedString("Preferences", comment: ""), action: #selector(showPreferences), keyEquivalent: "")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let aboutStr = String(format: NSLocalizedString("About %@", comment: ""), NSRunningApplication.current().localizedName!)
        let aboutItem = NSMenuItem(title: aboutStr, action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(NSApp.terminate), keyEquivalent: "")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        
        if error {
            statusItem?.image = colorizeImage(image: statusImage, color: NSColor.red)
        } else if warning {
            statusItem?.image = colorizeImage(image: statusImage, color: NSColor(calibratedRed:0.50, green:0.00, blue:1.00, alpha:1.0))
        } else {
            statusItem?.image = statusImage
        }
        statusItem?.menu = menu
    }
    
    func updateLastUpdatedItemToolTip() {
        if lastUpdatedItem == nil {
            return
        }
        if nextScheduledUpdate != nil {
            lastUpdatedItem.toolTip = String(format: NSLocalizedString("Next Update: %@", comment: ""), fmt.string(from: nextScheduledUpdate))
        } else {
            lastUpdatedItem.toolTip = nil
        }
    }
    
    func showError(sender: Any?) {
        if let item = sender as? NSMenuItem, let backupHost = item.representedObject as? BackupHost {
            let alert = NSAlert()
            alert.informativeText = backupHost.error
            alert.alertStyle = .critical
            alert.runModal()
        }
    }
    
    func showPreferences(sender: Any?) {
        if prefsController == nil {
            prefsController = PreferencesController()
        }
        NSApp.activate(ignoringOtherApps: true)
        prefsController?.window?.makeKeyAndOrderFront(sender)
    }
    
    func showAbout(sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }
    
    func scheduleNextUpdate() {
        // Update every hour at X:30
        guard let cal = NSCalendar(calendarIdentifier: .gregorian) else {
            print("ERROR: Got nil calendar")
            return
        }
        let now = Date()
        let nowComps = cal.components([.hour, .minute], from: now)
        let scheduledMinute = 30
        // If we're under 1 minute of the scheduled time, use the current hour. Otherwise use the next hour
        let hour: Int
        if nowComps.minute! < (scheduledMinute - 1) {
            hour = nowComps.hour!
        } else {
            hour = nowComps.hour! + 1
        }
        guard let scheduledDate = cal.date(bySettingHour: hour, minute: scheduledMinute, second: 0, of: now) else {
            print("ERROR: Got nil date")
            return
        }
        
        nextScheduledUpdate = scheduledDate
        
        let timerBlock = {(timer: Timer) in
            self.updateCycle()
        }
        if scheduleTimer != nil {
            scheduleTimer.invalidate()
        }
        scheduleTimer = Timer(fire: scheduledDate, interval: 0, repeats: false, block: timerBlock)
        RunLoop.current.add(scheduleTimer, forMode: RunLoopMode.defaultRunLoopMode)
        
        updateLastUpdatedItemToolTip()
    }
}
