//
//  ColorUtility.swift
//  excero
//
//  Created by Alessandro Silacci on 26.08.22.
//

import Foundation
import SpriteKit

class ColorUtility {
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
    
    // from: https://cocoacasts.com/from-hex-to-uicolor-and-back-in-swift
    static func toHex(color: UIColor, alpha: Bool = false) -> String? {
            guard let components = color.cgColor.components, components.count >= 3 else {
                return nil
            }

            let r = Float(components[0])
            let g = Float(components[1])
            let b = Float(components[2])
            var a = Float(1.0)

            if components.count >= 4 {
                a = Float(components[3])
            }

            if alpha {
                return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
            } else {
                return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
            }
        }
}
