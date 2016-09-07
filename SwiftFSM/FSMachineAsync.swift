//
//  FSMachineAsync.swift
//  SwiftFSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import Foundation

public class FSMachineAsync<State, Event> : FSMachineProtocol, FSMachineAsyncProtocol
    where State: Hashable, Event: Hashable {
    
    public typealias ConditionBlock = (State, State, Event) -> Bool
    public typealias HandlerBlock = (State, Event?) -> Void
    public typealias FinishBlock = (State, Bool) -> Void
    
    public init() {
        machine = FSMachineBasic<State, Event>()
        
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        lock = NSLock()
    }
    
    // MARK: FSMachineProtocol
    
    public func setStates(states: [State]) {
    }
    
    public func setTerminalStates(initial: State, finish: State?) {
    
    }
    
    public func addStateEnterHandler(state: State, handler: HandlerBlock) {
    }
    
    public func addStateLeaveHandler(state: State, handler: HandlerBlock) {
    
    }
    
    public func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) {
    
    }
    
    public func setNoTransitionHandler(handler: HandlerBlock) {
    
    }
    
    public func setFinishHandler(handler: FinishBlock) {
    
    }
    
    public func startMachine() {
    }
    
    public func processEvent(event: Event) {
    
    }
    
    public func terminateMachine() {
    
    }
    
    public func isStarted() -> Bool {
        return machine.isStarted()
    }
    
    public func getCurrentState() -> State? {
        return machine.getCurrentState()
    }
    
    // MARK: FSMachineAsyncProtocol
    
    public func pauseMachine() {
    }
    
    public func resumeMachine() {
    }
    
    public func clearEventsQueue() {
    }

    // MARK:
    
    let machine: FSMachineBasic<State, Event>
    let queue: OperationQueue
    let lock: NSLock

}
