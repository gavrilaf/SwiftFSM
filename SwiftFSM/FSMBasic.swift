//
//  FSMBasic.swift
//  Swift-FSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import Foundation

public class FSMBasic<State, Event> : FSMProtocol where State: Hashable, Event: Hashable {
    
    public typealias ConditionBlock = (State, State, Event) -> Bool
    public typealias HandlerBlock = (State, Event?) -> Void
    public typealias FinishBlock = (State, Bool) -> Void
    public typealias ErrorBlock = (Error) -> Void
        
    public init() {
        noTransitionHandler = {
            self.logger.debugLog("No transition from state \($0) with event \(String(describing: $1))")
        }
        
        finishHandler = {
            self.logger.debugLog("Machine finished with state \($0), terminating \($1)")
        }
        
        errorHandler = {
            self.logger.debugLog("Unexpected error: \($0)")
        }
    }
    
    
    // MARK: State
    
    public var logger: FSMLogger {
        get {
            return _logger
        }
        
        set {
            _logger = newValue
        }
    }
    
    public var currentState: State? {
        return _currentState
    }
    
    public var isStarted: Bool {
        return started
    }
    
    // MARK: Setup
    public func setStates(states: [State]) throws {
        guard !started else {
            throw FSMError.alreadyStarted
        }
        
        // clear previous states
        machine = [:]
        
        for state in states {
            let handlers: StateHandlers = (enter: [], leave: [], noTransition: [])
            let transitionsMap: TransitionsMap = [:]
            let definition: StateDefinition = (transitionsMap: transitionsMap, handlers: handlers)
            
            machine[state] = definition
        }
    }
    
    public func setTerminalStates(initial: State, finish: State?) throws {
        guard !started else {
            throw FSMError.alreadyStarted
        }
        
        guard machine[initial] != nil else {
            throw FSMError.unknowState(state: initial as AnyObject)
        }
        
        if let finish = finish {
            guard machine[finish] != nil else {
                throw FSMError.unknowState(state: finish as AnyObject)
            }
        }
        
        initialState = initial
        finishState = finish
    }
    
    public func addEnterHandler(forState state: State, handler: @escaping HandlerBlock) throws {
        guard var definition = machine[state] else {
            throw FSMError.unknowState(state: state as AnyObject)
        }
        
        definition.handlers.enter.append(handler)
        machine[state] = definition
    }
    
    public func addLeaveHandler(forState state: State, handler: @escaping HandlerBlock) throws {
        guard var definition = machine[state] else {
            throw FSMError.unknowState(state: state as AnyObject)
        }
        
        definition.handlers.leave.append(handler)
        machine[state] = definition
    }
    
    public func addNoTransitionHandler(forState state: State, handler: @escaping HandlerBlock) throws {
        guard var definition = machine[state] else {
            throw FSMError.unknowState(state: state as AnyObject)
        }
        
        definition.handlers.noTransition.append(handler)
        machine[state] = definition
    }
    
    public func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) throws {
        guard machine[to] != nil else {
            throw FSMError.unknowState(state: to as AnyObject)
        }
        
        guard var definition = machine[from] else {
            throw FSMError.unknowState(state: from as AnyObject)
        }
        
        
        var transitions = definition.transitionsMap[event] ?? Transitions()
        let transition: Transition = (condition: condition, stateTo: to)
        
        transitions.append(transition)
        
        definition.transitionsMap[event] = transitions
        machine[from] = definition
    }
    
    public func setGlobalNoTransitionHandler(handler: @escaping HandlerBlock) {
        noTransitionHandler = handler
    }
    
    public func setFinishHandler(handler: @escaping FinishBlock) {
        finishHandler = handler
    }
    
    public func setErrorHandler(handler: @escaping ErrorBlock) {
        errorHandler = handler
    }
    
    
    // MARK: Manage machine
    
    public func startMachine() {
        guard !started else {
            errorHandler(FSMError.alreadyStarted)
            return
        }
        
        guard let initialState = initialState else {
            errorHandler(FSMError.noInitialState)
            return
        }
        
        started = true
        _ = updateState(newState: initialState, withEvent: nil)
    }
    
    public func processEvent(event: Event) {
        logger.debugLog("process: event(\(event)), started(\(started)), currentState(\(String(describing: currentState)))")
        
        guard started else {
            errorHandler(FSMError.notStarted)
            return
        }
        
        guard let state = currentState else {
            errorHandler(FSMError.unexpected(msg: "currentState == nil"))
            return
        }
        
        guard let definition = machine[state] else {
            errorHandler(FSMError.unexpected(msg: "Couldn't find definition for state \(state)"))
            return
        }
        
        guard let transitions = definition.transitionsMap[event] else {
            errorHandler(FSMError.unexpected(msg: "Nil transitions table for state \(state)"))
            return
        }
        
        var processed = false
        
        // looking for suitable transition
        for transition in transitions {
            if transition.condition == nil || transition.condition!(state, transition.stateTo, event) {
                _currentState = updateState(newState: transition.stateTo, withEvent: event)
                processed = true
                break
            }
        }
        
        // no transition, looking for noTransition handlers for currentState
        if !processed {
            for handler in definition.handlers.noTransition {
                handler(state, event)
                processed = true
            }
        }
        
        // call general 'no transition' handler
        if !processed {
            callNoTransitionHandler(state: state, event: event)
        }
        
        logger.debugLog("after process: \(String(describing: currentState))")
        
        if currentState == finishState {
            callFinishHandler(state: state, isTerminating: false)
            started = false
        }
    }
    
    public func terminateMachine() {
        if started {
            callFinishHandler(state: currentState!, isTerminating: true)
            started = false
        }
    }
    
   // MARK: Private
    
    private func updateState(newState: State, withEvent event: Event?) -> State {
        logger.debugLog("State changed from \(String(describing: currentState)) to \(newState)")
        
        // 1. Run leave handlers for currentState
        // 2. Change state (currentState = newState)
        // 3. Run enter handlers for new currentState
        
        if let state = currentState {
            if let handlers = machine[state]?.handlers.leave {
                for handler in handlers {
                    handler(state, event)
                }
            }
        }
        
        _currentState = newState
        
        if let state = self.currentState {
            if let handlers = machine[state]?.handlers.enter {
                for handler in handlers {
                    handler(state, event)
                }
            }
        }
        
        return newState
    }
    
    private func callNoTransitionHandler(state: State, event: Event?) {
        if let noTransitionHandler = noTransitionHandler {
            noTransitionHandler(state, event)
        }
    }
    
    private func callFinishHandler(state: State, isTerminating: Bool) {
        if let finishHandler = finishHandler {
            finishHandler(state, isTerminating)
        }
    }
    
    // MARK: Types
    
    typealias Transition = (condition: ConditionBlock?, stateTo: State)
    typealias Transitions = [Transition]
    typealias TransitionsMap = [Event : Transitions]
    typealias StateHandlers = (enter: [HandlerBlock], leave: [HandlerBlock], noTransition: [HandlerBlock])
    typealias StateDefinition = (transitionsMap: TransitionsMap, handlers: StateHandlers)
    typealias Machine = [State: StateDefinition]
    
    // MARK: Private
    
    internal var machine: Machine = [:]
    internal var _currentState: State?
    
    internal var started = false
    
    internal var initialState: State?
    internal var finishState: State?
    
    internal var noTransitionHandler: HandlerBlock!
    internal var finishHandler: FinishBlock!
    internal var errorHandler: ErrorBlock!
    
    internal var _logger: FSMLogger = FSMSimpleLogger()
}
