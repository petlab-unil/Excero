//
//  PeerStepSynchronizer.swift
//  excero
//
//  Created by Alessandro Silacci on 23.09.2024.
//

import Foundation

class PeerStepSynchronizer {
    var timer: Timer?
    let timeInterval: TimeInterval
    let repeats: Bool
    let peerURL: URL
    let api: AuthenticatedApiFacade
    
    init(timeInterval: TimeInterval, peerURL: URL, repeats: Bool = true) {
        self.timeInterval = timeInterval
        self.repeats = repeats
        self.peerURL = peerURL
        self.api = AuthenticatedApiFacade()
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: self.repeats)
        self.timer?.fire()
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @objc func tick() {
        ResourcesManager.logger.info("PeerStepSynchronizer started updating peer steps from URL(\(peerURL.absoluteString + "steps/"))")
        Task {
            do {
                let data = try await api.get(fullUrl: peerURL.absoluteString + "steps/", header: nil)
                if let data {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let steps = try decoder.decode([StepRecordCodable].self, from: data).reversed()
                    var currentDayStepsAcc: Int32 = 0
                    let today = Date()
                    for step in steps {
                        if Calendar.current.isDate(step.start, inSameDayAs: today) {
                            currentDayStepsAcc += step.value
                        } else {
                            break
                        }
                    }
                    ResourcesManager.instance.peerStepsOfDayStream.accept(StepRecordRepresentation(url: nil, value: currentDayStepsAcc, start: today, end: today))
                    ResourcesManager.logger.info("PeerStepSynchronizer updated steps for peer with count(\(currentDayStepsAcc))")
                }
            } catch {
                ResourcesManager.logger.error("PeerStepSynchronizer failed to update peer steps. Detailed error: \(error)")
            }
        }
    }
}
