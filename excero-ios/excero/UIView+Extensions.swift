//
//  UIView+Extensions.swift
//  excero
//
//  Created by Alessandro Silacci on 22.09.22.
//

import Foundation
import UIKit

// from: https://www.hackingwithswift.com/example-code/uikit/how-to-find-the-view-controller-responsible-for-a-view
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            print("responder")
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            print("uiview")
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
