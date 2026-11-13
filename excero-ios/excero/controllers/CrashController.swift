//
//  CrashController.swift
//  excero
//
//  Created by Alessandro Silacci on 04.11.2024.
//

import Foundation
import CrashReporter

class CrashController {
    
    private let crashReporter: PLCrashReporter
    private let user: UserRepresentation?
    
    init(_ crashReporter: PLCrashReporter, user: UserRepresentation?) {
        self.crashReporter = crashReporter
        self.user = user
    }
    
    func retrievePendingCrashes() -> Data? {
        if !self.crashReporter.hasPendingCrashReport() {
            ResourcesManager.logger.warning("CrashController.retrievePendingCrashes No crash report found.")
            return nil
        }
        do {
            let data = try crashReporter.loadPendingCrashReportDataAndReturnError()
            try self.crashReporter.purgePendingCrashReportAndReturnError()
            let report = try PLCrashReport(data: data)
            if let dataTxt = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS) {
                return dataTxt.data(using: .utf8)
            }
            return nil
        } catch {
            ResourcesManager.logger.error("CrashController.retrievePendingCrashes could not retrieve data for crash report generation. Detailed error \(error)")
        }
        return nil
    }
    
    func clearPendingCrashes() {
        do {
            try self.crashReporter.purgePendingCrashReportAndReturnError()
        } catch {
            ResourcesManager.logger.error("CrashController.clearPendingCrashes could not clear pending crash reports. Detailed error \(error)")
        }
    }
    
    func sendCrashData(_ data: Data) async {
        guard let user = self.user, let userURL = user.url else {
            ResourcesManager.logger.warning("CrashController.sendCrashData No user specified.")
            return
        }
        let api: AuthenticatedApiFacade = AuthenticatedApiFacade()
        do {
            let additionalData = ["issuer": userURL]
            let _ = try await api.postFormData(endpointPath: "admin/reports/crash/", file: data, additionalData: additionalData, header: nil)
        } catch {
            ResourcesManager.logger.error("CrashController.sendCrashData could not send crash report. Detailed error \(error)")
        }
    }
    
    func retrieveAndSendPendingCrashes() async {
        guard let crashData = self.retrievePendingCrashes() else {
            return
        }
        await self.sendCrashData(crashData)
    }
}
