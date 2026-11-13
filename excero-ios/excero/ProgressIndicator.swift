//
//  ProgressIndicator.swift
//  excero
//
//  Created by Alessandro Silacci on 31.08.22.
//

import Foundation
import SpriteKit
import UIKit

class ProgressIndicator: SKNode {
    private var size: CGSize?
    private var max: Int = 0
    private var current: Int = 0
    
    private var isPeered: Bool = false
    private var peerMax: Int?
    private var peerCurrent: Int = 0
    
    private var personnalIndicator: SKNode?
    private var peerIndicator: SKNode?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    internal init(size: CGSize, max: Int) {
        self.size = size
        self.max = max
        super.init()
        self.drawProgressBar()
        self.drawProgressIndicators()
    }
    
    internal init(size: CGSize, max: Int, peerMax: Int) {
        self.size = size
        self.max = max
        self.peerMax = peerMax
        self.isPeered = true
        super.init()
        self.drawProgressBar()
        self.drawProgressIndicators(hasPeer: true)
    }
    
    
    
    private func drawProgressBar() {
        let line = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 4, height: self.size!.height))
        let bottomPoint = SKShapeNode(ellipseIn: CGRect(x: 0, y: 0, width: self.size!.width, height: self.size!.width))
        let topPoint = SKShapeNode(ellipseIn: CGRect(x: 0, y: 0, width: self.size!.width, height: self.size!.width))
        
        bottomPoint.position = CGPoint(x: (-1 * bottomPoint.frame.size.width/2) + (line.frame.size.width/2), y: -1 * bottomPoint.frame.size.height/2)
        topPoint.position = CGPoint(x: (-1 * topPoint.frame.size.width/2) + (line.frame.size.width/2), y: self.size!.height - topPoint.frame.size.height/2)
        line.position = CGPoint(x: 0, y: 0)
        
        line.fillColor = UIColor.black
        bottomPoint.fillColor = UIColor.black
        topPoint.fillColor = UIColor.black
        line.strokeColor = UIColor.clear
        bottomPoint.strokeColor = UIColor.clear
        topPoint.strokeColor = UIColor.clear
        
        self.addChild(line)
        self.addChild(bottomPoint)
        self.addChild(topPoint)
    }
    
    private func createIndicator(inverted: Bool = false) -> SKNode {
        let indicator = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 35, height: 20))
        indicator.fillColor = UIColor.black
        var corners = UIRectCorner()
        if inverted {
            indicator.position = CGPoint(x: 16, y: 0) // FIXME: dirty
            
            corners = corners.union(.bottomRight)
            corners = corners.union(.topRight)
        } else {
            indicator.position = CGPoint(x: -1 * indicator.frame.size.width - 10, y: 0)
            let youLabel = SKLabelNode(text: "moi")
            youLabel.fontSize = indicator.frame.size.height-2
            youLabel.horizontalAlignmentMode = .center
            youLabel.verticalAlignmentMode = .center
            youLabel.position = CGPoint(x: indicator.frame.size.width/2, y: indicator.frame.size.height/2)
            youLabel.fontName = "Arial"
            indicator.addChild(youLabel)
            corners = corners.union(.topLeft)
            corners = corners.union(.bottomLeft)
        }
        let cornerRadii = CGSize(width: 35, height: 20)
        indicator.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: indicator.frame.width, height: indicator.frame.height),
                                            byRoundingCorners: corners, cornerRadii: cornerRadii).cgPath
        indicator.lineWidth = 0.0
        let triangle = SKShapeNode()
        let path = UIBezierPath()
        if inverted {
            path.move(to: CGPoint(x: 0.0, y: 0.0))
            path.addLine(to: CGPoint(x: -10, y: indicator.frame.size.height/2))
            path.addLine(to: CGPoint(x: 0.0, y: indicator.frame.size.height))
        } else {
            path.move(to: CGPoint(x: indicator.frame.size.width, y: 0.0))
            path.addLine(to: CGPoint(x: indicator.frame.size.width + 10, y: indicator.frame.size.height/2))
            path.addLine(to: CGPoint(x: indicator.frame.size.width, y: indicator.frame.size.height))
        }
        triangle.path = path.cgPath
        triangle.lineWidth = 0.0
        triangle.fillColor = UIColor.black
        indicator.addChild(triangle)
        return indicator
    }
    
    private func drawProgressIndicators(hasPeer: Bool = false) {
        self.personnalIndicator = self.createIndicator()
        self.addChild(self.personnalIndicator!)
        
        if hasPeer {
            self.peerIndicator = self.createIndicator(inverted: true)
            self.addChild(self.peerIndicator!)
        }
    }
    
    private func computeProgress(value: Int, max: Int) -> Double {
        if value >= max {
            return self.size!.height
        }
        return (Double(value) * self.size!.height) / Double(max)
    }
    
    func setProgress(value: Int, peer: Bool = false) {
        var max = self.max
        if peer {
            max = self.peerMax!
        }
        let newY = self.computeProgress(value: value, max: max)
        if peer {
            self.peerIndicator!.position.y = newY
        } else {
            self.personnalIndicator!.position.y = newY
        }
    }
}
