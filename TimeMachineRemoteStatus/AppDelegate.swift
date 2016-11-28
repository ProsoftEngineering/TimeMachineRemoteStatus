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
    let fmt = DateFormatter()
    let backupsManager = BackupsManager()
    var prefsController: PreferencesController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        statusItem?.image = NSImage(named: "img")
        statusItem?.alternateImage = NSImage(named: "imgalt")

        fmt.doesRelativeDateFormatting = true
        fmt.timeStyle = .short
        fmt.dateStyle = .short
        
        update()
        
        let didChangeHandler = {(notif: Notification) in
            self.update()
        }
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil, using: didChangeHandler)
    }
    
    func update() {
        if let hosts = UserDefaults().value(forKey: "Hosts") as? [String] {
            backupsManager.hosts = hosts
        }
        
        let backups = backupsManager.update()
        
        let menu = NSMenu()

        for host in backups.keys.sorted() {
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
            } else {
                let errorItem = NSMenuItem(title: NSLocalizedString("Error", comment: ""), action: #selector(showError), keyEquivalent: "")
                errorItem.target = self
                errorItem.representedObject = backupHost!
                menu.addItem(errorItem)
            }
            menu.addItem(NSMenuItem.separator())
        }

        let lastUpdatedItem = NSMenuItem(title: String(format: NSLocalizedString("Updated: %@", comment: ""), fmt.string(from: Date())), action: nil, keyEquivalent: "")
        let updateItem = NSMenuItem(title: NSLocalizedString("Update Now", comment: ""), action: #selector(update), keyEquivalent: "")
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
        
        statusItem?.menu = menu
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
}
