//
//  Keychain.swift
//  Jamf Device Manager
//
//  Created by Richard Mallion on 10/01/2023.
//  Updated by Mat Griffin on 18/06/2025.

import Foundation
import Security

let kSecAttrAccountString          = NSString(format: kSecAttrAccount)
let kSecValueDataString            = NSString(format: kSecValueData)
let kSecClassGenericPasswordString = NSString(format: kSecClassGenericPassword)

class Keychain {
    
    func save(service: String, account: String, data: String) {
        
        if let password = data.data(using: String.Encoding.utf8) {
            var keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                kSecAttrService as String: service,
                                                kSecAttrAccount as String: account,
                                                kSecValueData as String: password]
            
            // see if credentials already exist for server
            let accountCheck = retrieve(service: service)
            if accountCheck.count == 0 {
                // try to add new credentials, if account exists we'll try updating it
                let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
                if (addStatus != errSecSuccess) {
                    if let addErr = SecCopyErrorMessageString(addStatus, nil) {
                        print("[addStatus] Write failed for new credentials: \(addErr)")
                    }
                }
            } else {
                // credentials already exist, try to update
                keychainQuery = [kSecClass as String: kSecClassGenericPasswordString,
                                 kSecAttrService as String: service,
                                 kSecMatchLimit as String: kSecMatchLimitOne,
                                 kSecReturnAttributes as String: true]
                let updateStatus = SecItemUpdate(keychainQuery as CFDictionary, [kSecAttrAccountString:account,kSecValueDataString:password] as CFDictionary)
                if (updateStatus != errSecSuccess) {
                    if let updateErr = SecCopyErrorMessageString(updateStatus, nil) {
                        print("[updateStatus] Update failed for existing credentials: \(updateErr)")
                    }
                }
            }
        }
    }
    
    func retrieve(service: String) -> [String] {
        
        var storedCreds = [String]()
        
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                            kSecAttrService as String: service,
                                            kSecMatchLimit as String: kSecMatchLimitOne,
                                            kSecReturnAttributes as String: true,
                                            kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        guard status != errSecItemNotFound else { return [] }
        guard status == errSecSuccess else { return [] }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let account = existingItem[kSecAttrAccount as String] as? String,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else {
                return []
        }
        storedCreds.append(account)
        storedCreds.append(password)
        return storedCreds
    }
}
