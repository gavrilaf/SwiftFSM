//
//  FSMachineAsync.swift
//  SwiftFSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import Foundation

public class FSMachineAsync<State, Event> : FSMachineProtocol where State: Hashable, Event: Hashable {
    
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
    
    public func setStates(states: [State]) throws {
        try machine.setStates(states: states)
    }
    
    public func setTerminalStates(initial: State, finish: State?) throws {
        try machine.setTerminalStates(initial: initial, finish: finish)
    }
    
    public func addStateEnterHandler(state: State, handler: HandlerBlock) throws {
        try machine.addStateEnterHandler(state: state, handler: handler)
    }
    
    public func addStateLeaveHandler(state: State, handler: HandlerBlock) throws {
        try machine.addStateLeaveHandler(state: state, handler: handler)
    }
    
    public func addStateNoTransitionHandler(state: State, handler: HandlerBlock) throws {
        try machine.addStateNoTransitionHandler(state: state, handler: handler)
    }
    
    public func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) throws {
        try machine.addTransition(from: from, to: to, event: event, condition: condition)
    }
    
    public func setGlobalNoTransitionHandler(handler: HandlerBlock) {
        machine.setGlobalNoTransitionHandler(handler: handler)
    }
    
    public func setFinishHandler(handler: FinishBlock) {
        machine.setFinishHandler(handler: handler)
    }
    
    public func setErrorHandler(handler: ((Error) -> Void)) {
        machine.setErrorHandler(handler: handler)
    }
    
    public func startMachine() {
        queue.addOperation { [weak self] in
            self?.syncBlock {
                self?.machine.startMachine()
            }
        }
    }
    
    public func processEvent(event: Event) {
        queue.addOperation { [weak self] in
            self?.syncBlock {
                self?.machine.processEvent(event: event)
            }
        }
    }
    
    public func terminateMachine() {
       cancelAllEvents()
        
        syncBlock {
            machine.terminateMachine()
        }
    }
    
    public func isStarted() -> Bool {
        
        var isStarted: Bool = false
        
        syncBlock {
            isStarted = machine.isStarted()
        }
        
        return isStarted
    }
    
    public func getCurrentState() -> State? {
        
        var state: State? = nil
        
        syncBlock {
            state = machine.getCurrentState()
        }
        
        return state
    }
    
    // MARK:
    
    private func syncBlock(block: () -> Void) {
        defer {
            lock.unlock()
        }
        
        lock.lock()
        block()
    }

    // MARK:
    
    let machine: FSMachineBasic<State, Event>
    let queue: OperationQueue
    let lock: NSLock

}

extension FSMachineAsync: FSMachineAsyncProtocol {
    
    public var isPaused: Bool {
        get {
            return queue.isSuspended
        }
        
        set {
            queue.isSuspended = isPaused
        }
    }
    
    public func cancelAllEvents() {
        queue.cancelAllOperations()
    }
}
