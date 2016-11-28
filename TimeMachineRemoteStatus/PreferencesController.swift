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

class PreferencesController: NSWindowController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var removeButton: NSButton!
    
    var hosts: [String] = []
    
    override var windowNibName : String! {
        return "Preferences"
    }
    
    override func windowDidLoad() {
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
    
}
