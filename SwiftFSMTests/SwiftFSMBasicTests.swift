//
//  SwiftFSMBasicTests.swift
//  SwiftFSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import XCTest

@testable import SwiftFSM

class SwiftFSMBasicTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimpleLinearSequence() {
        
        // FSM
        // (.1) - 12 -> (2) - 23 -> (3.)
        //
        
        let machine = FSMachineBasic<Int, Int>()
        
        machine.setStates(states: [1, 2, 3])
        machine.setTerminalStates(initial: 1, finish: 3)
        
        var callsCounter = 0
        
        machine.addStateEnterHandler(state: 2) { (state, event) in
            XCTAssert(state == 2)
            XCTAssert(event == 12)
            
            callsCounter += 1
        }
        
        machine.addStateLeaveHandler(state: 2) { (state, event) in
            XCTAssert(state == 2)
            XCTAssert(event == 23)
            
            callsCounter += 1
        }
        
        machine.addStateEnterHandler(state: 3) { (state, event) in
            XCTAssert(state == 3)
            XCTAssert(event == 23)
            
            callsCounter += 1
        }
        
        machine.setFinishHandler { (state, isTerminated) in
            XCTAssert(state == 3)
            XCTAssert(isTerminated == false)
            
            XCTAssert(callsCounter == 3)
        }
        
        machine.addTransition(from: 1, to: 2, event: 12, condition: nil)
        machine.addTransition(from: 2, to: 3, event: 23, condition: nil)
        
        machine.startMachine()
        machine.processEvent(event: 12)
        machine.processEvent(event: 23)
        
        XCTAssert(machine.isStarted() == false)
        XCTAssert(machine.getCurrentState() == 3)
    }
    
    
}
