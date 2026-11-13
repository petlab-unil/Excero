//
//  StepRecordRepresentation.swift
//  excero
//
//  Created by Alessandro on 03.10.23.
//

import Foundation

class StepRecordRepresentation {
    private var _url: String?
    private var _value: Int32?
    private var _start: Date?
    private var _end: Date?
    
    
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
    
    public var value: Int32 {
        get {
            if let value = self._value {
                return value
            } else {
                return -1
            }
        }
    }
    
    internal init(url: String?, value: Int32, start: Date, end: Date) {
        self._url = url
        self._value = value
        self._start = start
        self._end = end
    }
    
}

extension StepRecordRepresentation {
    func toCDStepRecord() -> StepArchive? {
        guard let value = self._value else { return nil }
        guard let start = self._start else { return nil }
        guard let end = self._end else { return nil }
        
        let step = StepArchive(context: CoreDataController.instance.mainContext)
        step.value = value
        step.start = start
        step.end = end
        
        return step
    }
    
    static func fromCDStepRecord(step: StepArchive) -> StepRecordRepresentation? {
        return step.managedObjectContext?.performAndWait {
            guard let start = step.start else { return nil }
            guard let end = step.end else { return nil }
            return StepRecordRepresentation(url: "", value: step.value, start: start, end: end)
        }
    }
}

extension StepRecordRepresentation {
    func toCodable() -> StepRecordCodable? {
        guard let value = self._value else { return nil }
        guard let start = self._start else { return nil }
        guard let end = self._end else { return nil }
        
        return StepRecordCodable(url: self._url ?? "", value: value, start: start, end: end)
    }
    
    static func fromURL(url: String) async throws -> StepRecordRepresentation? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            let representation = StepRecordRepresentation.fromCodable(step: try decoder.decode(StepRecordCodable.self, from: data))
            return representation
        }
        return nil
    }
    
    static func fromCodable(step: StepRecordCodable) -> StepRecordRepresentation? {
        return StepRecordRepresentation(url: step.url, value: step.value, start: step.start, end: step.end)
    }
}
