//
//  AuthorizationViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 26.09.22.
//

import UIKit
import HealthKit

class AuthorizationViewController: UIViewController {
    @IBOutlet weak var authorizeHKButton: UIButton!
    @IBOutlet weak var authorizeNotificationsButton: UIButton!
    
    private var isHKAuthorized: Bool = false
    private var isNotificationAuthorized: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.authorizeHKButton.addTarget(self, action: #selector(AuthorizationViewController.authorizeHKTapped(_:)), for: .touchUpInside)
        self.authorizeNotificationsButton.addTarget(self, action: #selector(AuthorizationViewController.authorizeNotificationsTapped(_:)), for: .touchUpInside)
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName())
    }
    
    @objc func authorizeHKTapped(_ sender: UIButton) {
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "AUTHORIZE_HEALTHKIT")
        HealthKitUtility.instance.requestStepPermissions() { authorized in
            ResourcesManager.logger.info("AuthorizationViewController.authorizedHKTapped user authorized for Healthkit usage .")
            ResourcesManager.instance.registerUserEvent(action: .OTHER_EVENT, target: "AUTHORIZATION_GRANTED_HEALTHKIT")
            DispatchQueue.main.async {
                self.authorizeHKButton.backgroundColor = UIColor.green
                self.isHKAuthorized = authorized
                if (self.isHKAuthorized && self.isNotificationAuthorized) {
                    self.retrieveBaselineSteps()
                }
            }
        }
    }
    
    @objc func authorizeNotificationsTapped(_ sender: UIButton) {
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "AUTHORIZE_NOTIFICATIONS")
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { authorized, error in
            if let error {
                ResourcesManager.logger.warning("AuthorizationViewController.authorizeNotificationsTapped user denied notification usage.")
            } else {
                ResourcesManager.logger.info("AuthorizationViewController.authorizeNotificationsTapped user authorized for notification usage.")
            }
            ResourcesManager.instance.registerUserEvent(action: .OTHER_EVENT, target: "AUTHORIZATION_GRANTED_NOTIFICATIONS")
            DispatchQueue.main.async {
                self.authorizeNotificationsButton.backgroundColor = UIColor.green
                self.isNotificationAuthorized = authorized
                if (self.isHKAuthorized && self.isNotificationAuthorized) {
                    ResourcesManager.logger.info("AuthorizationViewController.authorizeNotificationsTapped user authorized all necessary features.")
                    self.retrieveBaselineSteps()
                }
            }
            
        }
    }
    
    private func retrieveBaselineSteps() {
        if !ResourcesManager.instance.isFirstLaunch {
            return
        }
        #if targetEnvironment(simulator)
        ResourcesManager.instance.isFirstLaunch = false
        self.showActivityIndicator(subtext: nil, display: false)
        self.switchToMainStoryboard()
        #else
        self.showActivityIndicator(text: "Synchronisation...", subtext: "Nous synchronisons tes données de pas avec nos serveurs, ne pas quitter l'application", display: true)
        Task {
            var baselineStepsRepresentations: [StepRecordRepresentation] = []
            let api = AuthenticatedApiFacade()
            do {
                let currentDate = Date()
                let startDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: currentDate)
                let startBaselineDate = Calendar.current.date(byAdding: .month, value: -3, to: startDate!)
                let stepsBaseline = try await HealthKitUtility.instance.getStepsWithInterval(from: startBaselineDate!, to: currentDate, intervalComponent: DateComponents(hour: 1))
                stepsBaseline?.forEach() { statisticEntry in
                    if let quantity = statisticEntry.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                        let stepRepresentation = StepRecordRepresentation(url: nil, value: Int32(quantity), start: statisticEntry.startDate, end: statisticEntry.endDate)
                        baselineStepsRepresentations.append(stepRepresentation)
                    }
                }
            } catch {
                ResourcesManager.logger.error("AuthorizationViewController.retrieveBaselineSteps could not retrieve user steps. Detailed error: \(error)")
                // -- MARK: Should find something to do when data is not sufficient.
            }
            
            if let user = ResourcesManager.instance.user {
                let controller = StepRecordController(user: user)
                await controller.saveStepRecords(baselineStepsRepresentations)
                self.showActivityIndicator(subtext: nil, display: false)
                ResourcesManager.instance.isFirstLaunch = false
                self.switchToMainStoryboard()
            }
        }
        #endif
    }
    
    func switchToMainStoryboard() {
        var mainSB: UIStoryboard
        var startingVC: UIViewController
        mainSB = UIStoryboard(name: "Main", bundle: nil)
        startingVC = mainSB.instantiateViewController(withIdentifier: "Main") as UIViewController
        guard let rootWindow = self.view.window else {return}
        rootWindow.rootViewController?.dismiss(animated: false)
        rootWindow.rootViewController = startingVC
    }

}
