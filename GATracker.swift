//
//  AnalyticObject.swift
//  TVSwiftMeasurementProtocol
//
//  Created by Vincent Lee and Luka Cempre on 11/23/15.
//  Copyright © 2015 Analytics Pros. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public class GATracker {
    
    public static let sharedInstance: GATracker = GATracker(tid: "")
    
    /*
        Define properties
        @tid = Google Analytics property id
        @cid = Google Analytics client id
        @appName = Application Name 
        @appVersion = Application Version
        @MPVersion = Measurement Protocol version
        @ua = User Agent string
    */
    var tid : String
    var cid: String
    var appName : String
    var appVersion : String
    var MPVersion : String
    var ua : String
    var ul : String
    
    //Set up singleton object for the tracker
    public class func setup(_ tid: String) -> GATracker {
        GATracker.sharedInstance.tid = tid
        return GATracker.sharedInstance
    }
    
    init(tid: String) {
        /*
            Initialize Tracker with Property Id
            Set up all attributes
        */
        #if DEBUG
            print("Google Analytics Tracker Initialized")
        #endif
        
        self.tid = tid
        self.appName = Bundle.main.infoDictionary!["CFBundleName"] as! String
        let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject?
        self.appVersion = nsObject as! String
        self.ua = "Mozilla/5.0 (Apple TV; CPU iPhone OS 9_0 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13T534YI"
        self.MPVersion = "1"
        let defaults = UserDefaults.standard
        if let cid = defaults.string(forKey: "cid") {
            self.cid = cid
        }
        else {
            self.cid = UUID().uuidString
            defaults.set(self.cid, forKey: "cid")
        }
        
        let language = Locale.preferredLanguages.first
        if language?.characters.count > 0 {
            self.ul = language!
        } else {
            self.ul = "(not set)"
        }
    }
    
    func send(_ type: String, params: Dictionary<String, String>) {
        /*
            Generic hit sender to Measurement Protocol
            Consists out of hit type and a dictionary of other parameters
        */
        let endpoint = "https://www.google-analytics.com/collect?"
        var parameters = "v=" + self.MPVersion + "&an=" + self.appName + "&tid=" + self.tid + "&av=" + self.appVersion + "&cid=" + self.cid + "&t=" + type + "&ua=" + self.ua + "&ul=" + self.ul

        for (key, value) in params {
            parameters += "&" + key + "=" + value
        }
        
        //Encoding all the parameters
        if let paramEndcode = parameters.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed){
            let urlString = endpoint + paramEndcode;
            let url = URL(string: urlString);
            
            #if DEBUG
                print(urlString)
            #endif
            
            let task = URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) -> Void in
                if let httpReponse = response as? HTTPURLResponse {
                    let statusCode = httpReponse.statusCode
                    #if DEBUG
                        print(statusCode)
                    #endif
                }
                else {
                        if (error != nil) {
                            #if DEBUG
                                print(error!.description)
                            #endif
                        }
                }
            }) 
            task.resume()
        }
    }
    
    func screenView(_ screenName: String, customParameters: Dictionary<String, String>?) {
        /*
            A screenview hit, use screenname
        */
        var params = ["cd" : screenName]
        if (customParameters != nil) {
            for (key, value) in customParameters! {
                params.updateValue(value, forKey: key)
            }
        }
        self.send("screenview", params: params)
    }
    
    func event(_ category: String, action: String, label: String?, customParameters: Dictionary<String, String>?) {
        var label = label
        /*
            An event hit with category, action, label
        */
        if label == nil {
            label = ""
        }
       
        //event parameters category, action and label
        var params = ["ec" : category, "ea" : action, "el" : label!]
        if (customParameters != nil) {
            for (key, value) in customParameters! {
                params.updateValue(value, forKey: key)
            }
        }
        self.send("event", params: params)
    }
    
    func exception(_ description: String, isFatal:Bool, customParameters: Dictionary<String, String>?) {
        /*
            An exception hit with exception description (exd) and "fatality"  (Crashed or not) (exf)
        */
        var fatal="0";
        if (isFatal){
            fatal = "1";
        }
        
        var params = ["exd":description, "exf":fatal]
        if (customParameters != nil) {
            for (key, value) in customParameters! {
                params.updateValue(value, forKey: key)
            }
        }
        self.send("exception", params: params)
        
    }
}
