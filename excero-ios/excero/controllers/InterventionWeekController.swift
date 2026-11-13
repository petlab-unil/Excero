//
//  InterventionWeekController.swift
//
//
//  Created by Alessandro on 03.05.24.
//

import Foundation
import AsyncPlus

class InterventionWeekController {
    
    private let coreController: ModelController<InterventionWeek>
    private let resourceManager: ResourcesManager
    private let api: AuthenticatedApiFacade
    
    init() {
        self.coreController = ModelController<InterventionWeek>()
        self.resourceManager = ResourcesManager.instance
        self.api = AuthenticatedApiFacade()
    }
    
    func getCurrentInterventionWeek() async -> InterventionWeekRepresentation? {
        let currentDate = Date()
        return await self.getInterventionWeekForDate(date: currentDate)
    }
    
    
    func listInterventionWeeks() async -> [InterventionWeekRepresentation]? {
        if self.resourceManager.networkAvailable {
            return await attempt {
                return try await self.api.get(endpointPath: "interventions/", header: nil)
            }.then { (data: Data?) -> [InterventionWeekRepresentation]? in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let data {
                    do {
                        let iws = try decoder.decode([InterventionWeekCodable].self, from: data)
                        var representations: [InterventionWeekRepresentation] = []
                        if iws.count == 0 {
                            return nil
                        }
                        for iw in iws {
                            if let rep = InterventionWeekRepresentation.fromCodable(interventionWeek: iw) {
                                representations.append(rep)
                            }
                        }
                        return representations
                    } catch {
                        fatalError("Error while decoding intervention weeks: \(error)")
                    }
                }
                return nil
            }.asyncOptional() ?? nil
        } else {
            let iws = self.coreController.list()
            var representations: [InterventionWeekRepresentation] = []
            if iws.count == 0 {
                return nil
            }
            for iw in iws {
                if let rep = InterventionWeekRepresentation.fromCD(element: iw) {
                    representations.append(rep)
                }
            }
            return representations
        }
    }
    
    func listInterventionWeeksUntilDate(_ date: Date) async -> [InterventionWeekRepresentation]? {
        return await attempt {
            if let weeks = await self.listInterventionWeeks() {
                var validWeeks: [InterventionWeekRepresentation] = []
                for week in weeks {
                    if let weekBegin = week.begin, weekBegin <= date {
                        validWeeks.append(week)
                    }
                }
                return validWeeks
            }
            return []
        }.asyncOptional()
    }
    
    func getInterventionWeekForDate(date: Date) async -> InterventionWeekRepresentation? {
        if let iws = await self.listInterventionWeeks() {
            for iw in iws {
                if let iwBegin = iw.begin, let iwEnd = iw.end, 
                    date >= iwBegin && date <= iwEnd {
                    return iw
                }
            }
        }
        return nil
    }
    
}
