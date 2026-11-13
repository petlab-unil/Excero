//
//  NotificationService.swift
//  ExceroNotificationServiceExtension
//
//  Created by Alessandro on 11.04.24.
//

import UserNotifications
import FirebaseMessaging

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    let SUITE_NAME: String = "group.ch.heg.silacci.excero.Notifications"

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        Messaging.messaging().appDidReceiveMessage(request.content.userInfo)
        let center = UNUserNotificationCenter.current()
        if let bestAttemptContent = bestAttemptContent { // I leave this in case notifications should be modified by the app later.
            contentHandler(bestAttemptContent)
        }
        let userInfo = request.content.userInfo
        var totalBadgeCount: Int = 0
        var badge = 0
        let chatBadges = UserDefaults(suiteName: SUITE_NAME)?.object(forKey: "chat_badge_count") as? Int ?? 0
        let normalBadges = UserDefaults(suiteName: SUITE_NAME)?.object(forKey: "normal_badge_count") as? Int ?? 0
        if userInfo["has_badge"] != nil {
            badge = 1
        }
        print("Received badge \(badge)")
        
       
        if let notificationType = userInfo["notification_type"], notificationType as! String == "chat" {
            UserDefaults(suiteName: SUITE_NAME)?.setValue(chatBadges + badge, forKey: "chat_badge_count")
            totalBadgeCount += chatBadges
        } else {
            UserDefaults(suiteName: SUITE_NAME)?.setValue(normalBadges + badge, forKey: "normal_badge_count")
            totalBadgeCount += normalBadges
        }
        totalBadgeCount = normalBadges + chatBadges + badge
        print("setting total number of badges \(totalBadgeCount)")
        Task { [totalBadgeCount] in
            if #available(iOS 16.0, *) {
                do {
                    try await center.setBadgeCount(totalBadgeCount)
                } catch {
                    print("Error while setting badge \(error)")
                }
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
