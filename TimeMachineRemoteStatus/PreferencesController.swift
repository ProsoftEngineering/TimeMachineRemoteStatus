// Copyright © 2016-2017, Prosoft Engineering, Inc. (A.K.A "Prosoft")
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

class PreferencesController: NSWindowController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var removeButton: NSButton!
    
    static let hostsDidUpdateNotification = NSNotification.Name("PreferencesControllerHostsDidUpdateNotification")
    
    var hosts: [String] = []
    
    let HostsTableDragAndDropDataType = "HostsTableDragAndDropDataType"
    
    override var windowNibName : String! {
        return "Preferences"
    }
    
    override func windowDidLoad() {
        tableView.register(forDraggedTypes: [HostsTableDragAndDropDataType])

        if let hosts = UserDefaults().object(forKey: "Hosts") as? [String] {
            self.hosts = hosts
            tableView.reloadData()
        }
    }
    
    @IBAction func addHost(_ sender: AnyObject) {
        hosts.append("Host")
        tableView.reloadData()
        tableView.editColumn(0, row: hosts.count - 1, with: nil, select: true)
    }
    
    @IBAction func removeHost(_ sender: AnyObject) {
        for idx in tableView.selectedRowIndexes.reversed() {
            hosts.remove(at: idx)
        }
        tableView.reloadData()
        save()
    }
    
    func save() {
        UserDefaults().set(hosts, forKey: "Hosts")
        NotificationCenter.default.post(name: PreferencesController.hostsDidUpdateNotification, object: nil)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return hosts.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return hosts[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if let str = object as? String {
            hosts[row] = str
            save()
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        removeButton?.isEnabled = tableView.numberOfSelectedRows != 0
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes([HostsTableDragAndDropDataType], owner: self)
        pboard.setData(data, forType: HostsTableDragAndDropDataType)
        return true
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        return dropOperation == .above ? .move : NSDragOperation(rawValue: 0)
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        guard let rowIndexesData = info.draggingPasteboard().data(forType: HostsTableDragAndDropDataType) else {
            print("ERROR: Bad pboard data")
            return false
        }
        guard let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: rowIndexesData) as? IndexSet else {
            print("ERROR: Bad pboard archived data")
            return false
        }
        for idx in rowIndexes {
            if row == idx + 1 || row == idx {
                // No change
                continue
            }
            let host = hosts[idx]
            hosts.remove(at: idx)
            if row > hosts.count {
                hosts.append(host)
            } else if row > idx {
                hosts.insert(host, at: row - 1)
            } else {
                hosts.insert(host, at: row)
            }
        }
        save()
        return true
    }
    
}
