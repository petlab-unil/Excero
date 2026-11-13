//
//  AvatarDisplayScene.swift
//  excero
//
//  Created by Alessandro on 16.02.24.
//

import Foundation
import SpriteKit
import HealthKit

class AvatarDisplayScene: EmbeddedSKScene {
    var displayAvatarCustomization: Bool = false
    var displayStepIndicator: Bool = false
    var displayGoalCompletionIndicator: Bool = false
    var displayPeerGoalCompletionIndicator: Bool = false
    
    
    private var healthkitStore: HKHealthStore?
    var currentRatio: CGSize?
    
    private var defaultDimensions: CGSize = CGSize(width: 428, height: 926)
    
    private var safeArea: SafeAreaInsets {
        guard let view = self.view else { return .zero }
        let halfedWidth = view.bounds.width/2
        let halfedHeight = view.bounds.height/2
        return SafeAreaInsets(top: halfedHeight - view.safeAreaInsets.top,
                              bottom: (-1 * halfedHeight) + view.safeAreaInsets.bottom,
                              left: (-1 * halfedWidth) + view.safeAreaInsets.left,
                              right: halfedWidth - view.safeAreaInsets.right)
    }
    
        
    override func willMove(from view: SKView) {
        self.removeAllChildren()
    }
    
    override func didMove(to view: SKView) {
        self.currentRatio = CGSize(width: self.view!.bounds.width/self.defaultDimensions.width,
                                   height: self.view!.bounds.height/self.defaultDimensions.height)
        self.backgroundColor = ColorUtility.colorWithHexString(hexString: "87CEEB")
        let backImage = SKSpriteNode(imageNamed: "ui_background")
        backImage.size = view.frame.size
        backImage.zPosition = 0
        self.addChild(backImage)
        
        self.setupParameterizedUIElements()
        self.loadAvatar()
    }
    
    private func setupParameterizedUIElements() {
        var stepIndicator: StepIndicator? = nil
        var progressBar: ProgressIndicator? = nil
        
        if (self.displayAvatarCustomization) {
            let avatarChangeProfile = SKUIButton(imageName: "ui_profile", size: CGSize(width: 30, height: 30),
                                                 position: CGPoint(x: self.safeArea.right - 30,
                                                                   y: self.safeArea.top - 30)) { () in
                self.openAvatarCustomization()
            }
            self.addChild(avatarChangeProfile)
        }
        if (self.displayStepIndicator) {
            stepIndicator = StepIndicator(size: CGSize(width: 160, height: 60), position: CGPoint(x: 0, y: self.safeArea.top - 60))
            if let stepIndicator = stepIndicator {
                stepIndicator.zPosition = 900
                self.addChild(stepIndicator)
            }
        }
        
        if (self.displayGoalCompletionIndicator) {
            if self.displayPeerGoalCompletionIndicator {
                progressBar = ProgressIndicator(size: CGSize(width: 15, height: 200), max: 10000, peerMax: 10000)
                if let progressBar = progressBar {
                    progressBar.zPosition = 900
                    progressBar.position = CGPoint(x: self.safeArea.left + 50, y: 0)
                    self.addChild(progressBar)
                }
            } else {
                progressBar = ProgressIndicator(size: CGSize(width: 15, height: 200), max: 10000)
                if let progressBar = progressBar {
                    progressBar.zPosition = 900
                    progressBar.position = CGPoint(x: self.safeArea.left + 50, y: 0)
                    self.addChild(progressBar)
                }
            }
        }
        #if targetEnvironment(simulator)
        let randomSteps = Int.random(in: 1...70000)
        if let indicator = stepIndicator {
            indicator.setStepValue(value: Double(randomSteps))
        }
        if let progressBar = progressBar {
            progressBar.setProgress(value: Int(randomSteps))
        }
        #else
        let _ = ResourcesManager.instance.stepOfDayStream.subscribe(onNext: {value in
            if let indicator = stepIndicator {
                indicator.setStepValue(value: Double(value.value))
            }
            if let progressBar = progressBar {
                progressBar.setProgress(value: Int(value.value))
            }
        })
        if self.displayPeerGoalCompletionIndicator {
            let _ = ResourcesManager.instance.peerStepsOfDayStream.subscribe(onNext: {value in
                if let progressBar = progressBar {
                    progressBar.setProgress(value: Int(value.value), peer: true)
                }
            })
        }
        #endif
    }
    
    public func loadAvatar() {
        
    }
    
    
    func openAvatarCustomization() {
        super.goToView(viewName: "GameScene")
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "USER_AVATAR_PERSONALIZATION")
    }
    
    
    private func countCurrentDaySteps(callback: @escaping (Double) -> Void) {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)
        let now = Date()
        let dayStart = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType!,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, steps, _ in
            guard let steps = steps, let sum = steps.sumQuantity() else {
                callback(0.0)
                return
            }
            callback(sum.doubleValue(for: HKUnit.count()))
        }
        self.healthkitStore!.execute(query)
    }
}
