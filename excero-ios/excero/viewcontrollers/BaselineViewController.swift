//
//  BaselineViewController.swift
//  excero
//
//  Created by Alessandro on 06.05.24.
//

import UIKit

class BaselineViewController: UIViewController {

    @IBOutlet weak var synchronizationIndicatorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName())
        if ResourcesManager.instance.networkAvailable {
            Task {
                self.showActivityIndicator(subtext: nil, display: true)
                do {
                    if let user = try await ResourcesManager.instance.getCurrentUser().value, let userURL = user.url,
                       let lastOpened = UserDefaults.standard.object(forKey: AppDelegate.APP_LASTOPEN_TAG) {
                        let api = AuthenticatedApiFacade()
                        
                        self.synchronizationIndicatorLabel.text = "En cours"
                        #if targetEnvironment(simulator)
                        #else
                        do {
                            for try await steps in ResourcesManager.instance.getHKSteps(from: lastOpened as! Date).values {
                                for step in steps {
                                    do {
                                        let _ = try await api.post(fullUrl: userURL + "steps/", data: step.toCodable(), header: nil)
                                    } catch {
                                        ResourcesManager.logger.error("BaselineViewController.viewDidLoad could not synch steps with backend. Detailed error: \(error)")
                                    }
                                }
                            }
                        } catch {
                            ResourcesManager.logger.error("BaselineViewController.viewDidLoad could not retrieve steps from Healthkit. Detailed error: \(error)")
                        }
                        #endif
                        self.showActivityIndicator(subtext: nil, display: false)
                        self.synchronizationIndicatorLabel.text = "Synchronisé"
                    } else {
                        self.showActivityIndicator(subtext: nil, display: false)
                        self.synchronizationIndicatorLabel.text = "Synchronization impossible"
                    }
                } catch {
                    ResourcesManager.logger.error("BaselineViewController.viewDidLoad could not load current user. Detailed error: \(error)")
                    // -- MARK: Should go back to authentication view.
                }
            }
        } else {
            self.showActivityIndicator(subtext: nil, display: false)
            self.synchronizationIndicatorLabel.text = "Synchronization impossible"
            ResourcesManager.logger.warning("BaselineViewController.viewDidLoad could not synchronize steps, network is unavailable.")
        }
    }

}
