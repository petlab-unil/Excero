//
//  GoalRepresentation.swift
//  excero
//
//  Created by Alessandro on 21.11.23.
//

import Foundation

class GoalRepresentation: Representation {
    private var _url: String?
    private var _start: Date?
    private var _end: Date?
    private var _value: Int?
    private var _attained: Bool = false
    private var _week: InterventionWeekRepresentation?
    
    public var attained: Bool {
        set {
            self._attained = newValue
        }
        get {
            return self._attained
        }
    }
    
    public var week: InterventionWeekRepresentation? {
        set {
            self._week = newValue
        }
        get {
            return self._week
        }
    }
    
    public var start: Date? {
        get {
            return self._start
        }
    }
    
    public var end: Date? {
        get {
            return self._end
        }
    }
    
    public var value: Int? {
        get {
            return self._value
        }
    }
    
    internal init(url: String, start: Date, end: Date, value: Int, interventionWeek: InterventionWeekRepresentation? = nil, attained: Bool = false) {
        self._url = url
        self._start = start
        self._end = end
        self._value = value
        self._week = interventionWeek
        self._attained = attained
    }
}

extension GoalRepresentation: CoreDataRepresentable {
    typealias CoreDataElement = Goal
    typealias RepresentationElement = GoalRepresentation
    
    static func fromCD(element: Goal) -> GoalRepresentation? {
        guard let url = element.url else { return nil }
        guard let start = element.start else { return nil }
        guard let end = element.end else { return nil }
        guard let week = element.week else { return nil }
        
        return GoalRepresentation(url: url, start: start, end: end, value: Int(element.value), interventionWeek: InterventionWeekRepresentation.fromCD(element: week), attained: element.attained)
    }
    
    func toCD() -> Goal? {
        guard let url = self._url else { return nil }
        guard let start = self._start else { return nil }
        guard let end = self._end else { return nil }
        guard let week = self._week else { return nil }
        guard let value = self._value else { return nil }
        var goal: Goal? = self.checkCoreData {element in element.url == self._url}
        if goal == nil {
            goal = Goal(context: CoreDataController.instance.mainContext)
        }
        goal?.url = url
        goal?.start = start
        goal?.end = end
        goal?.week = week.toCD()
        goal?.value = Int32(value)
        goal?.attained = self._attained
        
        return goal
    }
}

extension GoalRepresentation {
    func toCodable() -> GoalCodable? {
        guard let url = self._url else { return nil }
        guard let start = self._start else { return nil }
        guard let end = self._end else { return nil }
        guard let value = self._value else { return nil }
        
        return GoalCodable(url: url, start: start, end: end, value: Int(value), attained: self._attained)
    }
    
    static func fromCodable(goal: GoalCodable, interventionWeek: InterventionWeekRepresentation? = nil) -> GoalRepresentation? {
        return GoalRepresentation(url: goal.url, start: goal.start, end: goal.end, value: goal.value, interventionWeek: interventionWeek)
    }
}
