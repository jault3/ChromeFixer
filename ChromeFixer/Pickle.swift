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

import Foundation

struct Pickle {
    let content: NSData
    var payloadLen = 0
    var location = 0
    
    init(_ content: NSData) {
        self.content = content
    }
    
    mutating func initializePayload() {
        // read 4 bytes as uint32 for the payloadLen
        content.getBytes(&payloadLen, range: NSRange(location: 0, length: 4))
        location = content.length - payloadLen
    }
    
    mutating func resetLocation() {
        location = content.length - payloadLen
    }

    mutating func readUInt32() -> UInt32 {
        var u32: UInt32 = 0
        content.getBytes(&u32, range: NSRange(location: location, length: 4))
        location += 4
        return u32
    }
    
    mutating func readString() -> String {
        let strLen = Int(readUInt32())
        // apparently this can be too large? TODO figure out how/when/why
        let subData = content.subdataWithRange(NSRange(location: location, length: strLen))
        location += strLen
        return String(data: subData, encoding: NSUTF8StringEncoding) ?? "Invalid string"
    }
}