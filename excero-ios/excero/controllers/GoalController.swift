//
//  GoalController.swift
//  excero
//
//  Created by Alessandro on 02.05.24.
//

import Foundation
import AsyncPlus

class GoalController {
    
    private let coreController: ModelController<Goal>
    private let resourceManager: ResourcesManager
    private let api: AuthenticatedApiFacade
    private let user: UserRepresentation
    
    init(user: UserRepresentation) {
        self.coreController = ModelController<Goal>()
        self.resourceManager = ResourcesManager.instance
        self.api = AuthenticatedApiFacade()
        self.user = user
    }
    
    func getCurrentGoal() async throws -> GoalRepresentation? {
        let currentDate = Date()
        if self.resourceManager.networkAvailable {
            if let userURL = self.user.url {
                let userGoalsData = try await self.api.get(fullUrl: userURL + "goals/", header: nil)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let data = userGoalsData {
                    let decodedGoals = try decoder.decode([GoalCodable].self, from: data)
                    if let lastGoal = decodedGoals.last,
                       currentDate >= lastGoal.start && currentDate <= lastGoal.end {
                        let goalRepresentation = GoalRepresentation.fromCodable(goal: lastGoal)
                        let _ = goalRepresentation?.toCD()
                        return goalRepresentation
                    }
                }
            }
        }
        if let lastGoal = self.coreController.getLast(),
          let start = lastGoal.start, let end = lastGoal.end, currentDate >= start && currentDate <= end {
               return GoalRepresentation.fromCD(element: lastGoal)
        }
        return nil
    }
    
    func getGoalForWeek(_ iw: InterventionWeekRepresentation) async throws -> GoalRepresentation? {
        guard let userURL = self.user.url else {return nil}
        if let iwBegin = iw.begin, let iwEnd = iw.end {
            if self.resourceManager.networkAvailable {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let userGoalsData = try await self.api.get(fullUrl: userURL + "goals/", header: nil)
                if let data = userGoalsData {
                    let decodedGoals = try decoder.decode([GoalCodable].self, from: data)
                    for goal in decodedGoals {
                        if goal.start == iwBegin && goal.end == iwEnd {
                            return GoalRepresentation.fromCodable(goal: goal)
                        }
                    }
                }
            } else {
                let goals = self.coreController.list()
                for goal in goals {
                    if let gStart = goal.start, let gEnd = goal.end,
                       gStart == iwBegin && gEnd == iwEnd {
                        return GoalRepresentation.fromCD(element: goal)
                    }
                }
            }
            return nil
        }
        return nil
    }
    
    func createGoal(iw: InterventionWeekRepresentation, value: Int) async throws -> GoalRepresentation? {
        guard let userURL = self.user.url else {return nil}
        if let iwBegin = iw.begin, let iwEnd = iw.end {
            let goal = GoalRepresentation(url: "", start: iwBegin, end: iwEnd, value: value, interventionWeek: iw, attained: false)
            if self.resourceManager.networkAvailable {
                let goalData = try await self.api.post(fullUrl: userURL + "goals/", data: goal.toCodable(), header: nil)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let data = goalData {
                    let goal = try decoder.decode(GoalCodable.self, from: data)
                    if let goalRepresentation = GoalRepresentation.fromCodable(goal: goal) {
                        let _ = goalRepresentation.toCD()
                        return goalRepresentation
                    }
                }
            } else {
                // TODO: Stage for sync
            }
        }
        return nil
    }
}
