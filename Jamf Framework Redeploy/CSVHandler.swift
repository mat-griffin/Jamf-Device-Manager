//
//  CSVHandler.swift
//  Jamf Device Manager
//
//

import Foundation
import UniformTypeIdentifiers

struct ComputerRecord: Identifiable, Hashable {
    let id = UUID()
    let serialNumber: String
    let computerName: String?
    let notes: String?
    var status: DeploymentStatus = .pending
    var errorMessage: String?
    var jamfComputerID: Int?
    
    enum DeploymentStatus {
        case pending
        case inProgress
        case completed
        case failed
    }
}

class CSVHandler: ObservableObject {
    @Published var computers: [ComputerRecord] = []
    @Published var isProcessing = false
    @Published var processedCount = 0
    @Published var totalCount = 0
    
    func parseCSV(from url: URL) throws -> [ComputerRecord] {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { 
            if hasAccess {
                url.stopAccessingSecurityScopedResource() 
            }
        }
        
        // Try to read the file even if security scoped resource access fails
        // This might work for drag-and-drop scenarios
        
        let content = try String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVError.emptyFile
        }
        
        var records: [ComputerRecord] = []
        let headerLine = lines.first?.lowercased() ?? ""
        let hasHeaders = headerLine.contains("serial") || headerLine.contains("computer") || headerLine.contains("name")
        
        let dataLines = hasHeaders ? Array(lines.dropFirst()) : lines
        
        for (index, line) in dataLines.enumerated() {
            do {
                let record = try parseCSVLine(line, lineNumber: index + (hasHeaders ? 2 : 1))
                records.append(record)
            } catch CSVError.missingSerialNumber {
                // Skip lines with missing serial numbers but continue processing
                continue
            } catch {
                // For other errors, continue but could log if needed
                continue
            }
        }
        
        guard !records.isEmpty else {
            throw CSVError.noValidRecords
        }
        
        return records
    }
    
    private func parseCSVLine(_ line: String, lineNumber: Int) throws -> ComputerRecord {
        let fields = parseCSVFields(line)
        
        guard !fields.isEmpty else {
            throw CSVError.emptyLine
        }
        
        let serialNumber = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !serialNumber.isEmpty && serialNumber.lowercased() != "serial number" else {
            throw CSVError.missingSerialNumber
        }
        
        let computerName = fields.count > 1 ? fields[1].trimmingCharacters(in: .whitespacesAndNewlines) : nil
        let notes = fields.count > 2 ? fields[2].trimmingCharacters(in: .whitespacesAndNewlines) : nil
        
        return ComputerRecord(
            serialNumber: serialNumber,
            computerName: computerName?.isEmpty == true ? nil : computerName,
            notes: notes?.isEmpty == true ? nil : notes
        )
    }
    
    private func parseCSVFields(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                if inQuotes && i < line.index(before: line.endIndex) && line[line.index(after: i)] == "\"" {
                    currentField.append("\"")
                    i = line.index(after: i)
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        fields.append(currentField)
        return fields
    }
    
    func loadComputers(from url: URL) throws {
        computers = try parseCSV(from: url)
        totalCount = computers.count
        processedCount = 0
    }
    
    func resetStatus() {
        for i in computers.indices {
            computers[i].status = .pending
            computers[i].errorMessage = nil
        }
        processedCount = 0
    }
    
    func clearComputers() {
        computers = []
        totalCount = 0
        processedCount = 0
    }
    
    func updateComputerStatus(_ computerId: UUID, status: ComputerRecord.DeploymentStatus, error: String? = nil, jamfComputerID: Int? = nil) {
        if let index = computers.firstIndex(where: { $0.id == computerId }) {
            computers[index].status = status
            computers[index].errorMessage = error
            if let jamfID = jamfComputerID {
                computers[index].jamfComputerID = jamfID
            }
            
            if status == .completed || status == .failed {
                processedCount += 1
            }
        }
    }
}

enum CSVError: LocalizedError {
    case emptyFile
    case emptyLine
    case missingSerialNumber
    case parseError(line: Int, message: String)
    case noValidRecords
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "CSV file is empty"
        case .emptyLine:
            return "Empty line encountered"
        case .missingSerialNumber:
            return "Serial number is required"
        case .parseError(let line, let message):
            return "Parse error on line \(line): \(message)"
        case .noValidRecords:
            return "No valid computer records found in CSV"
        }
    }
}

extension UTType {
    static let csv = UTType(filenameExtension: "csv")!
}