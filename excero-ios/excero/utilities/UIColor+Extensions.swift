//
//  UIColor+Extensions.swift
//  excero
//
//  Created by Alessandro on 29.04.24.
//

import Foundation
import UIKit
extension UIColor {
    
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }
    
    static func dynamicHEXColor(light: String, dark: String) -> UIColor {
        return UIColor.dynamicColor(light: UIColor.fromHex(hexString: light), dark: UIColor.fromHex(hexString: dark))
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
    
    // from: https://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
    static func fromHex(hexString: String, alpha: CGFloat = 1.0) -> UIColor {

        // Convert hex string to an integer
        let hexint = Int(UIColor.intFromHexString(hexStr: hexString))
        let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexint & 0xff) >> 0) / 255.0

        // Create color object, specifying alpha as well
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }
}
