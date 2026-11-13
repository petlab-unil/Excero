//
//  UserNonEligibleViewController.swift
//  excero
//
//  Created by Alessandro on 26.08.24.
//

import UIKit

class UserNonEligibleViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            do {
                if let user = try await ResourcesManager.instance.getCurrentUser().value {
                    let userController = UserController(user: user)
                    do {
                        try await userController.deactivate()
                    } catch {
                        ResourcesManager.logger.error("UserNonEligibleViewController.viewDidLoad could not deactivate user account. Detailed error: \(error)")
                    }
                }
            } catch {
                ResourcesManager.logger.error("UserNonEligibleViewController.viewDidLoad could not retrieve current user account. Detailed error: \(error)")
            }
        }
    }

}
