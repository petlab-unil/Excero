//
//  AnalyticsController.swift
//  excero
//
//  Created by Alessandro on 04.07.24.
//

import Foundation

enum ActionNames: String {
    case BTN_CLICK = "ch.unil.silacci.excero.BTN_CLICK"
    case FIELD_TYPE = "ch.unil.silacci.excero.FIELD_TYPE"
    case VIEW_CHANGE = "ch.unil.silacci.excero.VIEW_CHANGE"
    case USER_ERROR = "ch.unil.silacci.excero.USER_ERROR"
    case OTHER_EVENT = "ch.unil.silacci.excero.OTHER_EVENT"
}

class AnalyticsController {
    
    private let api: AuthenticatedApiFacade = AuthenticatedApiFacade()
    
    private let _user: UserRepresentation?
    
    
    init(user: UserRepresentation) {
        self._user = user
    }
    
    public func storeAnalyticEvent(action: ActionNames, target: String) async -> Void {
        guard let user = self._user, let userURL = user.url else { return }
        var version: String = "unknown"
        if let nsObjectDict = Bundle.main.infoDictionary, let nsObject = nsObjectDict["CFBundleShortVersionString"] {
            version = nsObject as! String
        }
        do {
            let data = AnalyticRecordCodable(actionName: action.rawValue, target: target, appVersion: version)
            let _ = try await self.api.post(fullUrl: userURL + "analytics/", data: data, header: nil)
        } catch {
            print("Error while saving analytic record: \(error)")
        }
    }
    
}
