//
//  HealthKitUtility.swift
//  excero
//
//  Created by Alessandro Silacci on 30.08.22.
//

import Foundation
import HealthKit

class HealthKitUtility {
    private var healthkitStore: HKHealthStore?
    private var stepType:HKQuantityType? = HKObjectType.quantityType(forIdentifier: .stepCount)
    private var observerQuery: HKObserverQuery?
    
    static let instance: HealthKitUtility = HealthKitUtility()
    
    
    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthkitStore = HKHealthStore()
        }
    }
    
    func registerStepObserver(callback: @escaping (Double) -> Void) {
        guard let stepType = self.stepType else {
            callback(0.0)
            return
        }
        let now = Date()
        let dayStart = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: nil, options: .strictStartDate)
        let query = HKObserverQuery(sampleType: stepType, predicate: predicate) { _, completionHandler, error in
            if let _ = error {
                callback(0.0)
            }
            self.countCurrentDaySteps(callback: callback)
            completionHandler()
        }
        self.healthkitStore?.execute(query)
    }
    
    func registerTotalStepObserver(callback: @escaping (Double, Date, Date) -> Void) {
        let now = Date()
        let dayStart = Calendar.current.startOfDay(for: now)
        guard let stepType = self.stepType else {
            callback(0.0, dayStart, now)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: nil, options: .strictStartDate)
        let query = HKObserverQuery(sampleType: stepType, predicate: predicate) { _, completionHandler, error in
            if let _ = error {
                callback(0.0, dayStart, now)
            }
            self.countCurrentDaySteps(from: dayStart, callback: callback)
            completionHandler()
        }
        self.healthkitStore?.execute(query)
    }
    
    func registerIncrementStepObserver(callback: @escaping (Double, Date, Date) -> Void) {
        let now = Date()
        let dayStart = Calendar.current.startOfDay(for: now)
        guard let stepType = self.stepType else {
            callback(0.0, dayStart, now)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: nil, options: .strictStartDate)
        let query = HKObserverQuery(sampleType: stepType, predicate: predicate) { _, completionHandler, error in
            if let _ = error {
                callback(0.0, dayStart, now)
            }
            // self.countCurrentDaySteps(from: dayStart, callback: callback)
            Task {
                let startDate = UserDefaults.standard.object(forKey: Constants.DEFAULTS_LAST_STEP_SYNCHDATE) as? Date ?? dayStart
                let currentDate = Date()
                do {
                    if let steps = try await self.getStepsRecordInPeriod(from: startDate, to: currentDate) {
                        callback(steps.1 ?? 0.0, steps.0, currentDate)
                    }
                } catch {
                    print("Could not retrieve steps in specific period \(error)")
                }
            }
            completionHandler()
        }
        self.healthkitStore?.execute(query)
    }
    
    func stopObserver() {
        if let query = self.observerQuery {
            self.healthkitStore?.stop(query)
        }
    }
    
    func countCurrentDaySteps(callback: @escaping (Double) -> Void) {
        guard let stepType = self.stepType else {
            callback(0.0)
            return
        }
        let now = Date()
        let dayStart = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: nil, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, steps, _ in
            guard let steps = steps, let sum = steps.sumQuantity() else {
                callback(0.0)
                return
            }
            callback(sum.doubleValue(for: HKUnit.count()))
        }
        self.healthkitStore!.execute(query)
    }
    
    func countCurrentDaySteps(from: Date, callback: @escaping (Double, Date, Date) -> Void) {
        guard let stepType = self.stepType else {
            callback(0.0, from, Date())
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: from, end: nil, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { query, steps, _ in
            guard let steps = steps, let sum = steps.sumQuantity() else {
                callback(0.0, from, Date())
                return
            }
            callback(sum.doubleValue(for: HKUnit.count()), from, Date())
        }
        self.healthkitStore!.execute(query)
    }
    
    func executeStatisticsQuery(from: Date, to: Date, interval: DateComponents) async throws -> [HKStatistics]? {
        guard let stepType = self.stepType else {
            return nil
        }
        let query = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let predicate = HKSamplePredicate.quantitySample(type: stepType, predicate: query)
        let queryDescriptor = HKStatisticsCollectionQueryDescriptor(predicate: predicate, options: .cumulativeSum,
                                                                    anchorDate: to, intervalComponents: interval)
        let results = try await queryDescriptor.result(for: self.healthkitStore!)
        return results.statistics()
    }
    
    func getStepsRecordInPeriod(from: Date, to: Date) async throws -> (Date, Double?)?  {
        guard let stepType = self.stepType else {
            return nil
        }
        
        let dateDelta = to.timeIntervalSinceReferenceDate - from.timeIntervalSinceReferenceDate
        var interval = DateComponents(second: Int(dateDelta))
        let period = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)
        let predicate = HKSamplePredicate.quantitySample(type: stepType, predicate: period)
        let steps = HKStatisticsQueryDescriptor(predicate: predicate, options: .cumulativeSum)
        let stepsCount = try await steps.result(for: self.healthkitStore!)?.sumQuantity()?.doubleValue(for: HKUnit.count())
        return (from, stepsCount)
    }
    
    func getStepsWithInterval(from: Date, to: Date, intervalComponent: DateComponents) async throws -> [HKStatistics]? {
        let calendar = Calendar.current
        let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, hour: 0, minute: 0, second: 0)
                
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("Could not create quantity type for step counts.")
        }
        let query = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let predicate = HKSamplePredicate.quantitySample(type: quantityType, predicate: query)
        let queryDescriptor = HKStatisticsCollectionQueryDescriptor(predicate: predicate, options: .cumulativeSum,
                                                                    anchorDate: to, intervalComponents: intervalComponent)
        let results = try await queryDescriptor.result(for: self.healthkitStore!)
        return results.statistics()
    }
    
    func enableBackgroundObservations(completion: @escaping (Bool, Error?) -> Void) {
        guard let stepType = self.stepType else {
            return
        }
        self.healthkitStore?.enableBackgroundDelivery(for: stepType,
                                                      frequency: HKUpdateFrequency.immediate,
                                                      withCompletion: completion)
    }
    
    func enableBackgroundObservations() async throws {
        guard let stepType = self.stepType else {
            return
        }
        try await self.healthkitStore?.enableBackgroundDelivery(for: stepType,
                                                      frequency: HKUpdateFrequency.immediate)
    }
    
    func hasStepPermissions() async -> Bool {
        /*guard let healthkitStore = self.healthkitStore else {return false}
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)
        let status = healthkitStore.authorizationStatus(for: stepType!)
        return status == .sharingAuthorized*/
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) else { return false }
        do {
            let result = try await self.getStepsWithInterval(from: yesterday, to: .now, intervalComponent: DateComponents(hour: 5))
            return result != nil && result?.count ?? 0 > 0
        } catch {
            ResourcesManager.logger.error("HealthKitUtility.hasStepPermissions impossible to check HK permissions. Detailed error: \(error)")
        }
        return false
    }
    
    func requestStepPermissions(callback: @escaping (Bool) -> Void) {
        guard let healthkitStore = self.healthkitStore else {return}
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)
        healthkitStore.requestAuthorization(toShare: nil, read: [stepType!]) { authorized, err in
            if let _ = err {
                callback(false)
            } else {
                callback(authorized)
            }
        }
    }
}
