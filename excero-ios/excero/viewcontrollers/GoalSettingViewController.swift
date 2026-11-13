//
//  GoalSettingViewController.swift
//  excero
//
//  Created by Alessandro on 16.04.24.
//

import UIKit
import AsyncPlus

class GoalSettingViewController: DataBundledViewController {
    
    public static let DATA_BUNDLE_GOAL_LASTWEEK_STEPS = "ch.unil.silacci.excero.GoalSettingViewController.DATA_BUNDLE_GOAL_LASTWEEK_STEPS"
    public static let DATA_BUNDLE_GOAL_INTERVENTIONWEEK = "ch.unil.silacci.excero.GoalSettingViewController.DATA_BUNDLE_GOAL_INTERVENTIONWEEK"
    
    @IBOutlet weak var keepOldGoalButton: UIButton!
    @IBOutlet weak var goalConfirmButton: UIButton!
    @IBOutlet weak var newStepGoalLabel: UILabel!
    
    private let defaultGoal: Int = Constants.DEFAULT_STEP_GOAL // TODO: Set constant for this.
    private var currentInterventionWeek: InterventionWeekRepresentation?
    private var previousNumberOfSteps: Int = 0
    
    private let increment: Float = 0.05
    private let decrement: Float = -0.01
    
    private let api: AuthenticatedApiFacade = AuthenticatedApiFacade()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName())
        if let bundle = super.dataBundle {
            if let currentInterventionWeek = bundle[GoalSettingViewController.DATA_BUNDLE_GOAL_INTERVENTIONWEEK] {
                self.currentInterventionWeek = currentInterventionWeek as? InterventionWeekRepresentation
            }
            if let previousNumberOfSteps = bundle[GoalSettingViewController.DATA_BUNDLE_GOAL_LASTWEEK_STEPS] {
                if let lastWeekSteps = previousNumberOfSteps as? Int {
                    self.previousNumberOfSteps = lastWeekSteps
                    self.keepOldGoalButton.setTitle("Je préfère \(lastWeekSteps) pas", for: .normal)
                }
            } else {
                self.keepOldGoalButton.isHidden = true
            }
        }
        self.newStepGoalLabel.text = String(self.defaultGoal)
    }
    
    private func setGoal(_ value: Int) {
        Task {
            attempt {
                if let user = try await ResourcesManager.instance.getCurrentUser().value {
                    let goalController = GoalController(user: user)
                    if let iw = self.currentInterventionWeek {
                        attempt {
                            return try await goalController.createGoal(iw: iw, value: value)
                        }.then { goal in
                            DispatchQueue.main.async {
                                self.dismiss(animated: true)
                            }
                        }
                    }
                }
            }.catch { error in
                fatalError("Error while setting new goal: \(error)")
            }
        }
    }
    
    @IBAction func onConfirmClicked(_ sender: Any) {
        self.setGoal(Int(self.defaultGoal))
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "SET_NORMAL_GOAL")
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        self.setGoal(Int(self.previousNumberOfSteps))
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "SET_CUSTOM_GOAL")
    }
}
