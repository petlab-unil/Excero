//
//  EmbeddedSKScene.swift
//  excero
//
//  Created by Alessandro on 19.02.24.
//

import Foundation
import SpriteKit

class EmbeddedSKScene: SKScene {
    private var _mainViewControllerInstanceID: String?
    
    
    public var mainViewControllerInstanceID: String? {
        get {
            return self._mainViewControllerInstanceID
        }
        set {
            self._mainViewControllerInstanceID = newValue
        }
    }
    
    
    public func goToView(viewName: String) {
        let event = EventDispatcher.DispatchableEvent(identifier: (self._mainViewControllerInstanceID ?? "") + "gameview_change")
        event.content = viewName as AnyObject
        EventDispatcher.instance.emit(event)
    }
    
}
