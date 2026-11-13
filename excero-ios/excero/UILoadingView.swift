//
//  UILoadingView.swift
//  excero
//
//  Created by Alessandro on 15.09.23.
//

import Foundation
import UIKit


class UILoadingView: UIView {
    
    
    private var _backgroundTint: UIColor = .black
    private var _textTint: UIColor = .white
    
    private var _loadingIndicator: UIShapeableProgressView?
    private var _loadingText: UITextView?
    
    private let marginIndicatorText: CGFloat = 30.0
    
    var loadingIndicatorView: UIShapeableProgressView? {
        set {
            self._loadingIndicator?.removeFromSuperview()
            self._loadingIndicator = newValue
            self.addSubview(self._loadingIndicator!)
            self.computeConstraints()
        }
        get { return self._loadingIndicator }
    }
    
    var loadingText: String? {
        set {
            if let textView = self._loadingText {
                textView.text = newValue
            } else {
                self._loadingText = UITextView(frame: CGRect(x: 0, y: 0, width: self.frame.width - 20, height: self.frame.height - 20))
                self._loadingText!.text = newValue
                self._loadingText!.textAlignment = .center
                self._loadingText!.backgroundColor = .clear
                //self._loadingText!.font?.withSize(30)
                self.addSubview(self._loadingText!)
                self.computeConstraints()
            }
        }
        get { return self._loadingText?.text }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    internal override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .systemGray6
        self.layer.cornerRadius = 20.0
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 4
    }
    
    private func computeConstraints() {
        guard let indicatorView = self._loadingIndicator else { return }
        guard let textView = self._loadingText else { return }
        
        
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        let indicatorTopConstraint = NSLayoutConstraint(item: indicatorView, attribute: .top, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: self.marginIndicatorText)
        let indicatorTextConstraint = NSLayoutConstraint(item: textView, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: indicatorView, attribute: .bottom, multiplier: 1, constant: indicatorView.frame.height / 2 + self.marginIndicatorText)
        let indicatorCenterXConstraint = NSLayoutConstraint(item: indicatorView, attribute: .centerX, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .centerX, multiplier: 1.0, constant: -indicatorView.frame.width/2)
        let textViewWidthConstraint = NSLayoutConstraint(item: textView, attribute: .width, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .width, multiplier: 1, constant: 0.0)
        let textViewHeightConstraint = NSLayoutConstraint(item: textView, attribute: .height, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .height, multiplier: 1, constant: 0.0)
        self.addConstraints([indicatorTopConstraint, indicatorTextConstraint, indicatorCenterXConstraint, textViewWidthConstraint, textViewHeightConstraint])
    }
    
}
