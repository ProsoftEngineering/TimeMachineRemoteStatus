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

import Foundation

class Backup: NSObject {
    let volumeName: String
    let date: Date
    
    init(volumeName aVolumeName: String, date aDate: Date) {
        self.volumeName = aVolumeName
        self.date = aDate
    }
}

class BackupHost: NSObject {
    var backups: [Backup] = []
    var error: String = ""
}

class BackupsManager: NSObject {
    
    var hosts: [String] = []
    let regex: NSRegularExpression
    let cal = NSCalendar(calendarIdentifier: .gregorian)
    
    override init() {
        do {
            // /Volumes/Drive/Backups.backupdb/hostname/2016-11-15-164402
            regex = try NSRegularExpression(pattern: "^/Volumes/(.*?)/.*/(\\d{4,4})-(\\d{2,2})-(\\d{2,2})-(\\d{2,2})(\\d{2,2})(\\d{2,2})", options: [])
        } catch let error as NSError {
            print("Invalid regex: \(error.localizedDescription)")
            exit(-1)
        }
    }

    func update() -> [String: BackupHost] {
        var backups = [String: BackupHost]()
        
        for host in hosts {
            if backups[host] == nil {
                backups[host] = BackupHost()
            }
            let result = Process.run(launchPath: "/usr/bin/ssh", args: [host, "tmutil", "listbackups"])
            if result.status != 0 {
                backups[host]?.error = result.error
                continue
            }
            
            for line in result.output.components(separatedBy: "\n") {
                if line.isEmpty {
                    continue
                }
                let txt = line as NSString
                let results = regex.matches(in: line, options: [], range: NSMakeRange(0, txt.length))
                for result in results {
                    if result.numberOfRanges == 8 {
                        let volumeName = txt.substring(with: result.rangeAt(1))
                        var comps = DateComponents()
                        comps.year = Int(txt.substring(with: result.rangeAt(2)))!
                        comps.month = Int(txt.substring(with: result.rangeAt(3)))!
                        comps.day = Int(txt.substring(with: result.rangeAt(4)))!
                        comps.hour = Int(txt.substring(with: result.rangeAt(5)))!
                        comps.minute = Int(txt.substring(with: result.rangeAt(6)))!
                        comps.second = Int(txt.substring(with: result.rangeAt(7)))!
                        let date = cal?.date(from: comps)
                        
                        backups[host]?.backups.append(Backup(volumeName: volumeName, date: date!))
                    } else {
                        print("Unknown line: \(line)")
                    }
                }
            }
        }
        
        return backups
    }

}
