//
//  ComJuruperisianRevenuecatModule.swift
//  com.juruperisian.revenuecat
//
//  Created by Your Name
//  Copyright (c) 2022 Your Company. All rights reserved.
//

import UIKit
import TitaniumKit
import RevenueCat

/**
 
 Titanium Swift Module Requirements
 ---
 
 1. Use the @objc annotation to expose your class to Objective-C (used by the Titanium core)
 2. Use the @objc annotation to expose your method to Objective-C as well.
 3. Method arguments always have the "[Any]" type, specifying a various number of arguments.
 Unwrap them like you would do in Swift, e.g. "guard let arguments = arguments, let message = arguments.first"
 4. You can use any public Titanium API like before, e.g. TiUtils. Remember the type safety of Swift, like Int vs Int32
 and NSString vs. String.
 
 */

@objc(ComJuruperisianRevenuecatModule)
class ComJuruperisianRevenuecatModule: TiModule {

  public let testProperty: String = "Hello World"
    
    @objc(configure:)
    func configure(arguments: [Any]?) -> Void {
        NSLog("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
        print("in configure")
        guard let arguments = arguments, let params = arguments[0] as? [String: Any] else {return}
        let apiKey = params["apiKey"] as? String ?? ""
        let userId = params["userId"] as? String ?? ""
        
        Purchases.logLevel = .debug
        
        Purchases.configure(
         with: Configuration.Builder(withAPIKey: apiKey)
                  .with(appUserID: userId)
                  .build()
         )
    }
    
    @objc(isSubscribed:)
    func isSubscribed(arguments: [Any]) -> Void {
        // Unwrap the first element of the array using the `guard` keyword
        if case let callback as KrollCallback = arguments.first {
            NSLog("1 \(callback)")
           
            // If the first element is a (Bool) -> Void function, call it with a true value
            Purchases.shared.getCustomerInfo { (customerInfo, error) in
                NSLog("customerInfo:  error: ")
                // access latest customerInfo
                guard let isEmpty = (customerInfo?.entitlements.active.isEmpty) else {return}
                
                if !isEmpty {
                    //user has access to some entitlement
                    NSLog("isSubscribed")
                    callback.call([true], thisObject: nil)
                } else {
                    NSLog("not subscribed")
                    callback.call([false], thisObject: nil)
                }
            }
        }
    }
        
    @objc(getCurrentOfferings:)
    func getCurrentOfferings(arguments: [Any]) -> Void {
        NSLog("in getCurrentOfferings")
        if case let callback as KrollCallback = arguments.first {
            NSLog("callback: \(String(describing: callback))")
            Purchases.shared.getOfferings { (offerings, error) in
                NSLog("offerings: \(String(describing: offerings)) - error: \(String(describing: error))")
                if let packages = offerings?.current?.availablePackages {
                    // Display packages for sale
                    NSLog("packages: \(packages)")
//                    let packages: [RCPackage] = // An array of RCPackage objects

                    let dictionaryArray = packages.map { package -> [String: String] in
                        let localizedPriceString = package.localizedPriceString
                        let offeringIdentifier = package.offeringIdentifier
                        let storeProduct = package.storeProduct
                        
                        return [
                            "localizedPriceString": localizedPriceString,
                            "offeringIdentifier": offeringIdentifier,
                            "localizedDescription": storeProduct.localizedDescription,
                            "localizedTitle": storeProduct.localizedTitle,
                            "productIdentifier": storeProduct.productIdentifier
                        ]
                    }

                    callback.call(dictionaryArray, thisObject: nil)
                }
            }
        }
    }
    
    
  func moduleGUID() -> String {
    return "81646e76-5a05-49e2-ba13-420b4324ed7f"
  }
  
  override func moduleId() -> String! {
    return "com.juruperisian.revenuecat"
  }

  override func startup() {
    super.startup()
    debugPrint("[DEBUG] \(self) loaded")
  }

  @objc(example:)
  func example(arguments: Array<Any>?) -> String? {
    guard let arguments = arguments, let params = arguments[0] as? [String: Any] else { return nil }

    // Example method. 
    // Call with "MyModule.example({ hello: 'world' })"

    return params["hello"] as? String
  }
  
  @objc public var exampleProp: String {
     get { 
        // Example property getter
        return "Titanium rocks!"
     }
     set {
        // Example property setter
        // Call with "MyModule.exampleProp = 'newValue'"
        self.replaceValue(newValue, forKey: "exampleProp", notification: false)
     }
   }
}
