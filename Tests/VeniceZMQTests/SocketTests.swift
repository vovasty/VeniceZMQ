// Error.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2016 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
import Venice
@testable import VeniceZMQ

class VeniceZMQTests: XCTestCase {
    func testPushPull() throws {
        var called = false
        let context = try Context()
        
        let outbound = try context.socket(.push)
        try outbound.connect("tcp://127.0.0.1:5555")
        
        try outbound.send("Hello World!")
        try outbound.send("Bye!")

        let inbound = try context.socket(.pull)
        try inbound.bind("tcp://127.0.0.1:5555")

        while let data = try inbound.receiveString() , data != "Bye!" {
            called = true
            XCTAssert(data == "Hello World!")
        }
        
        XCTAssert(called)
    }
    
    func testRouterDealer() throws {
        let numClients = 10
        
        let context = try Context()
        
        var received = 0
        let completed = Channel<Void>()
        
        let server = try context.socket(.router)
        try server.bind("inproc://test")
        
        for _ in 0..<numClients {
            co {
                do {
                    let id = try server.receiveMessage(.ReceiveMore)
                    
                    let query = try server.receiveString()
                    
                    XCTAssertEqual(query, "How are you?")
                    
                    try server.send(id, mode: .SendMore)
                    try server.send("I am good")
                }
                catch {
                    XCTAssert(false)
                }
            }
        }
        
        for _ in 0..<numClients {
            co {
                do {
                    let client = try context.socket(.dealer)
                    try client.connect("inproc://test")
                    try! client.send("How are you?")
                    let reply = try client.receiveString()
                    XCTAssertEqual("I am good", reply)
                    
                    received += 1
                    
                    if received == numClients {
                        completed.send()
                    }
                }
                catch {
                    XCTAssert(false)
                }
            }
        }
        
        completed.receive()
        
    }

}

extension VeniceZMQTests {
    static var allTests: [(String, (VeniceZMQTests) -> () throws -> Void)] {
        return [
            ("testPushPull", testPushPull), ("testRouterDealer", testRouterDealer)
        ]
    }
}
