//
//  UIGradientColorPicker.swift
//  excero
//
//  Created by Alessandro Silacci on 30.08.22.
//

import Foundation
import SpriteKit

class UIGradientColorPicker: SKNode {
    private var colorSwatches: [UIColor]?
    private var swatchCircleShape: CGSize = CGSize(width: 40, height: 40)
    private var horizontal: Bool?
    private var callback: (([UIColor]) -> Void)?
    
    
    internal init(colorSwatches: [UIColor], spacing: CGFloat = 10, horizontal: Bool? = false, callback: (([UIColor]) -> Void)?) {
        super.init()
        self.colorSwatches = colorSwatches
        self.createSwatches(colorSwatches: colorSwatches, spacing: spacing)
        self.isUserInteractionEnabled = true
        
        if let direction = horizontal {
            self.horizontal = direction
        }
        if let callback = callback {
            self.callback = callback
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func createSwatches(colorSwatches: [UIColor], spacing: CGFloat) {
        let color1 = colorSwatches[0]
        let color2 = colorSwatches[1]
        
        let rect = CGRect(x: 0, y: 0, width: self.swatchCircleShape.width, height: self.swatchCircleShape.height)
        let circle1 = SKShapeNode(ellipseIn: rect)
        let circle2 = SKShapeNode(ellipseIn: rect)
        
        if let _ = horizontal {
            circle1.position = CGPoint(x: 0, y: -1 * spacing)
        } else {
            circle1.position = CGPoint(x: -1 * spacing, y: 0)
        }
                
        circle1.fillColor = color1
        circle2.fillColor = color2
        self.addChild(circle1)
        self.addChild(circle2)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.callback?(self.colorSwatches!)
    }
    
}
