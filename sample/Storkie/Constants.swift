//
//  Constants.swift
//  Storkie
//
//  Created by Mahajan on 24/07/19.
//  Copyright © 2019 Mahajan. All rights reserved.
//

import Foundation
import UIKit
import Firebase


//MARK: LIVE

let COOKIE_BASE_URL = "" //base url with http or https
let HOST_URL = "" //host url
let DOMAIN_URL = "" //.website.com
let TOPIC_NOTIFICATION_KEY =  "prod_user_id_"// "user_id_",
let WEBVIEW_BASE_URL = "" //landing page







let COOKIE_SESSION_KEY = "myScrlCookie"

let COOKIE_APP_KEY = "myScrlAppCookie"

let COOKIE_APP_VALUE_REMEM_ME = "hideRememberMe"

let COOKIE_APP_VALUE_LOGOUT = "logout"

let COOKIE_SESSION_VALUE_USER_ID = "UserID"

let UPLOAD_DOCUMENT = "UploadDocument"
let DOWNLOAD_FILE = "DownloadFile"
let YOU_TUBE = "youtube"
let EMBED = "embed"

//"http://dev.skorkel.com/Landing.aspx",
let USER_AGENT  = "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"

let NO_INTERNET_CONNECTION_TITLE = "No Internet Connection"
let NO_INTERNET_CONNECTION_ALERT = "Please check your internet connection and try again."

let NOTIFICATION_CLIECKED = "NotificationClicked"


class Constants: NSObject {
     static let _singletonInstance = Constants()
    
    class func sharedInstance() -> Constants {
        return _singletonInstance
    }
    
    func saveUserNotificationTopic(userTopic: String) {
        UserDefaults.standard.set(userTopic, forKey: TOPIC_NOTIFICATION_KEY)
        UserDefaults.standard.synchronize()
    }
    func getUserNotificationTopic() -> String {
        if let topic = UserDefaults.standard.value(forKey: TOPIC_NOTIFICATION_KEY) {
            return topic as! String
        } else {
            return ""
        }
    }
    func removeNotificationTopic() {
        UserDefaults.standard.removeObject(forKey: TOPIC_NOTIFICATION_KEY)
        UserDefaults.standard.synchronize()
    }
}


extension UserDefaults {
    
    /// A dictionary of properties representing a cookie.
    typealias CookieProperties = [HTTPCookiePropertyKey: Any]
    
    /// The `UserDefaults` key for accessing cookies.
    private static let cookieKey = "cookies"
    
    /// Saves all cookies currently in the shared `HTTPCookieStorage` to the shared `UserDefaults`.
    func saveCookies() {
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            return
        }
        let cookiePropertiesArray = cookies.compactMap { $0.properties }
        set(cookiePropertiesArray, forKey: UserDefaults.cookieKey)
        synchronize()
    }
    
    /// Loads all cookies stored in the shared `UserDefaults` and adds them to the current shared `HTTPCookieStorage`.
    func loadCoookies() {
        let cookiePropertiesArray = value(forKey: UserDefaults.cookieKey) as? [CookieProperties]
        cookiePropertiesArray?.forEach {
            if let cookie = HTTPCookie(properties: $0) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
      //  self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
    }
    func setRememberMeCookie(key: String, value: AnyObject) {
        let cookieProps: [HTTPCookiePropertyKey : Any] = [
            HTTPCookiePropertyKey.domain: DOMAIN_URL,
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.name: key,
            HTTPCookiePropertyKey.value: value,
            HTTPCookiePropertyKey.secure: "TRUE",
           // HTTPCookiePropertyKey.expires: NSDate(timeIntervalSinceNow: 32333311)
        ]
        
        if let cookie = HTTPCookie(properties: cookieProps) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        
    }
    
    
    
    func setUserPassCookie(){
        guard let cookies = UserDefaults.standard.value(forKey: COOKIE_SESSION_KEY) as? [[HTTPCookiePropertyKey: Any]] else {
            return
        }
        cookies.forEach { (cookie) in
            guard let cookie = HTTPCookie.init(properties: cookie) else {
                return
            }
            
            HTTPCookieStorage.shared.setCookie(cookie)
            HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
            UserDefaults.standard.synchronize()
            
            guard let userId = cookie.value.components(separatedBy: "&").first?.components(separatedBy: "=").last else { return  }
            let topic = TOPIC_NOTIFICATION_KEY + userId
            Constants.sharedInstance().saveUserNotificationTopic(userTopic: topic)
            Messaging.messaging().subscribe(toTopic: topic) { error in
                print("Subscribed to \(topic) topic")
            }

        }
            
            
        
    }
}

extension HTTPCookiePropertyKey {
    static let httpOnly = HTTPCookiePropertyKey("HTTPOnly")
}
