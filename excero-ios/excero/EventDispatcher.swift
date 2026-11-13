//
//  EventDispatcher.swift
//  excero
//
//  Created by Alessandro Silacci on 01.09.22.
//

import Foundation

class EventDispatcher {
    class DispatchableEvent {
        var identifier: String
        var content: AnyObject?
        
        internal init(identifier: String) {
            self.identifier = identifier
        }
    }
    
    public static let instance: EventDispatcher = EventDispatcher()
    private var subscribers: [(DispatchableEvent) -> Void] = []
    
    private init() {
    }
    
    func subscribe(call: @escaping (DispatchableEvent) -> Void) {
        self.subscribers.append(call)
    }
    
    func emit(_ event: DispatchableEvent) {
        for subscriber in self.subscribers {
            subscriber(event)
        }
    }
    
}
