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
    }
    
    
    // MARK: public
    public func setStates(states: [State]) {
        for state in states {
            let handlers: StateHandlers = (enter: [], leave: [])
            let transitionsMap: TransitionsMap = [:]
            let definition: StateDefinition = (transitionsMap: transitionsMap, handlers: handlers)
            
            machine[state] = definition
        }
    }
    
    public func setTerminalStates(initial: State, finish: State?) {
        initialState = initial
        finishState = finish
    }
    
    public func addStateEnterHandler(state: State, handler: HandlerBlock) {
        guard var definition = machine[state] else {
            return
        }
        
        definition.handlers.enter.append(handler)
        machine[state] = definition
    }
    
    public func addStateLeaveHandler(state: State, handler: HandlerBlock) {
        guard var definition = machine[state] else {
            return
        }
        
        definition.handlers.leave.append(handler)
        machine[state] = definition
    }
    
    public func addTransition(from: State, to: State, event: Event, condition: ConditionBlock?) {
        guard var definition = machine[from] else {
            return
        }
        
        guard machine[to] != nil else {
            return
        }
        
        let transition: Transition = (condition: condition, stateTo: to)
        var transitions: Transitions? = definition.transitionsMap[event]
        
        if  transitions != nil {
            transitions!.append(transition)
        } else {
            transitions = [transition]
        }
        
        definition.transitionsMap[event] = transitions
        
        machine[from] = definition
    }
    
    public func setNoTransitionHandler(handler: HandlerBlock) {
        noTransitionHandler = handler
    }
    
    public func setFinishHandler(handler: FinishBlock) {
        finishHandler = handler
    }
    
    public func startMachine() {
        started = true
        updateState(newState: initialState!, withEvent: nil)
    }
    
    public func processEvent(event: Event) {
        guard started else {
            return
        }
        
        print("Event -> \(event)")
        
        let definition = machine[currentState!]
        
        guard let transitions = definition?.transitionsMap[event] else {
            callNoTransitionHandler(state: currentState!, event: event)
            return
        }
        
        var processed = false
        
        for transition in transitions {
            if transition.condition == nil || transition.condition!(currentState!, transition.stateTo, event) {
                updateState(newState: transition.stateTo, withEvent: event)
                processed = true
                break
            }
        }
        
        if processed == false {
            callNoTransitionHandler(state: currentState!, event: event)
        }
        
        if currentState == finishState {
            callFinishHandler(state: currentState!, isTerminating: false)
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
    
    private func updateState(newState state: State, withEvent event: Event?) {
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
        
        if let currentState = currentState {
            if let handlers = machine[currentState]?.handlers.enter {
                for handler in handlers {
                    handler(currentState, event)
                }
            }
        }
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
    typealias StateHandlers = (enter: [HandlerBlock], leave: [HandlerBlock])
    typealias StateDefinition = (transitionsMap: TransitionsMap, handlers: StateHandlers)
    typealias Machine = [State: StateDefinition]
    
    var machine: Machine = [:]
    var currentState: State?
    
    var started = false
    
    var initialState: State?
    var finishState: State?
    
    var noTransitionHandler: HandlerBlock?
    var finishHandler: FinishBlock?
}
