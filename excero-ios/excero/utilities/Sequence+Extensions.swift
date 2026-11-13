//
//  Sequence+Extensions.swift
//  excero
//
//  Created by Alessandro on 10.05.24.
//

import Foundation
// From: https://www.swiftbysundell.com/articles/async-and-concurrent-forEach-and-map/
extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}
