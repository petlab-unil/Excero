//
//  TabBarViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 01.09.22.
//

import UIKit
import SpriteKit
import FirebaseMessaging
import HealthKit
import BackgroundTasks

struct CustomUITabBarItem {
    var item: UITabBarItem
    var controller: UIViewController
    var data: Dictionary<String, NSObject>?
}

class TabBarViewController: UITabBarController {
    private var fcmToken: String?
    private var lastSelectedView: String? = ""
    
    private var lastSyncDate: Date?
    private var bufferedSteps: [StepRecordRepresentation] = []
    
    private let tabBarContentMap: Dictionary<ExperimentalConditionAcronyms, [CustomUITabBarItem]> = [
        .SEP: [
            CustomUITabBarItem(item: UITabBarItem(title: "Duo", image: UIImage(systemName: "person.2.fill"), selectedImage: UIImage(systemName: "person.2.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home"), data: [GameViewController.START_START_PARAM_KEY: "DuoScene" as NSObject]),
            CustomUITabBarItem(item: UITabBarItem(title: "Progression", image: UIImage(systemName: "person.fill"), selectedImage: UIImage(systemName: "person.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home"), data: [GameViewController.START_START_PARAM_KEY: "MainScene" as NSObject]),
            CustomUITabBarItem(item: UITabBarItem(title: "Chat", image: UIImage(systemName: "message.fill"), selectedImage: UIImage(systemName: "message.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat")),
            CustomUITabBarItem(item: UITabBarItem(title: "Historique", image: UIImage(systemName: "clock.arrow.circlepath"), selectedImage: UIImage(systemName: "clock.arrow.circlepath")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "History")),
            CustomUITabBarItem(item: UITabBarItem(title: "A propos", image: UIImage(systemName: "info.circle.fill"), selectedImage: UIImage(systemName: "info.circle.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "About"))
        ],
        .HUM: [
            CustomUITabBarItem(item: UITabBarItem(title: "Duo", image: UIImage(systemName: "person.2.fill"), selectedImage: UIImage(systemName: "person.2.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home"), data: [GameViewController.START_START_PARAM_KEY: "DuoScene" as NSObject]),
            CustomUITabBarItem(item: UITabBarItem(title: "Progression", image: UIImage(systemName: "person.fill"), selectedImage: UIImage(systemName: "person.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home"), data: [GameViewController.START_START_PARAM_KEY: "MainScene" as NSObject]),
            CustomUITabBarItem(item: UITabBarItem(title: "Chat", image: UIImage(systemName: "message.fill"), selectedImage: UIImage(systemName: "message.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat")),
            CustomUITabBarItem(item: UITabBarItem(title: "Historique", image: UIImage(systemName: "clock.arrow.circlepath"), selectedImage: UIImage(systemName: "clock.arrow.circlepath")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "History")),
            CustomUITabBarItem(item: UITabBarItem(title: "A propos", image: UIImage(systemName: "info.circle.fill"), selectedImage: UIImage(systemName: "info.circle.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "About"))
        ],
        .CON: [
            CustomUITabBarItem(item: UITabBarItem(title: "Progression", image: UIImage(systemName: "person.fill"), selectedImage: UIImage(systemName: "person.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home")),
            CustomUITabBarItem(item: UITabBarItem(title: "Historique", image: UIImage(systemName: "clock.arrow.circlepath"), selectedImage: UIImage(systemName: "clock.arrow.circlepath")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "History")),
            CustomUITabBarItem(item: UITabBarItem(title: "A propos", image: UIImage(systemName: "info.circle.fill"), selectedImage: UIImage(systemName: "info.circle.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "About"))
        ],
        .BASE: [
            CustomUITabBarItem(item: UITabBarItem(title: "Expérience", image: UIImage(systemName: "house.fill"), selectedImage: UIImage(systemName: "house.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Baseline")),
            CustomUITabBarItem(item: UITabBarItem(title: "A propos", image: UIImage(systemName: "info.circle.fill"), selectedImage: UIImage(systemName: "info.circle.fill")), controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "About"))
        ]
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self
        self.delegate = self
        self.tabBar.isHidden = true
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName())
        UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        var viewControllers: [UIViewController] = []
        var items: [CustomUITabBarItem] = tabBarContentMap[.BASE]!
        let currentDate = Date()
        if let user = ResourcesManager.instance.user {
            if let expCond = user.lastExperimentalCondition,
                let exp = ExperimentalConditionAcronyms(rawValue: expCond.acronym) {
                if let expStart = expCond.start, let expEnd = expCond.end,
                   currentDate >= expStart && currentDate <= expEnd {
                    if (tabBarContentMap.keys.contains(exp)) {
                        items = tabBarContentMap[exp]!
                    }

                    Task {
                        var stepSynchTimer: PeerStepSynchronizer?
                        let conversationController = ConversationController(user: user)
                        if exp == .HUM {
                            if let humanPeer = await conversationController.getUserPeer(), let humanPeerURL = humanPeer.url,
                               let url = URL(string: humanPeerURL) {
                                stepSynchTimer = PeerStepSynchronizer(timeInterval: Constants.PEER_STEPS_REFRESH_TIMEINTERVAL, peerURL: url)
                            }
                        } else if exp == .SEP {
                            if let sepPeer = user.simulatedPeer, let sepPeerUrl = sepPeer.url,
                               let url = URL(string: sepPeerUrl) {
                                stepSynchTimer = PeerStepSynchronizer(timeInterval: Constants.PEER_STEPS_REFRESH_TIMEINTERVAL, peerURL: url)
                            }
                        }
                        stepSynchTimer?.start()
                    }
                }
            }
            var i = 0
            for item in items {
                item.controller.tabBarItem = item.item
                if let tabBarItemTitle = item.item.title, tabBarItemTitle == "Chat" {
                    if let defaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME),
                        let chatCounter = defaults.object(forKey: "chat_badge_count") {
                        if let chatCounter = chatCounter as? Int {
                            if chatCounter > 0 {
                                item.item.badgeValue = String(chatCounter)
                            }
                        }
                    } else {
                        print("No defaults matching the suitename.")
                    }
                }
                item.controller.tabBarItem.tag = i
                if let additionalData = item.data {
                    let controller = item.controller as! any InitialDataExpanded as InitialDataExpanded
                    controller.setData(initialData: additionalData)
                }
                viewControllers.append(item.controller)
                i += 1
            }
            self.viewControllers = viewControllers
            self.viewControllers?.forEach { let _ = $0.view }
            self.tabBar.isHidden = false
        }
        
        EventDispatcher.instance.subscribe() { event in
            if event.identifier == "goToChat_segue" {
                guard let chatVC = self.viewControllers![1] as? ExceroMessageViewController else {return}
                chatVC.setPredefinedMessage(message: "Regarde-ça ! Je suis déjà à \(event.content as! Int) pas aujourd'hui !")
                //self.performSegue(withIdentifier: "messageToSend", sender: self)
                self.selectedIndex = 1
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let crashAlert = UIAlertController(title: "Crash", message: "Il semblerait qu'une erreur a causé un crash lors de la dernière exécution de l'application. Seriez-vous d'accord de partager le rapport avec l'équipe d'Excero?", preferredStyle: .alert)
        
        if let reporter = ResourcesManager.instance.crashReporter {
            let user = ResourcesManager.instance.user
            let crashController = CrashController(reporter, user: user)
            crashAlert.addAction(UIAlertAction(title: "Envoyer", style: .default, handler: { action in
                Task {
                    await crashController.retrieveAndSendPendingCrashes()
                }
                crashAlert.dismiss(animated: true)
            }))
            crashAlert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: { action in
                crashController.clearPendingCrashes()
                crashAlert.dismiss(animated: true)
            }))
            if reporter.hasPendingCrashReport() {
                self.present(crashAlert, animated: true, completion: nil)
            } else {
                ResourcesManager.logger.info("TabBarViewController.ViewDidAppear No crash report detected.")
            }
        }
        Task {
            if let user = try await ResourcesManager.instance.getCurrentUser().value {
                let goalController = GoalController(user: user)
                do {
                    if try await goalController.getCurrentGoal() == nil {
                        let interventionWeekController = InterventionWeekController()
                        let current = await interventionWeekController.getCurrentInterventionWeek()
                        if let current {
                            var bundle: Dictionary<String, Any> = [GoalSettingViewController.DATA_BUNDLE_GOAL_INTERVENTIONWEEK: current]
                            let toDate = Date()
                            
                            if let fromDate = Calendar.current.date(byAdding: .day, value: -7, to: toDate) {
                                let weekRecords = try await ResourcesManager.instance.getHKSteps(from: fromDate, to: toDate).asSingle().value
                                var cumulativeSum: Int = 0
                                for record in weekRecords {
                                    cumulativeSum += Int(record.value)
                                }
                                bundle[GoalSettingViewController.DATA_BUNDLE_GOAL_LASTWEEK_STEPS] = cumulativeSum
                            }
                            if Constants.SHOW_GOAL_SETTING_VIEW {
                                self.displayViewControllerAsSheet(viewControllerName: "GoalSetting", data: bundle) { _ in
                                    
                                }
                            } else {
                                let _ = try await goalController.createGoal(iw: current, value: Constants.DEFAULT_STEP_GOAL)
                            }
                        }
                    }
                } catch ApiError.unauthorizedError(_) {
                    ResourcesManager.logger.error("TabBarViewController.viewDidAppear user authentication token has expired.")
                    let event = EventDispatcher.DispatchableEvent(identifier: AppOrchestrator.ORCHESTRATOR_EVENT_LOAD_STORYBOARD)
                    event.content = AppOrchestrator.StoryBoardBundle(storyboardName: "Authentication", viewName: "Authentication", rootWindow: self.view.window!) as AnyObject
                    EventDispatcher.instance.emit(event)
                } catch {
                    ResourcesManager.logger.error("TabBarViewController.viewDidAppear could not retrieve user goals. Detailed error: \(error)")
                }
            }
        }
        for item in self.tabBar.items! {
            if let tabBarItemTitle = item.title, tabBarItemTitle == "Chat" {
                if let defaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME),
                   let chatCounter = defaults.object(forKey: "chat_badge_count") {
                    if let chatCounter = chatCounter as? Int {
                        if chatCounter > 0 {
                            item.badgeValue = String(chatCounter)
                        }
                    }
                } else {
                    print("No defaults matching the suitename.")
                }
            }
        }
        Task {
            if let user = try await ResourcesManager.instance.getCurrentUser().value {
                let stepRecordController = StepRecordController(user: user)
                let lastSynchedDate = await stepRecordController.lastSynchronizedStepRecordDate()
                await self.synchStepsFromDate(lastSynchedDate)
            }
            await self.registerStepsObserver()
        }
    }
    
    func registerStepsObserver() async {
        let api = AuthenticatedApiFacade()
        do {
            try await HealthKitUtility.instance.enableBackgroundObservations()
            HealthKitUtility.instance.registerTotalStepObserver() { steps, start, end in
                let step = StepRecordRepresentation(url: nil, value: Int32(steps), start: start, end: end)
                ResourcesManager.instance.stepOfDayStream.accept(step)
            }
        } catch {
            ResourcesManager.logger.error("TabBarViewController.registerStepsObserver could not register background observer for HK steps. Detailed error: \(error)")
        }
        

        HealthKitUtility.instance.registerIncrementStepObserver() { steps, start, end in
            let step = StepRecordRepresentation(url: nil, value: Int32(steps), start: start, end: end)
            self.lastSyncDate = UserDefaults.standard.object(forKey: Constants.DEFAULTS_LAST_STEP_SYNCHDATE) as? Date 
            let deltaSync = Date().timeIntervalSinceReferenceDate - (self.lastSyncDate ?? Date()).timeIntervalSinceReferenceDate
            if deltaSync < Constants.DELTA_TIME_STEPS_SYNCH {
                self.bufferedSteps.append(step)
            } else {
                if self.bufferedSteps.count > 0 {
                    let startAcc = self.bufferedSteps[0].start ?? Date()
                    let endAcc = self.bufferedSteps.last?.end ?? Date()
                    var stepAcc = Int32(0)
                    for step in self.bufferedSteps {
                        stepAcc += step.value
                    }
                    let accStepRecord = StepRecordRepresentation(url: nil, value: stepAcc, start: startAcc, end: endAcc)
                    if let userURL = ResourcesManager.instance.user?.url {
                        Task {
                            do {
                                let _ = try await api.post(fullUrl: userURL + "steps/", data: accStepRecord.toCodable(), header: nil)
                                let _ = UserDefaults.standard.set(accStepRecord.end ?? Date(), forKey: Constants.DEFAULTS_LAST_STEP_SYNCHDATE)
                                self.bufferedSteps = []
                            } catch {
                                ResourcesManager.logger.error("TabBarViewController.registerStepsObserver could not synchronize steps with backend. Detailed error: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func synchStepsFromDate(_ date: Date) async {
        var steps: [StepRecordRepresentation] = []
        do {
            let currentDate = Date()
            let startDate = date
            let hkSteps = try await HealthKitUtility.instance.getStepsWithInterval(from: startDate, to: currentDate, intervalComponent: DateComponents(hour: 1))
            hkSteps?.forEach() { statisticEntry in
                if let quantity = statisticEntry.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                    let stepRepresentation = StepRecordRepresentation(url: nil, value: Int32(quantity), start: statisticEntry.startDate, end: statisticEntry.endDate)
                    steps.append(stepRepresentation)
                    
                }
            }
            
        } catch {
            ResourcesManager.logger.error("TabBarViewController.synchStepsFromDate could not synchronize steps from Healthkit. Detailed error: \(error)")
        }
        
        let controller = StepRecordController(user: ResourcesManager.instance.user)
        await controller.saveStepRecords(steps)
    }
}
extension TabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.lastSelectedView = viewController.title
        if viewController.title == "Chat" {
            if let defaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME),
                let _ = defaults.object(forKey: "chat_badge_count") {
                defaults.setValue(0, forKey: "chat_badge_count")
                viewController.tabBarItem.badgeValue = nil
                let center = UNUserNotificationCenter.current()
                var badgeValue = 0
                if let notificationCounter = defaults.object(forKey: "normal_badge_count"),
                   let notificationCounter = notificationCounter as? Int {
                    badgeValue = notificationCounter
                }
                Task {
                    if #available(iOS 16.0, *) {
                        do {
                            try await center.setBadgeCount(badgeValue)
                        } catch {
                            ResourcesManager.logger.error("TabBarViewController.userNotificationCenter could not set badge count. Detailed error: \(error)")
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
        }
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName() + "_" + (viewController.title ?? ""))
    }
}
extension TabBarViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        if let defaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME) {
            let chatBadge = defaults.object(forKey: "chat_badge_count")
            print(chatBadge ?? "No chat badge")
            guard let lastView = self.lastSelectedView else { return [[]] }
            if let items = self.tabBar.items {
                for item in items {
                    if item.title == "Chat" && lastView != "Chat" {
                        if let chatCounter = defaults.value(forKey: "chat_badge_count") {
                            item.badgeValue = String(chatCounter as? Int ?? 0)
                        }
                        return [[.banner, .sound]]
                    }
                }
            }
        }
        return [[]]
    }
}

extension TabBarViewController: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
          name: Notification.Name("FCMToken"),
          object: nil,
          userInfo: dataDict
        )
    }
}

