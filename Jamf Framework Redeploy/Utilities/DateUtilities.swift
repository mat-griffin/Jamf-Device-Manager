//
//  DateUtilities.swift
//  Jamf Device Manager
//
//  Created by AI Assistant on 25/06/2025.
//  Extracted from SearchJamfView.swift
//

import Foundation

// MARK: - Date Formatting Utilities

func formatJamfDate(_ dateString: String?) -> String? {
    guard let dateString = dateString else { return nil }
    
    let formatter = DateFormatter()
    // Jamf typically returns dates in this format
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone(identifier: "UTC")
    
    if let date = formatter.date(from: dateString) {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        outputFormatter.timeZone = TimeZone.current
        return outputFormatter.string(from: date)
    }
    
    // Try alternative format if the first one fails
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    if let date = formatter.date(from: dateString) {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        outputFormatter.timeZone = TimeZone.current
        return outputFormatter.string(from: date)
    }
    
    // Return original string if parsing fails
    return dateString
}