//
//  AppDelegate.swift
//  excero
//
//  Created by Alessandro Silacci on 20.07.22.
//

import UIKit
import FirebaseCore
import Network
import FirebaseMessaging
import BackgroundTasks
import HealthKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let APP_LASTOPEN_TAG = "Excero.LastOpened"
    
    private let configuration = FirebaseService.instance.configure()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let pathMonitor = NWPathMonitor()
        pathMonitor.pathUpdateHandler = { path in
            switch(path.status){
            case .satisfied:
                print("Connected")
                ResourcesManager.instance.networkAvailable = true
            case .unsatisfied:
                print("No Connection")
                ResourcesManager.instance.networkAvailable = false
            default:
                print("Not a normal status")
            }
        }
        let _ = ResourcesManager.instance
        pathMonitor.start(queue: DispatchQueue.global(qos: .background))
        if let reporter = ResourcesManager.instance.crashReporter {
            do {
                try reporter.enableAndReturnError()
            } catch {
                ResourcesManager.logger.error("AppDelegate.application Error when loading the crash reporter module.")
            }
        }
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
        Messaging.messaging().token { token, error in
          if let error = error {
              ResourcesManager.logger.error("AppDelegate.application Error while fetching user FCM registration token: \(token)")
          } else if let token = token {
              ResourcesManager.logger.info("AppDelegate.application Registering new FCM token for user, with token: \(token)")
              if let user = ResourcesManager.instance.user, let userURL = user.url {
                  Task {
                      let api = AuthenticatedApiFacade()
                      do {
                          user.fcmToken = token
                          if let userCodable = user.toCodable() {
                              let _ = try await api.put(fullUrl: userURL, data: userCodable, header: nil)
                          }
                      } catch {
                          ResourcesManager.logger.error("AppDelegate.application Could not update FCM token. Detailed error: \(error)")
                      }
                  }
              }
          }
        }
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func handleBackgroundTask(_ task: BGTask) {
        //self.scheduleBackgroundTask()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        Task { [weak self] in
            guard let self else {
                task.setTaskCompleted(success: false)
                return
            }
            do {
                guard let lastSyncDate = UserDefaults.standard.object(forKey: Constants.DEFAULTS_LAST_STEP_SYNCHDATE) else {
                    task.setTaskCompleted(success: false)
                    return
                }
                var stepRecords: [StepRecordRepresentation] = []
                let api = AuthenticatedApiFacade()
                do {
                    let currentDate = Date()
                    //let startDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: currentDate)
                    let startDate = lastSyncDate as! Date// Calendar.current.date(byAdding: .month, value: -3, to: startDate!)
                    let steps = try await HealthKitUtility.instance.getStepsWithInterval(from: startDate, to: currentDate, intervalComponent: DateComponents(hour: 1))
                    steps?.forEach() { statisticEntry in
                        if let quantity = statisticEntry.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                            let stepRepresentation = StepRecordRepresentation(url: nil, value: Int32(quantity), start: statisticEntry.startDate, end: statisticEntry.endDate)
                            stepRecords.append(stepRepresentation)
                            
                        }
                    }
                    
                } catch {
                    task.setTaskCompleted(success: false)
                    return
                }
                
                if let user = ResourcesManager.instance.user {
                    let controller = StepRecordController(user: user)
                    await controller.saveStepRecords(stepRecords)
                    task.setTaskCompleted(success: true)
                } else {
                    task.setTaskCompleted(success: false)
                }
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}

