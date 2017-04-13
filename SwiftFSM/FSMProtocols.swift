//
//  FSMProtocols.swift
//  Swift-FSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import Foundation

public protocol FSMLogger {
    func debugLog(_ s: String)
}

public protocol FSMProtocol {
    associatedtype State
    associatedtype Event
    
    typealias ConditionBlock = (State, State, Event) -> Bool
    typealias HandlerBlock = (State, Event?) -> Void
    typealias FinishBlock = (State, Bool) -> Void
    typealias ErrorBlock = (Error) -> Void
    
    var logger: FSMLogger { get set }
    
    var isStarted: Bool { get }
    var currentState: State? { get }
    
    func setStates(states: [State]) throws
    func setTerminalStates(initial: State, finish: State?) throws
    
    func addEnterHandler(forState state: State, handler: @escaping HandlerBlock) throws
    func addLeaveHandler(forState state: State, handler: @escaping HandlerBlock) throws
    func addNoTransitionHandler(forState state: State, handler: @escaping HandlerBlock) throws
    
    func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) throws
    
    func setGlobalNoTransitionHandler(handler: @escaping HandlerBlock)
    func setFinishHandler(handler: @escaping FinishBlock)
    func setErrorHandler(handler: @escaping ErrorBlock)
    
    func startMachine()
    func processEvent(event: Event)
    
    func terminateMachine()
}

public protocol FSMAsyncProtocol: FSMProtocol {
    var isPaused: Bool { get set }
    func cancelAllEvents()
}


public enum FSMError : Error {
    case unknowState(state: AnyObject)
    case unknowEvent(event: AnyObject)
    case unexpected(msg: String)
    case noInitialState
    case notStarted
    case alreadyStarted
}
