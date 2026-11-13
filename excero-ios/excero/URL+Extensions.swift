//
//  URL+Extensions.swift
//  excero
//
//  Created by Alessandro Silacci on 03.09.2024.
//

import Foundation

extension URL {
    func valueOf(_ queryParameterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
    }
}
