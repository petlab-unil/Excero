//
//  GameViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 20.07.22.
//

import UIKit
import SpriteKit
import GameplayKit
import HealthKit

class GameViewController: UIViewController, InitialDataExpanded {
    public static let START_START_PARAM_KEY: String = "GameViewController.InitialDataExpanded.START_START_PARAM_KEY"
    
    @IBOutlet var mainView: SKView!
    
    private var initialSceneName: String?
    
    private var sceneHistory: Stack<String> = Stack<String>()
    private var currentScene: String?
    public let instanceUUID: String = UUID().uuidString
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let modelController = ModelController<Avatar>() // FIXME: Could use new AvatarController
        if let _ = modelController.getLast() {
            if let initialSceneName = self.initialSceneName {
                self.currentScene = initialSceneName
                self.goToView(viewName: self.currentScene!)
                ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName() + "_" + self.currentScene!)
            } else {
                self.currentScene = "MainScene"
                self.goToView(viewName: self.currentScene!)
                ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName() + "_" + self.currentScene!)
            }
        } else {
            ResourcesManager.logger.info("GameViewController.viewDidAppear started avatar personalization view as no avatar was found locally.")
            self.currentScene = "GameScene"
            self.goToView(viewName: self.currentScene!)
            ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName() + "_" + self.currentScene!)
        }
        EventDispatcher.instance.subscribe() { event in
            if event.identifier == self.instanceUUID + "gameview_change" {
                if let viewName = event.content as? String {
                    self.sceneHistory.push(self.currentScene!)
                    self.currentScene = viewName
                    self.goToView(viewName: self.currentScene!)
                }
            }
            if event.identifier == self.instanceUUID + "gameview_previous" {
                if !self.sceneHistory.isEmpty {
                    self.currentScene = self.sceneHistory.pop()
                    self.goToView(viewName: self.currentScene!)
                }
            }
        }
    }
    
    func goToView(viewName: String, type: SKTransitionDirection? = nil,
                  duration: TimeInterval = 0.5) {
        if let view = self.view as? SKView {
            if let scene = SKScene(fileNamed: viewName) {
                (scene as! EmbeddedSKScene).mainViewControllerInstanceID = self.instanceUUID
                scene.scaleMode = .resizeFill
                scene.backgroundColor = .white
                if let transitionType = type {
                let transition = SKTransition.reveal(with: transitionType, duration: duration)
                    view.presentScene(scene, transition: transition)
                }
                else  {
                    view.presentScene(scene)
                }
            }
            
            view.ignoresSiblingOrder = false
            
            view.showsFPS = Constants.SHOW_DEBUG_DATA
            view.showsNodeCount = Constants.SHOW_DEBUG_DATA
        }
    }
    
    func setData(initialData: Dictionary<String, NSObject>) {
        if let value = initialData[GameViewController.START_START_PARAM_KEY] {
            let initialScene = value as! String
            self.initialSceneName = initialScene
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }
}
