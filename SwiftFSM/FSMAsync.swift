//
//  FSMachineAsync.swift
//  SwiftFSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import Foundation

public class FSMAsync<State, Event> : FSMAsyncProtocol where State: Hashable, Event: Hashable {
    
    public typealias ConditionBlock = (State, State, Event) -> Bool
    public typealias HandlerBlock = (State, Event?) -> Void
    public typealias FinishBlock = (State, Bool) -> Void
    public typealias ErrorBlock = (Error) -> Void

    public init() {
        machine = FSMBasic<State, Event>()
        
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        lock = NSLock()
    }
    
    // MARK: FSMAsyncProtocol
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

    
    // MARK: FSMProtocol
    public var logger: FSMLogger {
        get { return machine.logger }
        set { machine.logger = newValue }
    }
    
    public var isStarted: Bool {
        return machine.isStarted
    }
    
    public var currentState: State? {
        return machine.currentState
    }
    
    
    public func setStates(states: [State]) throws {
        try machine.setStates(states: states)
    }
    
    public func setTerminalStates(initial: State, finish: State?) throws {
        try machine.setTerminalStates(initial: initial, finish: finish)
    }
    
    public func addEnterHandler(forState state: State, handler: @escaping HandlerBlock) throws {
        try machine.addEnterHandler(forState: state, handler: handler)
    }
    
    public func addLeaveHandler(forState state: State, handler: @escaping HandlerBlock) throws {
        try machine.addLeaveHandler(forState: state, handler: handler)
    }
    
    public func addNoTransitionHandler(forState state: State, handler: @escaping HandlerBlock) throws {
        try machine.addNoTransitionHandler(forState: state, handler: handler)
    }
    
    public func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) throws {
        try machine.addTransition(from: from, to: to, event: event, condition: condition)
    }
    
    public func setGlobalNoTransitionHandler(handler: @escaping HandlerBlock) {
        machine.setGlobalNoTransitionHandler(handler: handler)
    }
    
    public func setFinishHandler(handler: @escaping FinishBlock) {
        machine.setFinishHandler(handler: handler)
    }
    
    public func setErrorHandler(handler: @escaping ErrorBlock) {
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
    
    
    // MARK:
    
    private func syncBlock(block: () -> Void) {
        defer {
            lock.unlock()
        }
        
        lock.lock()
        block()
    }

    // MARK:
    
    let machine: FSMBasic<State, Event>
    let queue: OperationQueue
    let lock: NSLock
}
 
 

