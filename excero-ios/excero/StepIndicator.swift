//
//  StepIndicator.swift
//  excero
//
//  Created by Alessandro Silacci on 26.08.22.
//

import Foundation
import SpriteKit

class StepIndicator: SKNode {
    private var label: SKLabelNode = SKLabelNode()
    
    private let sharingStepsEnabled: Bool = false
    
    internal init(size: CGSize, position: CGPoint) {
        super.init()
        let backgroundShape = SKShapeNode(rect: CGRect(x: -1 * size.width/2, y: -1 * size.height/2, width: size.width, height: size.height))
        backgroundShape.fillColor = UIColor.dynamicHEXColor(light: Constants.STEP_INDICATOR_BACKGROUND_COLOR_LIGHT, dark: Constants.STEP_INDICATOR_BACKGROUND_COLOR_DARK)
        
        let stepIndicatorTexture = SKTexture(imageNamed: "ui_step_indicator")
        let stepIndicator = SKSpriteNode(texture: stepIndicatorTexture)
        let tempIndicatorSize = stepIndicator.frame.size
        let ratioIndicator = size.height / tempIndicatorSize.height
        
        stepIndicator.size = CGSize(width: tempIndicatorSize.width * ratioIndicator, height: size.height)
        stepIndicator.position = CGPoint(x: -1 * size.width/2 + stepIndicator.size.width/2, y: 0)
        self.position = position
        
        let font = UIFont.preferredFont(forTextStyle: .headline)
        if self.sharingStepsEnabled {
            label.position = CGPoint(x: 0, y: label.frame.size.height)
        } else {
            label.position = CGPoint(x: stepIndicator.size.width/2, y: label.frame.size.height)
        }
        label.fontColor = UIColor.dynamicHEXColor(light: Constants.DEFAULT_TEXT_COLOR_LIGHT, dark: Constants.DEFAULT_TEXT_COLOR_DARK)
        label.fontName = font.fontName.replacingOccurrences(of: ".", with: "")
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        let stepSharingButton = SKSpriteNode(texture: SKTexture(image: UIImage(systemName: "square.and.arrow.up")!), size: CGSize(width: 20, height: 24))
        stepSharingButton.position = CGPoint(x: backgroundShape.frame.width/2 - 30, y: 0)
        stepSharingButton.zPosition = 10
        stepSharingButton.name = "share"
        self.isUserInteractionEnabled = true
        
        
        var corners = UIRectCorner()
        corners = corners.union(.bottomLeft)
        corners = corners.union(.bottomRight)
        corners = corners.union(.topLeft)
        corners = corners.union(.topRight)
        let cornerRadii = CGSize(width: 200, height: size.height)
        backgroundShape.path = UIBezierPath(roundedRect: CGRect(x: -1 * (backgroundShape.frame.width/2),
                                                                y: -1 * (backgroundShape.frame.height/2),
                                                                width: backgroundShape.frame.width,
                                                                height: backgroundShape.frame.height),
                                            byRoundingCorners: corners,
                                            cornerRadii: cornerRadii).cgPath
    
        if self.sharingStepsEnabled {
            self.addChild(stepSharingButton)
        }
        self.addChild(backgroundShape)
        self.addChild(label)
        self.addChild(stepIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setStepValue(value: Double) {
        self.label.text = String(Int(value))
    }
    
    private func shareSteps(steps: Int) {
        let event = EventDispatcher.DispatchableEvent(identifier: "goToChat_segue")
        event.content = steps as AnyObject
        EventDispatcher.instance.emit(event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let pos = t.location(in: self)
            let node = self.atPoint(pos)
            if node.name == "share" {
                self.shareSteps(steps: Int(self.label.text ?? "0") ?? 0)
            }
        }
    }
}
