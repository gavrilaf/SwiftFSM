//
//  FSMachineBasic.swift
//  Swift-FSM
//
//  Created by Eugen Fedchenko on 9/7/16.
//  Copyright © 2016 Personal. All rights reserved.
//

import Foundation

public class FSMachineBasic<State, Event> : FSMachineProtocol where State: Hashable, Event: Hashable {
    
    public typealias ConditionBlock = (State, State, Event) -> Bool
    public typealias HandlerBlock = (State, Event?) -> Void
    public typealias FinishBlock = (State, Bool) -> Void
    
    public init() {
        noTransitionHandler = {
            print("No transition from state \($0) with event \($1)")
        }
        
        finishHandler = {
            print("Machine finished with state \($0), terminating \($1)")
        }
        
        errorHandler = {
            print("Unexpected error: \($0)")
        }
    }
    
    
    // MARK: public
    public func setStates(states: [State]) throws {
        
        guard !started else {
            throw FSMachineError.AlreadyStarted
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
            throw FSMachineError.AlreadyStarted
        }
        
        guard machine[initial] != nil else {
            throw FSMachineError.UnknowState(state: initial as AnyObject)
        }
        
        if let finish = finish {
            guard machine[finish] != nil else {
                throw FSMachineError.UnknowState(state: finish as AnyObject)
            }
        }
        
        initialState = initial
        finishState = finish
    }
    
    public func addStateEnterHandler(state: State, handler: HandlerBlock) throws {
        guard var definition = machine[state] else {
            throw FSMachineError.UnknowState(state: state as AnyObject)
        }
        
        definition.handlers.enter.append(handler)
        machine[state] = definition
    }
    
    public func addStateLeaveHandler(state: State, handler: HandlerBlock) throws {
        guard var definition = machine[state] else {
            throw FSMachineError.UnknowState(state: state as AnyObject)
        }
        
        definition.handlers.leave.append(handler)
        machine[state] = definition
    }
    
    public func addStateNoTransitionHandler(state: State, handler: HandlerBlock) throws {
        guard var definition = machine[state] else {
            throw FSMachineError.UnknowState(state: state as AnyObject)
        }
        
        definition.handlers.noTransition.append(handler)
        machine[state] = definition
    }
    
    
    public func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) throws {
        guard machine[to] != nil else {
            throw FSMachineError.UnknowState(state: to as AnyObject)
        }
        
        guard var definition = machine[from] else {
            throw FSMachineError.UnknowState(state: from as AnyObject)
        }
        
        let transition: Transition = (condition: condition, stateTo: to)
        var transitions: Transitions? = definition.transitionsMap[event]
        
        if transitions != nil {
            transitions!.append(transition)
        } else {
            transitions = [transition]
        }
        
        definition.transitionsMap[event] = transitions
        machine[from] = definition
    }
    
    public func setGlobalNoTransitionHandler(handler: HandlerBlock) {
        noTransitionHandler = handler
    }
    
    public func setFinishHandler(handler: FinishBlock) {
        finishHandler = handler
    }
    
    public func setErrorHandler(handler: ((Error) -> Void)) {
        errorHandler = handler
    }
    
    public func startMachine() {
        guard !started else {
            errorHandler(FSMachineError.AlreadyStarted)
            return
        }
        
        guard let initialState = initialState else {
            errorHandler(FSMachineError.NoInitialState)
            return
        }
        
        started = true
        _ = updateState(newState: initialState, withEvent: nil)
    }
    
    public func processEvent(event: Event) {
        
        print("Event -> \(event), started=\(started), currentState=\(currentState)")
        
        guard started else {
            errorHandler(FSMachineError.NotStarted)
            return
        }
        
        guard var currentState = currentState else {
            errorHandler(FSMachineError.Unexpected(msg: "Null currentState"))
            return
        }
        
        guard let definition = machine[currentState] else {
            errorHandler(FSMachineError.Unexpected(msg: "Nil definition for state \(currentState)"))
            return
        }
        
        guard let transitions = definition.transitionsMap[event] else {
            errorHandler(FSMachineError.Unexpected(msg: "Nil transitions table for state \(currentState)"))
            return
        }
        
        var processed = false
        
        // looking for suitable transition
        for transition in transitions {
            if transition.condition == nil || transition.condition!(currentState, transition.stateTo, event) {
                currentState = updateState(newState: transition.stateTo, withEvent: event)
                processed = true
                break
            }
        }
        
        // no transition, looking for noTransition handlers for currentState
        if processed == false {
            for handler in definition.handlers.noTransition {
                handler(currentState, event)
                processed = true
            }
        }
        
        // call general 'no transition' handler
        if processed == false {
            callNoTransitionHandler(state: currentState, event: event)
        }
        
        print("\(currentState), \(finishState), \(currentState == finishState)")
        if currentState == finishState {
            callFinishHandler(state: currentState, isTerminating: false)
            started = false
        }
    }
    
    public func terminateMachine() {
        if started {
            callFinishHandler(state: currentState!, isTerminating: true)
            started = false
        }
    }
    
    public func isStarted() -> Bool {
        return started
    }
    
    public func getCurrentState() -> State? {
        return currentState
    }
    
    // MARK:
    
    private func updateState(newState state: State, withEvent event: Event?) -> State {
        print("State changed from \(currentState) to \(state)")
        
        // 1. Run leave handlers for currentState
        // 2. Change state (currentState = newState)
        // 3. Run enter handlers for new currentState
        
        if let currentState = currentState {
            if let handlers = machine[currentState]?.handlers.leave {
                for handler in handlers {
                    handler(currentState, event)
                }
            }
        }
        
        currentState = state
        
        if let currentState = self.currentState {
            if let handlers = machine[currentState]?.handlers.enter {
                for handler in handlers {
                    handler(currentState, event)
                }
            }
        }
        
        return state
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
    
    // MARK:
    
    typealias Transition = (condition: ConditionBlock?, stateTo: State)
    typealias Transitions = [Transition]
    typealias TransitionsMap = [Event : Transitions]
    typealias StateHandlers = (enter: [HandlerBlock], leave: [HandlerBlock], noTransition: [HandlerBlock])
    typealias StateDefinition = (transitionsMap: TransitionsMap, handlers: StateHandlers)
    typealias Machine = [State: StateDefinition]
    
    var machine: Machine = [:]
    var currentState: State?
    
    var started = false
    
    var initialState: State?
    var finishState: State?
    
    var noTransitionHandler: HandlerBlock?
    var finishHandler: FinishBlock?
    var errorHandler: ((Error) -> Void)
}
