//
//  FSMachineProtocol.swift
//  Swift-FSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import Foundation

public protocol FSMachineProtocol {
    associatedtype State
    associatedtype Event
    
    typealias ConditionBlock = (State, State, Event) -> Bool
    typealias HandlerBlock = (State, Event?) -> Void
    typealias FinishBlock = (State, Bool) -> Void
    
    func setStates(states: [State]) throws
    func setTerminalStates(initial: State, finish: State?) throws
    
    func addStateEnterHandler(state: State, handler: HandlerBlock) throws
    func addStateLeaveHandler(state: State, handler: HandlerBlock) throws
    func addStateNoTransitionHandler(state: State, handler: HandlerBlock) throws
    
    func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) throws
    
    func setGlobalNoTransitionHandler(handler: HandlerBlock)
    func setFinishHandler(handler: FinishBlock)
    func setErrorHandler(handler: ((Error) -> Void))
    
    func startMachine()
    func processEvent(event: Event)
    
    func terminateMachine()
    
    func isStarted() -> Bool
    func getCurrentState() -> State?
}

public protocol FSMachineAsyncProtocol {
    var isPaused: Bool { get set }
    func cancelAllEvents()
}


enum FSMachineError : Error {
    case UnknowState(state: AnyObject)
    case Unexpected(msg: String)
    case NoInitialState
    case NotStarted
    case AlreadyStarted
}
