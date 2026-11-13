//
//  PeerStepsRefreshOperation.swift
//  excero
//
//  Created by Alessandro Silacci on 20.09.2024.
//

import Foundation

class PeerStepsRefreshOperation: Operation {
    let peerURL: URL?
    let api: AuthenticatedApiFacade
    
    override var isAsynchronous: Bool {
        get {
            return true
        }
    }
    
    init(peerURL: String) {
        self.peerURL = URL(string: peerURL)
        self.api = AuthenticatedApiFacade()
    }
    
    override func main() {
        guard !isCancelled else {
            ResourcesManager.logger.error("PeerStepsRefreshOperation update has been cancelled before completion.")
            return
        }
        guard let peerURL else {
            ResourcesManager.logger.error("PeerStepsRefreshOperation URL for peer steps retrieval is nil.")
            return
        }
        ResourcesManager.logger.info("PeerStepsRefreshOperation started updating peer steps from URL(\(peerURL.absoluteString))")
        Task {
            do {
                let data = try await api.get(fullUrl: peerURL.absoluteString + "steps/", header: nil)
                if let data {
                    let steps = try JSONDecoder().decode([StepRecordCodable].self, from: data).reversed()
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
                    ResourcesManager.logger.info("PeerStepsRefreshOperation updated steps for peer with count(\(currentDayStepsAcc))")
                }
            } catch {
                ResourcesManager.logger.error("PeerStepsRefreshOperation failed to update peer steps. Detailed error: \(error)")
            }
        }
    }
}
