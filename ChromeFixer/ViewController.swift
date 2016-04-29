/*
 MIT License
 
 Copyright (c) 2016 Josh Ault
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Cocoa

protocol CommandProtocol {
    func isTab() -> Bool
    func tabId() -> UInt32
    func index() -> UInt32
    func url() -> String
}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var tblView: NSTableView!
    
    let currentTabsFile = "\(NSHomeDirectory())/Library/Application Support/Google/Chrome/Default/Current Tabs"
    let currentSessionFile = "\(NSHomeDirectory())/Library/Application Support/Google/Chrome/Default/Current Session"
    let snssMagic: Int32 = 0x53534E53
    var commands = [Command]()
    var tabs = [UInt32: [Command]]()
    var sessionFile = false
    
    class Command: CommandProtocol {
        var pickle: Pickle
        var keep = true
        
        init(_ content: NSData) {
            pickle = Pickle(content)
        }
        
        func isTab() -> Bool { return false }
        func tabId() -> UInt32 { return 0 }
        func index() -> UInt32 { return 0 }
        func url() -> String { return "" }
        
        // this double class init method is ugly.
        
        class func initFromIdType(idType: UInt8, content: NSData) -> Command {
            switch idType {
            case 1:
                return CommandUpdateTabNavigation(content)
            case 2:
                return CommandRestoredEntry(content)
            case 3:
                return CommandWindow(content)
            case 4:
                return CommandSelectedNavigationInTab(content)
            case 5:
                return CommandPinnedState(content)
            case 6:
                return CommandSetExtensionAppID(content)
            default:
                return Command(content)
            }
        }
        
        class func initFromIdTypeSession(idType: UInt8, content: NSData) -> Command {
            switch idType {
            case 0:
                return CommandSetTabWindow(content)
            case 2:
                return CommandSetTabIndexInWindow(content)
            case 3:
                return CommandTabClosed(content)
            case 4:
                return CommandWindowClosed(content)
            case 5:
                return CommandTabNavigationPathPrunedFromBack(content)
            case 6:
                return CommandUpdateTabNavigation(content)
            case 7:
                return CommandSetSelectedNavigationIndex(content)
            case 8:
                return CommandSetSelectedTabInIndex(content)
            case 9:
                return CommandSetWindowType(content)
            case 11:
                return CommandTabNavigationPathPrunedFromFront(content)
            case 12:
                return CommandSetPinnedState(content)
            case 13:
                return CommandSetExtensionAppID(content)
            case 14:
                return CommandSetWindowBounds3(content)
            default:
                return Command(content)
            }
        }

    }
    
    class CommandUpdateTabNavigation: Command, CustomStringConvertible {
        
        var description: String {
            return "Tab:\(tabId())-Index:\(index())"
        }
        
        override init(_ content: NSData) {
            super.init(content)
            pickle.initializePayload()
        }
        
        override func isTab() -> Bool {
            return true
        }
        
        override func tabId() -> UInt32 {
            pickle.resetLocation()
            return pickle.readUInt32()
        }
        
        override func index() -> UInt32 {
            pickle.resetLocation()
            // pass up the first uint32 which is the tabID
            pickle.location = pickle.location + 4
            return pickle.readUInt32()
        }
        
        override func url() -> String {
            pickle.resetLocation()
            // pass up the first uint32 which is the tabID, and the second uint32 which is the index
            pickle.location = pickle.location + 8
            return pickle.readString()
        }
    }
    
    // I might do something with these eventually 
    
    class CommandSetTabWindow: Command {}
        
    class CommandSetTabIndexInWindow: Command {}
        
    class CommandTabClosed: Command {}
        
    class CommandWindowClosed: Command {}
        
    class CommandTabNavigationPathPrunedFromBack: Command {}
    
    class CommandRestoredEntry: Command {}
    
    class CommandWindow: Command {}
    
    class CommandSelectedNavigationInTab: Command {}
    
    class CommandPinnedState: Command {}
    
    class CommandSetExtensionAppID: Command {}
        
    class CommandSetSelectedNavigationIndex: Command {}
    
    class CommandSetSelectedTabInIndex: Command {}
    
    class CommandSetWindowType: Command {}
    
    class CommandTabNavigationPathPrunedFromFront: Command {}
    
    class CommandSetPinnedState: Command {}
    
    class CommandSetWindowBounds3: Command {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tblView.setDelegate(self)
        tblView.setDataSource(self)
        
        reloadSNSSData(currentTabsFile)
        
        // detect if chrome is open, force kill it, then reload
        if detectChromeOpen() {
            print("detected chrome running")
            forceKillChrome()
            sessionFile = true
            refresh(0)
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func forceKillChrome() {
        print("kill -9'ing chrome")
        let chromeKill = "do shell script \"killall -9 'Google Chrome'\""
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: chromeKill) {
            scriptObject.executeAndReturnError(&error)
            if (error != nil) {
                print("failed to kill9 chrome: \(error)")
            }
        }
    }
    
    @IBAction func checkCurrentSessionFile(sender: AnyObject) {
        print("switching to session file")
        sessionFile = true
        refresh(0)
    }
    
    func detectChromeOpen() -> Bool {
        let chromeRunning = "if application \"Google Chrome\" is running then\n  return 1\nend if\nreturn 0"
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: chromeRunning) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
                return output.int32Value == 1
            } else if (error != nil) {
                print("chrome detection error: \(error)")
                return false
            }
        }
        return false
    }
    
    @IBAction func refresh(sender: AnyObject) {
        print("refreshing SNSS data")
        if sessionFile {
            reloadSNSSData(currentSessionFile)
        } else {
            reloadSNSSData(currentTabsFile)
        }
    }
    
    @IBAction func fixChrome(sender: AnyObject) {
        print("moving \(currentTabsFile) to \(currentTabsFile).old")
        do {
            try NSFileManager.defaultManager().removeItemAtPath("\(currentTabsFile).old")
        } catch {}
        do {
            try NSFileManager.defaultManager().moveItemAtPath(currentTabsFile, toPath: "\(currentTabsFile).old")
        } catch {
            print("failed to move \(currentTabsFile) file: \(error)")
            return
        }
        
        print("moving \(currentSessionFile) to \(currentSessionFile).old")
        do {
            try NSFileManager.defaultManager().removeItemAtPath("\(currentSessionFile).old")
        } catch {}
        do {
            try NSFileManager.defaultManager().moveItemAtPath(currentSessionFile, toPath: "\(currentSessionFile).old")
        } catch {
            print("failed to move \(currentSessionFile) file: \(error)")
            return
        }
        
        print("starting chrome and opening selected tabs")
        var args: [String] = ["open", "/Applications/Google Chrome.app", "--args"]
        for tabID in tabs.keys {
            if tabs[tabID]![0].keep {
                args.append(tabs[tabID]![0].url())
            }
        }
        print(args)
        
        let task = NSTask()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        print("task finished with status \(task.terminationStatus)")
    }
    
    func reloadSNSSData(filepath: String) {
        print("reading SNSS data from \(filepath)")
        if let snssData = NSData(contentsOfFile: filepath) {
            let len = snssData.length / sizeof(UInt8)
            
            // read 4 bytes as an int32 for the magic header
            var magic : Int32 = 0
            snssData.getBytes(&magic, range: NSRange(location: 0, length: 4))
            if magic != snssMagic {
                print("Bad magic number")
                return
            }
            
            // read 4 bytes as an int32 for the version
            var version : Int32 = 0
            snssData.getBytes(&version, range: NSRange(location: 4, length: 4))
            if version == 0 {
                print("Bad version")
                return
            }
            
            commands = [Command]()
            var location = 8
            // loop through to the end over commands
            while location < len {
                // read 2 bytes as a uint16 for the commandSize
                var commandSize : UInt16 = 0
                snssData.getBytes(&commandSize, range: NSRange(location: location, length: 2))
                location += 2
                
                // read 1 byte as a uint8 for the idType
                var idType : UInt8 = 0
                snssData.getBytes(&idType, range: NSRange(location: location, length: 1))
                location += 1
                
                // read the next commandSize-1 for the content (-1 because commandSize includes idType length)
                let contentLen = Int(commandSize) - 1
                let content = snssData.subdataWithRange(NSRange(location: location, length: contentLen))
                location += contentLen
                
                if filepath == currentSessionFile {
                    commands.append(Command.initFromIdTypeSession(idType, content: content))
                } else {
                    commands.append(Command.initFromIdType(idType, content: content))
                }
            }
            tabs = [UInt32: [Command]]()
            for c in commands {
                if c.isTab() {
                    if tabs[c.tabId()] == nil {
                        tabs[c.tabId()] = [Command]()
                    }
                    tabs[c.tabId()]!.append(c)
                }
            }
            for tabID in tabs.keys {
                // reversed sorting so we can take [0]
                tabs[tabID]!.sortInPlace({ $0.index() > $1.index() })
            }
            tblView.reloadData()
        }
    }

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return tabs.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        var g = tabs.keys.generate()
        for _ in 0..<row {
            g.next()
        }
        let tabID = g.next()! as UInt32
        let c = tabs[tabID]![0]
        
        if tableColumn == tableView.tableColumns[0] {
            return c.keep
        } else {
            return c.url()
        }
    }
    
    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        var g = tabs.keys.generate()
        for _ in 0..<row {
            g.next()
        }
        let tabID = g.next()! as UInt32
        let c = tabs[tabID]![0]
        c.keep = object!.boolValue
    }
}

