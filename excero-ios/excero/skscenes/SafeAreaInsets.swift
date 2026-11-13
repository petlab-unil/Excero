//
//  SafeAreaInsets.swift
//  excero
//
//  Created by Alessandro on 17.05.24.
//

import Foundation
struct SafeAreaInsets {
    public let top: CGFloat
    public let bottom: CGFloat
    public let left: CGFloat
    public let right: CGFloat
    
    public static var zero: SafeAreaInsets {
        SafeAreaInsets(top: 0, bottom: 0, left: 0, right: 0)
    }
}
