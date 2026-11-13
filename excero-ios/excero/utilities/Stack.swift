//
//  Stack.swift
//  excero
//
//  Created by Alessandro on 16.02.24.
//

import Foundation

public struct Stack<T> {
    private var _elements: [T] = []
    
    public var isEmpty: Bool {
        get {
            return self._elements.count == 0
        }
    }
    
    public init() {}
    
    public mutating func push(_ e: T) -> Void {
        self._elements.append(e)
    }
    
    @discardableResult
    public mutating func pop() -> T? {
        return self._elements.popLast()
    }
    
    public func peek() -> T? {
        return self._elements.last
    }
}
