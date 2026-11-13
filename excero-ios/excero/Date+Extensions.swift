//
//  Date+Extensions.swift
//  excero
//
//  Created by Alessandro on 17.11.23.
//

import Foundation

extension Date {
    func localDate() -> Date {
        let utc = self
        let tzOffset = Double(TimeZone.current.secondsFromGMT(for: utc))
        guard let localizedDate = Calendar.current.date(byAdding: .second, value: Int(tzOffset), to: utc) else { return Date() }
        
        return localizedDate
    }
}
