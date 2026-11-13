//
//  InterventionWeekRepresentation.swift
//  excero
//
//  Created by Alessandro on 24.11.23.
//

import Foundation
class InterventionWeekRepresentation: Hashable, Representation {
    
    private var _url: String?
    private var _begin: Date?
    private var _end: Date?
    
    var url: String? {
        get {
            return self._url
        }
    }
    
    var begin: Date? {
        get {
            return self._begin
        }
    }
    
    var end: Date? {
        get {
            return self._end
        }
    }
    
    internal init(url: String, begin: Date, end: Date) {
        self._url = url
        self._begin = begin
        self._end = end
    }
    
    static func == (lhs: InterventionWeekRepresentation, rhs: InterventionWeekRepresentation) -> Bool {
        return ObjectIdentifier(self) == ObjectIdentifier(self) && lhs._url == rhs._url && lhs._begin == rhs._begin && lhs._end == rhs._end
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
        hasher.combine(self._url)
        hasher.combine(self._begin)
        hasher.combine(self._end)
    }
}

extension InterventionWeekRepresentation: CoreDataRepresentable {
    typealias CoreDataElement = InterventionWeek
    typealias RepresentationElement = InterventionWeekRepresentation
    
    func toCD() -> InterventionWeek? {
        guard let url = self._url else { return nil }
        guard let begin = self._begin else { return nil }
        guard let end = self._end else { return nil }
        var iw: InterventionWeek? = self.checkCoreData {element in element.url == self._url}
        if iw == nil {
            iw = InterventionWeek(context: CoreDataController.instance.mainContext)
        }
        iw?.url = url
        iw?.begin = begin
        iw?.end = end
        return iw
    }
    
    static func fromCD(element: InterventionWeek) -> InterventionWeekRepresentation? {
        guard let url = element.url else { return nil }
        guard let begin = element.begin else { return nil }
        guard let end = element.end else { return nil }
        
        return InterventionWeekRepresentation(url: url, begin: begin, end: end)
    }
    
}

extension InterventionWeekRepresentation {
    func toCodable() -> InterventionWeekCodable? {
        guard let url = self._url else { return nil }
        guard let begin = self._begin else { return nil }
        guard let end = self._end else { return nil }
        
        return InterventionWeekCodable(url: url, begin: begin, end: end)
    }
    
    static func fromCodable(interventionWeek: InterventionWeekCodable) -> InterventionWeekRepresentation? {
        return InterventionWeekRepresentation(url: interventionWeek.url, begin: interventionWeek.begin, end: interventionWeek.end)
    }
}
