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
        machine.setStates(states: states)
    }
    
    public func setTerminalStates(initial: State, finish: State?) {
        machine.setTerminalStates(initial: initial, finish: finish)
    }
    
    public func addStateEnterHandler(state: State, handler: HandlerBlock) {
        machine.addStateEnterHandler(state: state, handler: handler)
    }
    
    public func addStateLeaveHandler(state: State, handler: HandlerBlock) {
        machine.addStateLeaveHandler(state: state, handler: handler)
    }
    
    public func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) {
        machine.addTransition(from: from, to: to, event: event, condition: condition)
    }
    
    public func setNoTransitionHandler(handler: HandlerBlock) {
        machine.setNoTransitionHandler(handler: handler)
    }
    
    public func setFinishHandler(handler: FinishBlock) {
        machine.setFinishHandler(handler: handler)
    }
    
    public func startMachine() {
        queue.addOperation { [weak self] in
            self?.machine.startMachine()
        }
    }
    
    public func processEvent(event: Event) {
        queue.addOperation { [weak self] in
            self?.machine.processEvent(event: event)
        }
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
