//
//  UICircularProgressView.swift
//  excero
//
//  Created by Alessandro on 15.09.23.
//

import Foundation
import QuartzCore
import UIKit

class UIShapeableProgressView: UIView {
    
    private var progressLayer: CAShapeLayer = CAShapeLayer()
    private var trackLayer: CAShapeLayer = CAShapeLayer()
    
    private var defaultRadius: CGFloat = 10.0
    private var _pathWidth: CGFloat = 1.0
    private let animationDuration = 0.1
    
    
    private var _progressTintColor: UIColor = .gray
    private var _trackTintColor: UIColor = .systemBlue
    
    var path: UIBezierPath?
    var pathWidth: CGFloat {
        set {
            _pathWidth = newValue
            self.setupPath()
        }
        get { return _pathWidth }
    }
    
    var progressTintColor: UIColor {
        set {
            _progressTintColor = newValue
            self.progressLayer.strokeColor = _progressTintColor.cgColor
        }
        get {
            return _progressTintColor
        }
    }
    
    var trackTintColor: UIColor {
        set {
            _trackTintColor = newValue
            self.trackLayer.strokeColor = _trackTintColor.cgColor
        }
        get {
            return _trackTintColor
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupPath()
    }
    
    internal init(path: UIBezierPath, frame: CGRect) {
        super.init(frame: frame)
        self.path = path
        self.setupPath()
    }
    
    override convenience init(frame: CGRect) {
        self.init(path: UIBezierPath(arcCenter: CGPoint(x: frame.size.width/2, y: frame.size.height/2), radius: (frame.size.width/2), startAngle: CGFloat(-0.5 * .pi), endAngle: (1.5 * .pi), clockwise: true), frame: frame)
    }
    
    private func setupPath() {
        if let path = self.path {
            self.trackLayer.path = path.cgPath
            self.progressLayer.path = path.cgPath
        }
        
        self.trackLayer.fillColor = UIColor.clear.cgColor
        self.trackLayer.strokeColor = self.trackTintColor.cgColor
        self.trackLayer.lineWidth = self.pathWidth
        self.trackLayer.strokeEnd = 1.0
        
        self.progressLayer.fillColor = UIColor.clear.cgColor
        self.progressLayer.strokeColor = self.progressTintColor.cgColor
        self.progressLayer.lineWidth = self.pathWidth
        self.progressLayer.strokeEnd = 0.0
        
        self.layer.addSublayer(self.trackLayer)
        self.layer.addSublayer(self.progressLayer)
    }
    
    func setProgress(_ progress: Float, animated: Bool) {
        /*if !animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = self.animationDuration
            animation.fromValue = 0
            animation.toValue = CGFloat(progress)
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.progressLayer.strokeEnd = CGFloat(progress)
            self.progressLayer.add(animation, forKey: "animationprogress")
        } else {*/
            self.progressLayer.strokeEnd = CGFloat(progress)
        //}
        
    }
    
}
