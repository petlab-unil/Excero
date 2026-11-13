//
//  ExperimentalConditionRepresentation.swift
//  excero
//
//  Created by Alessandro on 03.10.23.
//

import Foundation

class ExperimentalConditionRepresentation {
    private var _url: String?
    private var _acronym: String?
    private var _name: String?
    private var _start: Date?
    private var _end: Date?
    
    private static let coreModelController: ModelController<ExperimentalCondition> = ModelController<ExperimentalCondition>()
    
    public var url: String? {
        set {
            self._url = newValue
        }
        get {
            return self._url
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
    
    public var acronym: String {
        get {
            if let acronym = self._acronym {
                return acronym
            } else {
                return "BASE"
            }
        }
    }
    
    internal init(url: String, acronym: String, name: String, start: Date, end: Date) {
        self._url = url
        self._acronym = acronym
        self._name = name
        self._start = start
        self._end = end
    }
}

extension ExperimentalConditionRepresentation {
    func toCDExperimentalCondition() -> ExperimentalCondition? {
        guard let url = self._url else { return nil }
        guard let acronym = self._acronym else { return nil }
        guard let name = self._name else { return nil }
        guard let start = self._start else { return nil }
        guard let end = self._end else { return nil }
        var model: ExperimentalCondition? = ExperimentalConditionRepresentation.coreModelController.get(formatString: "url = %@", valueString: url)
        if model == nil {
            model = ExperimentalCondition(context: CoreDataController.instance.mainContext)
        }
        model?.url = url
        model?.acronym = acronym
        model?.name = name
        model?.start = start
        model?.end = end
        
        return model
    }
    
    static func fromCDExperimentalCondition(expCond: ExperimentalCondition) -> ExperimentalConditionRepresentation? {
        guard let url = expCond.url else { return nil }
        guard let acronym = expCond.acronym else { return nil }
        guard let name = expCond.name else { return nil }
        guard let start = expCond.start else { return nil }
        guard let end = expCond.end else { return nil }
        
        return ExperimentalConditionRepresentation(url: url, acronym: acronym,
                                                   name: name, start: start, end: end)
    }
}

extension ExperimentalConditionRepresentation {
    func toCodable() -> ExperimentalConditionCodable? {
        guard let url = self._url else { return nil }
        guard let acronym = self._acronym else { return nil }
        guard let name = self._name else { return nil }
        guard let start = self._start else { return nil }
        guard let end = self._end else { return nil }
        
        return ExperimentalConditionCodable(url: url, acronym: acronym, name: name, start: start, end: end)
    }
    
    static func fromURL(url: String) async throws -> ExperimentalConditionRepresentation? {
        let decoder = JSONDecoder()
        let api = AuthenticatedApiFacade()
        let data = try await api.get(fullUrl: url, header: nil)
        if let data = data {
            decoder.dateDecodingStrategy = .iso8601
            let exp = try decoder.decode(ExperimentalConditionCodable.self, from: data)
            let representation = ExperimentalConditionRepresentation.fromCodable(exp: exp)
            return representation
        }
        return nil
    }
    
    static func fromCodable(exp: ExperimentalConditionCodable) -> ExperimentalConditionRepresentation? {
        return ExperimentalConditionRepresentation(url: exp.url, acronym: exp.acronym,
                                                   name: exp.name, start: exp.start, end: exp.end)
    }
}
