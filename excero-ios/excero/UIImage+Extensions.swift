//
//  UIImage+Extensions.swift
//  excero
//
//  Created by Alessandro Silacci on 16.09.22.
//

import Foundation
import UIKit
extension UIImage {
    func resize(size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    func storeSprite(at directory: FileManager.SearchPathDirectory, fileName: String) ->URL? {
        do {
            let docDirectory = try FileManager.default.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
            var isDir: ObjCBool = true
            if FileManager.default.fileExists(atPath: docDirectory.absoluteString, isDirectory: &isDir) {
                try FileManager.default.createDirectory(at: docDirectory.absoluteURL, withIntermediateDirectories: true)
            }
            guard let data = pngData() else { return nil }
            let finalUrl = docDirectory.appendingPathComponent(fileName + ".png")
            try data.write(to: finalUrl)
            print("wrote file to: \(finalUrl)")
            return finalUrl
        } catch {
            print(error)
            return nil
        }
    }
    
}

extension UIImage {
    convenience init?(fileURL url: URL, scale: CGFloat = 1.0) {
        do {
            let data = try Data(contentsOf: url)
            self.init(data: data, scale:scale)
        } catch {
            print("error loading uiimage from URL: \(url) output is: \(error)")
            return nil
        }
    }
    
}
