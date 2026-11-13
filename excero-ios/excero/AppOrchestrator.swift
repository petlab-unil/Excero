//
//  AppOrchestrator.swift
//  excero
//
//  Created by Alessandro on 29.09.23.
//

import Foundation
import UIKit

class AppOrchestrator {
    struct StoryBoardBundle {
        var storyboardName: String
        var viewName: String
        var rootWindow: UIWindow
        var animated: Bool?
    }
    
    static let instance = AppOrchestrator()
    static let ORCHESTRATOR_EVENT_LOAD_STORYBOARD = "ORCHESTRATOR_EVENT_LOAD_STORYBOARD"
    private let eventDispatcher = EventDispatcher.instance
    private var lastLoadedView: String?
    private var lastLoadedStoryBoard: String?
    
    internal init() {
        self.lastLoadedStoryBoard = nil
        self.lastLoadedView = nil
        self.eventDispatcher.subscribe() { event in
            if event.identifier == AppOrchestrator.ORCHESTRATOR_EVENT_LOAD_STORYBOARD {
                guard let content = event.content as? StoryBoardBundle else {
                    print("No content in orchestrator event")
                    return
                }
                if let animated = content.animated {
                    self.loadStoryboard(storyboardName: content.storyboardName, viewName: content.viewName, rootWindow: content.rootWindow, animated: animated)
                } else {
                    self.loadStoryboard(storyboardName: content.storyboardName, viewName: content.viewName, rootWindow: content.rootWindow)
                }
            }
        }
    }
    
    func loadStoryboard(storyboardName: String, viewName: String, rootWindow: UIWindow, animated: Bool = false) {
        if let lastLoadedView = self.lastLoadedView, let lastLoadedStoryBoard = self.lastLoadedStoryBoard, lastLoadedView == viewName && lastLoadedStoryBoard == storyboardName {
            return
        } else {
            self.lastLoadedView = viewName
            self.lastLoadedStoryBoard = storyboardName
        }
        
        DispatchQueue.main.async {
            var mainView: UIStoryboard
            var startingVC: UIViewController
            mainView = UIStoryboard(name: storyboardName, bundle: nil)
            startingVC = mainView.instantiateViewController(withIdentifier: viewName) as UIViewController
            rootWindow.rootViewController?.dismiss(animated: animated)
            rootWindow.rootViewController = startingVC
        }
    }
    
    
}
