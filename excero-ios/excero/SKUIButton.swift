//
//  UIButton.swift
//  excero
//
//  Created by Alessandro Silacci on 24.08.22.
//

import Foundation
import SpriteKit

class SKUIButton: SKSpriteNode {
    private var callback: () -> Void
    private var _disabled: Bool = false
    
    var disabled: Bool {
        get {
            return self._disabled
        }
        set {
            self._disabled = newValue
        }
    }
    
    
    internal init(color: String, text: String? = nil, size: CGSize, position: CGPoint, paddingTopBottom: CGFloat? = 20,
                  paddingLeftRight: CGFloat? = 20, cornerRadius: CGFloat? = 0, disabled: Bool = false, callback: @escaping () -> Void) {
        
        self.callback = callback
        super.init(texture: nil, color: UIColor.clear, size: size)
        
        self.isUserInteractionEnabled = true
        self.position = position
        self._disabled = disabled
        
        if let text = text {
            let label = SKLabelNode(text: text)
            label.position = CGPoint(x: 0, y: -1 * label.frame.size.height/2)
            label.fontName = "Arial Bold"
            var shapeSize = CGSize(width: label.frame.size.width, height: label.frame.size.height)
            if let paddingLeftRight = paddingLeftRight {
                shapeSize.width += paddingLeftRight
            }
            if let paddingTopBottom = paddingTopBottom {
                shapeSize.height += paddingTopBottom
            }
            let buttonShape = SKShapeNode(rect: CGRect(x: -1 * shapeSize.width/2, y: -1 * shapeSize.height/2, width: shapeSize.width, height: shapeSize.height))
            var corners = UIRectCorner()
            corners = corners.union(.bottomLeft)
            corners = corners.union(.bottomRight)
            corners = corners.union(.topLeft)
            corners = corners.union(.topRight)
            let cornerRadii = CGSize(width: 200, height: size.height)
            buttonShape.path = UIBezierPath(roundedRect: CGRect(x: -1 * (buttonShape.frame.width/2),
                                                                    y: -1 * (buttonShape.frame.height/2),
                                                                    width: buttonShape.frame.width,
                                                                    height: buttonShape.frame.height),
                                                byRoundingCorners: corners,
                                                cornerRadii: cornerRadii).cgPath
            buttonShape.fillColor = SKUIButton.colorWithHexString(hexString: color)
            self.addChild(buttonShape)
            self.addChild(label)
        } else {
            let buttonShape = SKShapeNode(rect: CGRect(x: -1 * size.width/2, y: -1 * size.height/2, width: size.width, height: size.height))
            var corners = UIRectCorner()
            corners = corners.union(.bottomLeft)
            corners = corners.union(.bottomRight)
            corners = corners.union(.topLeft)
            corners = corners.union(.topRight)
            let cornerRadii = CGSize(width: 200, height: size.height)
            buttonShape.path = UIBezierPath(roundedRect: CGRect(x: -1 * (buttonShape.frame.width/2),
                                                                    y: -1 * (buttonShape.frame.height/2),
                                                                    width: buttonShape.frame.width,
                                                                    height: buttonShape.frame.height),
                                                byRoundingCorners: corners,
                                                cornerRadii: cornerRadii).cgPath
            buttonShape.fillColor = SKUIButton.colorWithHexString(hexString: color)
            self.addChild(buttonShape)
        }
    }
    
    internal init(imageName: String, size: CGSize, position: CGPoint, callback: @escaping () -> Void) {
        self.callback = callback
        let texture = SKTexture(imageNamed: imageName)
        super.init(texture: texture, color: UIColor.clear, size: size)
        self.position = position
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.callback = {
            
        }
        super.init(coder: aDecoder)
    }
    
    
    // from: https://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
    static func colorWithHexString(hexString: String, alpha:CGFloat = 1.0) -> UIColor {

        // Convert hex string to an integer
        let hexint = Int(self.intFromHexString(hexStr: hexString))
        let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexint & 0xff) >> 0) / 255.0

        // Create color object, specifying alpha as well
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }

    private static func intFromHexString(hexStr: String) -> UInt32 {
        var hexInt: UInt32 = 0
        // Create scanner
        let scanner: Scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        // Scan hex value
        hexInt = UInt32(bitPattern: scanner.scanInt32(representation: .hexadecimal) ?? 0)
        return hexInt
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self._disabled {
            self.callback()
        }
    }
    
}
