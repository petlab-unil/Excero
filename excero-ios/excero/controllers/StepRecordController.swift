//
//  StepRecordController.swift
//  excero
//
//  Created by Alessandro on 16.08.24.
//

import Foundation

class StepRecordController: NSObject {
    
    private var user: UserRepresentation?
    private let api: AuthenticatedApiFacade
    
    private var lastStepRecorded: StepRecordRepresentation?
    
    internal init(user: UserRepresentation?) {
        self.user = user
        self.api = AuthenticatedApiFacade()
    }
    
    public func lastSynchronizedStepRecordDate() async -> Date {
        guard let user = self.user, let userURL = user.url else { return Date() }
        if let lastSynchDate = UserDefaults.standard.object(forKey: Constants.DEFAULTS_LAST_STEP_SYNCHDATE) {
            return lastSynchDate as? Date ?? Date()
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let stepsData = try await self.api.get(fullUrl: userURL + "steps/", header: nil) {
                let steps = try decoder.decode([StepRecordCodable].self, from: stepsData)
                if let lastStepRecord = steps.last {
                    return lastStepRecord.end
                }
            }
        } catch {
            ResourcesManager.logger.error("StepRecordController.lastSynchronizedStepRecordDate An error occured while fetching last synchronized step record date. Detailed error: \(error)")
        }
        return Date()
    }
    
    public func saveStepRecords(_ steps: [StepRecordRepresentation]) async {
        guard let user = self.user, let userURL = user.url else { return }
        var data: [StepRecordCodable] = []
        for step in steps {
            if let s = step.toCodable() {
                data.append(s)
            }
        }
        do {
            let task = try await self.api.post(fullUrl: userURL + "steps/", data: data, header: nil, delegate: self)
            task?.resume()
        } catch {
            print("An error occured while saving all step records for user: \(error)")
        }
    }
}

extension StepRecordController: URLSessionTaskDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("SYNCH COMPLETED")
        if let lastStepRecorded = self.lastStepRecorded {
            UserDefaults.standard.setValue(lastStepRecorded.end, forKey: Constants.DEFAULTS_LAST_STEP_SYNCHDATE)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        print("Done synch: \(totalBytesSent/totalBytesExpectedToSend)")
    }
}
