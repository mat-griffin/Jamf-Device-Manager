//
//  Logger.swift
//  Jamf Device Manager
//
//  Created by Richard Mallion on 16/08/2024.
//  Updated by Mat Griffin on 18/06/2025.

import Foundation
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    //Categories
    static let loggerapi = Logger(subsystem: subsystem, category: "api")  // added lnh
}
