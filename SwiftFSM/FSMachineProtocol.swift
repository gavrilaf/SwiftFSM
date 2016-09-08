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
    
    func setStates(states: [State])
    func setTerminalStates(initial: State, finish: State?)
    
    func addStateEnterHandler(state: State, handler: HandlerBlock)
    func addStateLeaveHandler(state: State, handler: HandlerBlock)
    
    func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?)
    
    func setNoTransitionHandler(handler: HandlerBlock)
    func setFinishHandler(handler: FinishBlock)
    
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
