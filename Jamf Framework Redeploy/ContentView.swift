//
//  ContentView.swift
//  Jamf Framework Redeploy
//
//  Created by Richard Mallion on 09/01/2023.
//

import SwiftUI

struct ContentView: View {
    
    @State private var jamfURL = ""
    @State private var userName = ""
    @State private var password = ""
    @State private var savePassword = false
    @State private var serialNumber = ""

    @State private var buttonDisabled = false

    @State private var showAlert = false

    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    @State private var selectedTab = 0

    var body: some View {
        
        VStack(spacing: 0) {
            
            Picker("Mode", selection: $selectedTab) {
                Text("Single Computer").tag(0)
                Text("Bulk Operations").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Group {
                if selectedTab == 0 {
                    SingleRedeployView(
                        jamfURL: $jamfURL,
                        userName: $userName,
                        password: $password,
                        savePassword: $savePassword,
                        serialNumber: $serialNumber,
                        buttonDisabled: $buttonDisabled,
                        showAlert: $showAlert,
                        alertMessage: $alertMessage,
                        alertTitle: $alertTitle
                    )
                } else {
                    BulkRedeployView(
                        jamfURL: jamfURL,
                        userName: userName,
                        password: password
                    )
                }
            }
        }
        .onAppear {
            let defaults = UserDefaults.standard
            userName = defaults.string(forKey: "userName") ?? ""
            jamfURL = defaults.string(forKey: "jamfURL") ?? ""
            savePassword = defaults.bool(forKey: "savePassword" )
            if savePassword  {
                let credentialsArray = Keychain().retrieve(service: "co.uk.mallion.Jamf-Framework-Redeploy")
                if credentialsArray.count == 2 {
                    userName = credentialsArray[0]
                    password = credentialsArray[1]
                }
            }
        }
    }
}

struct SingleRedeployView: View {
    @Binding var jamfURL: String
    @Binding var userName: String
    @Binding var password: String
    @Binding var savePassword: Bool
    @Binding var serialNumber: String
    @Binding var buttonDisabled: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @Binding var alertTitle: String
    
    var body: some View {
        VStack(alignment: .trailing){
            
            HStack(alignment: .center) {
              
                VStack(alignment: .trailing, spacing: 12.0) {
                    Text("Jamf Server URL:")
                    Text("Client ID:")
                    Text("Secret:")
                }

                
                VStack(alignment: .leading, spacing: 7.0) {
                    TextField("https://your-jamf-server.com" , text: $jamfURL)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: jamfURL) { newValue in
                            let defaults = UserDefaults.standard
                            defaults.set(jamfURL , forKey: "jamfURL")
                            updateAction()
                        }
                    TextField("Your Jamf Pro admin user name" , text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: userName) { newValue in
                            let defaults = UserDefaults.standard
                            defaults.set(userName , forKey: "userName")
                            updateAction()
                        }

                    SecureField("Your password" , text: $password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: password) { newValue in
                            if savePassword {
                                DispatchQueue.global(qos: .background).async {
                                    Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: password)
                                }
                            } else {
                                DispatchQueue.global(qos: .background).async {
                                    Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: "")
                                }
                            }
                            updateAction()
                        }
                }
            }
            .padding()
            .alert(isPresented: self.$showAlert,
                   content: {
                self.showCustomAlert()
            })
            
            Toggle(isOn: $savePassword) {
                Text("Save Password")
            }
            .toggleStyle(CheckboxToggleStyle())
            .offset(x: -260 , y: -10)
            .onChange(of: savePassword) { newValue in
                let defaults = UserDefaults.standard
                defaults.set(savePassword, forKey: "savePassword")
                if savePassword {
                    DispatchQueue.global(qos: .background).async {
                        Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: password)
                    }
                } else {
                    DispatchQueue.global(qos: .background).async {
                        Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: "")
                    }
                }

            }
            
            HStack {
                Text("Serial Number:")
                    .padding(.leading, 15)
                
                TextField("Mac Serial Number" , text: $serialNumber)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: serialNumber) { newValue in
                        updateAction()
                    }
            }
            .padding()
            
            Button(/*@START_MENU_TOKEN@*/"Redeploy"/*@END_MENU_TOKEN@*/) {
                Task {
                    await redploy()
                }
            }
            .padding()
            .disabled(buttonDisabled)
        }
        .onAppear {
            updateAction()
        }
        .alert(isPresented: $showAlert,
               content: {
            showCustomAlert()
        })
    }
    
    func updateAction() {
        if jamfURL.validURL && !userName.isEmpty && !password.isEmpty && !serialNumber.isEmpty {
            buttonDisabled = false
        } else {
            buttonDisabled = true
        }
    }
    
    func showCustomAlert() -> Alert {
        return Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
                )
    }

    func redploy() async {
        let jamfPro = JamfProAPI()
        
        let (authToken, _) = await jamfPro.getToken(jssURL: jamfURL, clientID: userName, secret: password)
        guard let authToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            return
        }
        
        
        //1.0.2 Change
        let (computerID, computerResponse) = await jamfPro.getComputerID(jssURL: jamfURL, authToken: authToken.access_token, serialNumber: serialNumber)
        
        guard let computerID else {
            alertMessage = "Could not find this computer, please check the serial number."
            alertTitle = "Computer Record"
            showAlert = true
            return
        }
        
        guard let computerResponse, computerResponse == 200  else {
            alertMessage = "Could not find this computer, please check the serial number."
            alertTitle = "Computer Record"
            showAlert = true
            return
        }

        let redeployResponse = await jamfPro.redeployJamfFramework(jssURL: jamfURL, authToken: authToken.access_token, computerID: computerID)
        
        guard let redeployResponse, redeployResponse == 202  else {
            alertMessage = "Could not queue the redeploy the Jamf Managment Framework."
            alertTitle = "Redeployment"
            showAlert = true
            return
        }

        alertMessage = "Command successfully queued to redeploy the Jamf Managment Framework."
        alertTitle = "Redeployment"
        showAlert = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension String {
    var validURL: Bool {
        get {
//            let regEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
            let regEx = "^((http|https)://)[-a-zA-Z0-9@:%._\\+~#?&//=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%._\\+~#?&//=]*)$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
            return predicate.evaluate(with: self)
        }
    }
}

