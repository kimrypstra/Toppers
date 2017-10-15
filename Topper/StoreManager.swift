//
//  StoreManager.swift
//  Topper
//
//  Created by Kim Rypstra on 29/8/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit
import StoreKit

class StoreManager: NSObject {
    
    private var storeID: String!
    
    func confirmPlaybackCapability(completion: @escaping (Bool) -> ()) {
        print("Confirming playback capability...")
        let queue = DispatchQueue(label: "com.KimRypstra.Topper.Capability", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: .main)
        let group = DispatchGroup()
        var returnValue = false
        
        print("Pre-check...")
        
        if checkDefaultSettings() == true {
            print("Ready to go")
            completion(true)
            return
        } else {
            print("Not pre-authorized; proceeding with checks")
    
            print("Step 1: Checking authorisation...")
            group.enter()
            checkAuthorization(completion: { (authorised) in
                if authorised == false {
                    completion(false)
                    group.leave()
                } else {
                    group.leave()
                }
            })
            
            group.notify(queue: DispatchQueue.main, execute: {
                let secondGroup = DispatchGroup()
                
                print("Step 2: Checking compatibility...")
                secondGroup.enter()
                self.checkCapability { (success) in
                    if success {
                        returnValue = true
                    }
                    secondGroup.leave()
                }
                
                print("Step 3: Getting storefront ID...")
                secondGroup.enter()
                self.getStorefrontID { (identifier, error) in
                    guard error == nil else {
                        print("Error: \(error)")
                        secondGroup.leave()
                        return
                    }
                    
                    if identifier != nil {
                        self.storeID = identifier
                        print("StorefrontID: \(self.storeID!)")
                        secondGroup.leave()
                    } else {
                        print("Problem getting store ID")
                        secondGroup.leave()
                    }
                    
                }
                
                secondGroup.notify(queue: DispatchQueue.main) {
                    completion(returnValue)
                }
            })
            
            
        }
    }
    
    private func checkDefaultSettings() -> Bool {
        let defaults = UserDefaults()
        if let settings = defaults.value(forKey: "settings") as? [String: Any] {
            guard let preAuthorised = settings["preAuthorised"] as? Bool else {
                print("preAuthorised key not found")
                return false
            }
//            guard let deviceChecked = settings["deviceChecked"] as? Bool else {
//                print("deviceChecked key not found")
//                return false
//            }
            guard let appleMusicReady = settings["appleMusic"] as? Bool else {
                print("appleMusic key not found")
                return false
            }
            
            guard let storefrontID = settings["storefrontID"] as? String else {
                print("storefrontID key not found")
                return false
            }
            self.storeID = storefrontID
            
            if preAuthorised /*&& deviceChecked*/ && appleMusicReady && storeID != nil {
                return true
            } else {
                return false
            }
        } else {
            print("settings key not found")
            return false
        }
    }
    
    private func getStorefrontID(completion: @escaping (String?, Error?) -> ()) {
        let serviceController = SKCloudServiceController()
        serviceController.requestStorefrontIdentifier { (identifier, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let identifier = identifier else {
                completion(nil, nil)
                return
            }
            let sep = Character.init(",")
            let idString = identifier.split(separator: sep).first
            if var settings = UserDefaults().value(forKey: "settings") as? [String: Any] {
                settings["storefrontID"] = String(describing: idString!)
                UserDefaults().set(settings, forKey: "settings")
            } else {
                let settings: [String: Any] = ["storefrontID" : String(describing: idString!)]
                UserDefaults().set(settings, forKey: "settings")
            }
            completion(String(describing: idString!), nil)
        }
    }
    
    func storefrontID() -> String? {
        if self.storeID != nil {
            return self.storeID!
        } else {
            print("Store ID is nil")
            return nil
        }
        
    }
    
    private func checkCapability(completion: @escaping (Bool) -> ()) {
        print("Checking capability...")
        var returnValue = false
        let serviceController = SKCloudServiceController()
        
        serviceController.requestCapabilities { (capability, error) in
            if error == nil {
                if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                    print("Playback capable")
                    returnValue = true
                    if var settings = UserDefaults().value(forKey: "settings") as? [String: Any] {
                        settings["appleMusic"] = true
                        UserDefaults().set(settings, forKey: "settings")
                    } else {
                        let settings: [String: Any] = ["appleMusic" : true]
                        UserDefaults().set(settings, forKey: "settings")
                    }
                } else if capability.contains(SKCloudServiceCapability.addToCloudMusicLibrary) {
                    print("Add to cloud music library capable")
                } else if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                    print("Subscription eligible - maybe affiliate program is a good idea?")
                } else {
                    print("Not capable")
                }
            } else {
                print("Error: \(error!.localizedDescription)")
            }
            completion(returnValue)
        }
    }
    
    private func checkAuthorization(completion: @escaping (Bool) -> ())  {
        print("Checking authorization...")
        switch SKCloudServiceController.authorizationStatus() {
        case .authorized:
            print("Authorized")
            if var settings = UserDefaults().value(forKey: "settings") as? [String: Any] {
                settings["preAuthorised"] = true
                UserDefaults().set(settings, forKey: "settings")
            } else {
                let settings: [String: Any] = ["preAuthorised" : true]
                UserDefaults().set(settings, forKey: "settings")
            }
            completion(true)
        case .denied:
            print("Denied - show an alert telling the user to change settings")
            completion(false)
        case .notDetermined:
            print("Not determined...")
            requestAuthorization(completion: { (success) in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            })
        case .restricted:
            print("Restriced")
            completion(false)
        }
    }
    
    private func requestAuthorization(completion: @escaping (Bool) -> ()) {
        print("Requesting authorization...")
        SKCloudServiceController.requestAuthorization { (authorisationStatus) in
            switch authorisationStatus {
            case .authorized:
                print("Authorised")
                completion(true)
            case .denied:
                print("Denied")
                completion(false)
            case .notDetermined:
                print("Request for authorization returned notDetermined...")
                completion(false)
            case .restricted:
                print("Restricted")
                completion(false)
            }
        }
    }
}
