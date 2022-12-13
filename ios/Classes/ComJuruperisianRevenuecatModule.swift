//
//  ComJuruperisianRevenuecatModule.swift
//  com.juruperisian.revenuecat
//
//  Created by Your Name
//  Copyright (c) 2022 Your Company. All rights reserved.
//

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

func dateToStr(_ date: Date?) -> String? {
    guard let date = date else {return nil}
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"  // Set the desired date format

    return dateFormatter.string(from: date)
}

func customerInfoToDict(_ customerInfo: CustomerInfo) -> [String:Any?] {
    var dict = [String:Any?]()
    
    dict["description"] = customerInfo.description
    dict["originalAppUserId"] = customerInfo.originalAppUserId
    dict["originalApplicationVersion"] = customerInfo.originalApplicationVersion
    dict["firstSeen"] = dateToStr(customerInfo.firstSeen)
    dict["latestExpirationDate"] = dateToStr(customerInfo.latestExpirationDate)
    dict["originalApplicationVersion"] = customerInfo.originalApplicationVersion
    dict["originalPurchaseDate"] = dateToStr(customerInfo.originalPurchaseDate)
    dict["originalApplicationVersion"] = customerInfo.originalApplicationVersion
    dict["activeSubscriptions"] = Array(customerInfo.activeSubscriptions)
    dict["allPurchasedProductIdentifiers"] = Array(customerInfo.allPurchasedProductIdentifiers)
    
    return dict
}

@objc(ComJuruperisianRevenuecatModule)
class ComJuruperisianRevenuecatModule: TiModule, PurchasesDelegate {
    private var purchasesDelegate: KrollCallback?
    public let testProperty: String = "Hello World"
    
    /// -  Whenever the `shared` instance of Purchases updates the PurchaserInfo cache, this method will be called.
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        NSLog("delegate - purchases: \(purchases)")
        
        
        let customerInfoDict = customerInfoToDict(customerInfo)
        NSLog("delegate - custInfo: \(customerInfoDict)")
        
        purchasesDelegate?.call([customerInfoDict], thisObject: nil)
    }
    
//    @objc(setPurchasesDelegate:)
//    func setPurchasesDelegate(arguments: [Any]?) -> Void {
//        NSLog("0")
//        guard let args = arguments,
//              let callback = args[0] as? KrollCallback
//        else {
//            NSLog("setPurchasesDelegate: - Invalid parameters provided!")
//            return
//        }
//
//        NSLog("1")
//        self.purchasesDelegate = callback
//        NSLog("2")
//    }
   
    @objc(configure:)
    func configure(arguments: [Any]?) -> Void {
        guard let arguments = arguments, let params = arguments[0] as? [String: Any] else {return}
        let apiKey = params["apiKey"] as? String ?? ""
        
        Purchases.logLevel = .debug
        
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                  .with(usesStoreKit2IfAvailable: true)
                  .build()
        )
    }
    
    @objc(login:)
    func login(args: [Any]?) -> Void {
        guard
            let args = args, let appUserId = args[0] as? String
        else {
            fatalError("login: - UserId is required")
        }
        
        Purchases.shared.logIn(appUserId) { customerInfo, isNewUser, error in
            if args.count > 1, let callback = args[1] as? KrollCallback {
                callback.call([[
                    "success": error == nil,
                    "isNewUser": isNewUser,
                    "error": error?.localizedDescription ?? ""
                ]], thisObject: nil)
            }
        }
    }
    
    @objc(isSubscribed:)
    func isSubscribed(arguments: [Any]) -> Void {
        // Unwrap the first element of the array using the `guard` keyword
        if case let callback as KrollCallback = arguments.first {
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
                if let packages = offerings?.current?.availablePackages {
                    // Display packages for sale
                    NSLog("packages: \(packages)")

                    let dictionaryArray = packages.map { package -> [String: Any] in
                        let localizedPriceString = package.localizedPriceString
                        let offeringIdentifier = package.offeringIdentifier
                        let storeProduct = package.storeProduct
                        
                        return [
                            "id": package.id,
                            "identifier": package.identifier,
                            "localizedPriceString": localizedPriceString,
                            "offeringIdentifier": offeringIdentifier,
                            "localizedDescription": storeProduct.localizedDescription,
                            "localizedTitle": storeProduct.localizedTitle,
                            "productIdentifier": storeProduct.productIdentifier
                        ]
                    }
                    
                    callback.call([dictionaryArray], thisObject: nil)
                }
            }
        }
    }
    
    @objc(purchase:)
    func purchase(arguments: [Any]?) -> Void {
        guard let args = arguments,
              let productId = args[0] as? String
        else {
            NSLog("purchase: - Invalid parameters provided!")
            return
        }
        
        let callback = args[1] as? KrollCallback
        
        // Find package by id
        Purchases.shared.getOfferings { offerings, error in
            var success = false
            var errorMsg = ""
            
            if let error = error {
                // Handle the error
                errorMsg = error.localizedDescription
                NSLog(errorMsg)
                
                // Call JS callback if any - getOfferings:
                callback?.call([[
                    "success": success,
                    "error": errorMsg
                ]], thisObject: nil)
            } else if let offerings = offerings, let packages = offerings.current?.availablePackages {
                // Display packages for sale
                NSLog("packages: \(packages)")

                if let package = packages.first(where: { $0.storeProduct.productIdentifier == productId }) {
                    // Use package here
                    Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
                        var success = false
                        var errorMsg = ""
                        
                        if userCancelled {
                            errorMsg = error?.localizedDescription ?? ""
                            NSLog("User Cancelled")
                        } else if let error = error {
                            errorMsg = error.localizedDescription
                            NSLog(errorMsg)
                        } else if let customerInfo = customerInfo {
                            success = true
                            
                            NSLog("customerInfo: \(customerInfo)")
                            NSLog("transaction: \(String(describing: transaction))")
                        }
                        
                        // Call JS callback if any - purchase:
                        callback?.call([[
                            "success": success,
                            "error": errorMsg
                        ]], thisObject: nil)
                    }
                } else {
                    errorMsg = "Cannot find product with id: \(productId)"
                    // Handle the case where package is nil
                    NSLog(errorMsg)
                    
                    // Call JS callback if any - no product id:
                    callback?.call([[
                        "success": success,
                        "error": errorMsg
                    ]], thisObject: nil)
                }
            } else {
                // Call JS callback if any - purchase:
                callback?.call([[
                    "success": false,
                    "error": "Cannot find any available packages in the current offering"
                ]], thisObject: nil)
            }
        }
    }
    
    @objc(restorePurchases:)
    func restorePurchases(args: [Any]?) -> Void {
        Purchases.shared.restorePurchases { customerInfo, error in
            //... check customerInfo to see if entitlement is now active
            var success = false
            var errorMsg = ""
            
            if let error = error {
                errorMsg = error.localizedDescription
                NSLog(errorMsg)
            } else if let customerInfo = customerInfo {
                success = true
                NSLog("restorePurchases - customerInfo: \(customerInfo)")
            }
            
            if let args = args, let callback = args[0] as? KrollCallback {
                callback.call([[
                    "success": success,
                    "error": errorMsg
                ]], thisObject: nil)
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
