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
