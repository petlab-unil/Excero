//
//  LaunchScreenViewController.swift
//  excero
//
//  Created by Alessandro on 14.05.24.
//

import UIKit
import Lottie

class LaunchScreenViewController: UIViewController {
    
    private var loadingAnimation: LottieAnimationView?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupAnimation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadingAnimation = .init(name: "splash-animation-institutions")
        self.setupAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var loadStoryboard = "Authentication"
        var loadViewname = "Authentication"
        let loadingStatusSemaphore = DispatchSemaphore(value: 0)
        Task {
            if let _ = ModelController<UserInformation>().getLast() {
                if (await !HealthKitUtility.instance.hasStepPermissions()) {
                    loadStoryboard = "FirstInit"
                    loadViewname = "FirstInit"
                } else {
                    loadStoryboard = "Main"
                    loadViewname = "Main"
                }
            }
            do {
                let loadingResult = try await self.setupUser()
                if let loadingResult = loadingResult, let storyboard = loadingResult.keys.first, let viewname = loadingResult[storyboard] {
                    loadStoryboard = storyboard
                    loadViewname = viewname
                }
                loadingStatusSemaphore.signal()
            } catch {
                ResourcesManager.logger.error("LaunchScreenViewController.viewDidAppear encountered exceptions during the app initial setup. Detailed error: \(error)")
                loadingStatusSemaphore.signal()
            }
        }
        
        self.loadingAnimation?.play(fromFrame: AnimationFrameTime(exactly: 100), toFrame: AnimationFrameTime(exactly: 270)!) { [weak self] completed in
            loadingStatusSemaphore.wait(timeout: .now() + 10)
            Task {
                self?.initProcess(storyboardName: loadStoryboard, viewName: loadViewname)
            }
        }
    }
    
    private func initProcess(storyboardName: String, viewName: String) {
        let chatBadges = UserDefaults.standard.object(forKey: "chat_badge_count") as? Int ?? 0
        let normalBadges = UserDefaults.standard.object(forKey: "normal_badge_count") as? Int ?? 0
        ResourcesManager.logger.info("LaunchScreenViewController.initProcess observed number of notifications: Chat(\(chatBadges)), Regular(\(normalBadges)).")
        let _ = AppOrchestrator.instance
        EventDispatcher.instance.subscribe() { event in
            if event.identifier == SceneDelegate.SCENEDELEGATE_CHANGEVIEW_EVENT {
                let content = event.content as! SceneDelegate.SceneDelegateChangeViewEvent
                self.loadViewWithName(storyboardName: content.storyBoardName, viewName: content.viewName)
            }
        }
        self.loadViewWithName(storyboardName: storyboardName, viewName: viewName)
        
    }
    
    private func setupUser() async throws -> [String: String]? {
        if let userDefaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME), let isDeactivated = userDefaults.value(forKey: Constants.USER_DEFAULTS_ACCOUNT_DEACTIVATED) as? Bool {
            if isDeactivated == true {
                return ["FirstInit": "Deactivated"]
            }
        }
        if let _ = ModelController<UserInformation>().getLast() {
            if ResourcesManager.instance.networkAvailable {
                let apiAuth = AuthenticatedApiFacade()
                do {
                    let userInfo = try await ResourcesManager.instance.getUserInfo().value
                    ResourcesManager.instance.token = Token(token: userInfo?.token, refreshToken: userInfo?.refreshToken)
                    let selfData = try await apiAuth.get(endpointPath: "users/self/", header: nil)
                    if let selfData {
                        let decoder = JSONDecoder()
                        let userSelf = try decoder.decode([UserCodable].self, from: selfData)
                        do {
                            let user = try await UserRepresentation.fromCodable(user: userSelf[0])
                            ResourcesManager.instance.user = user
                        } catch {
                            print(error)
                        }
                        if (await !HealthKitUtility.instance.hasStepPermissions()) {
                            return ["FirstInit": "FirstInit"]
                        } else {
                            return ["Main": "Main"]
                        }
                    }
                } catch {
                    ResourcesManager.logger.error("LaunchScreenViewController.setupUser could not get initial user data. Detailed error: \(error)")
                    return ["Main": "Main"]
                }
            } else {
                if let _ = try await ResourcesManager.instance.getCurrentUser().value {
                    return ["Main": "Main"]
                }
            }
        }
        return ["Authentication": "Authentication"]
    }
    
    private func setupAnimation() {
        guard let loadingAnimation = self.loadingAnimation else { return }
        self.view.addSubview(loadingAnimation)
        loadingAnimation.isUserInteractionEnabled = false
        loadingAnimation.animationSpeed = 1.2
        loadingAnimation.frame = self.view.bounds
        loadingAnimation.contentMode = .scaleAspectFill
    }
    
    private func loadViewWithName(storyboardName: String, viewName: String) {
        let event = EventDispatcher.DispatchableEvent(identifier: AppOrchestrator.ORCHESTRATOR_EVENT_LOAD_STORYBOARD)
        let window = self.view.window
        if let window {
            event.content = AppOrchestrator.StoryBoardBundle(storyboardName: storyboardName, viewName: viewName, rootWindow: window) as AnyObject
            EventDispatcher.instance.emit(event)
        }
    }
    
    struct SceneDelegateChangeViewEvent {
        var storyBoardName: String
        var viewName: String
    }

}
