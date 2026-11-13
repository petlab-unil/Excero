//
//  SceneDelegate.swift
//  excero
//
//  Created by Alessandro on 08.11.23.
//

import Foundation
import UIKit


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    public static let SCENEDELEGATE_CHANGEVIEW_EVENT = "SceneDelegate.SCENEDELEGATE_CHANGEVIEW_EVENT"
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let urlContext = connectionOptions.urlContexts.first {
            let sourceApplication = urlContext.options.sourceApplication
            let url = urlContext.url
            ResourcesManager.logger.info("SceneDelegate.scene App has been opened using the custom URL Scheme, with the following url \(url.absoluteString) and source application is \(sourceApplication?.description ?? "undefined")")
            let event = EventDispatcher.DispatchableEvent(identifier: "test")
            event.content = url as AnyObject
            
            EventDispatcher.instance.emit(event)
            ResourcesManager.instance.openingURL.accept(url)
        }
        
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        //ResourcesManager.instance.clearNotifications(removeBadges: true, storedCountName: "normal_badge_count")
        guard let defaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME) else { return }
        var totalNotificationsBadgeCount: Int = 0
        if let chatCounter = defaults.object(forKey: "chat_badge_count") {
            totalNotificationsBadgeCount += chatCounter as? Int ?? 0
        }
        if let _ = defaults.object(forKey: "normal_badge_count") {
            defaults.setValue(0, forKey: "normal_badge_count")
        }
        Task {
            let center = UNUserNotificationCenter.current()
            if #available(iOS 16.0, *) {
                do {
                    try await center.setBadgeCount(totalNotificationsBadgeCount)
                } catch {
                    ResourcesManager.logger.error("SceneDelegate.sceneDidBecomeActive could not set badge count. Detailed error: \(error)")
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    public func sceneWillResignActive(_ scene: UIScene) {
        if let user = ResourcesManager.instance.user {
            UserDefaults.standard.set(Date(), forKey: AppDelegate.APP_LASTOPEN_TAG)
            let _ = user.toCDUser()
        }
        ResourcesManager.instance.saveResources()
        HealthKitUtility.instance.stopObserver()
    }
    
    private func loadViewWithName(storyboardName: String, viewName: String) {
        let event = EventDispatcher.DispatchableEvent(identifier: AppOrchestrator.ORCHESTRATOR_EVENT_LOAD_STORYBOARD)
        event.content = AppOrchestrator.StoryBoardBundle(storyboardName: storyboardName, viewName: viewName, rootWindow: self.window!) as AnyObject
        EventDispatcher.instance.emit(event)
    }
    
    struct SceneDelegateChangeViewEvent {
        var storyBoardName: String
        var viewName: String
    }
}
