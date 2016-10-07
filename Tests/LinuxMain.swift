#if os(Linux)

import XCTest
@testable import VeniceZMQ

XCTMain([
    testCase(VeniceZMQTests.allTests)
])

#endif
