//
//  SwiftFSMAsyncTests.swift
//  SwiftFSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import XCTest
@testable import SwiftFSM

class SwiftFSMAsyncTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSelfTransitionMachine() {
        
        let expectation = self.expectation(description: "")
        
        
        let machine = FSMAsync<Int, Int>()
        
        try! machine.setStates(states: [1, 2, 3, 4])
        try! machine.setTerminalStates(initial: 1, finish: 4)
        
        try! machine.addEnterHandler(forState: 1) { (_,_) in
            machine.processEvent(event: 12)
        }
        
        try! machine.addEnterHandler(forState: 2) { (_,_) in
            machine.processEvent(event: 23)
        }
        
        try! machine.addEnterHandler(forState: 3) { (_,_) in
            machine.processEvent(event: 34)
        }
        
        try! machine.addEnterHandler(forState: 4) { (_,_) in
            expectation.fulfill()
        }
        
        try! machine.addTransition(from: 1, to: 2, event: 12, condition: nil)
        try! machine.addTransition(from: 2, to: 3, event: 23, condition: nil)
        try! machine.addTransition(from: 3, to: 4, event: 34, condition: nil)
        
        machine.startMachine()
        
        waitForExpectations(timeout: 1.0) { (error) in
            
            XCTAssertNil(error)
            XCTAssertFalse(machine.isStarted)
            XCTAssertEqual(machine.currentState, 4)
        }
    }
    
}
