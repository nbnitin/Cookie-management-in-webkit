//
//  HomeViewController.swift
//  Storkie
//
//  Created by Mahajan on 26/07/19.
//  Copyright © 2019 Mahajan. All rights reserved.
//

import UIKit
import WebKit
import WKCookieWebView
import Firebase
import Reachability
import SafariServices

class HomeViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var splashView: UIView!
    var isResetPasswordSet = false
    var isLogout: Bool = false
    var isWrongCredentials = false
    
    lazy var webView: WKCookieWebView = {
        let webView: WKCookieWebView = WKCookieWebView(frame: self.containerView.bounds)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.clipsToBounds = true
        webView.backgroundColor = UIColor.clear
        webView.wkNavigationDelegate = self
        webView.uiDelegate = self
        return webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //if NetworkManager.isConnectedToNetwork() {
            loadWebView(isNeedPreloadForCookieSync: true)
//        } else {
//            showAlert(title: NO_INTERNET_CONNECTION_TITLE, message: NO_INTERNET_CONNECTION_ALERT)
//        }
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWebView), name: NSNotification.Name(rawValue: NOTIFICATION_CLIECKED), object: nil)
        
    }
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(true)
         NoNetworkManager.networkShared().enableLackOfNetworkTakeover()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
//        if AppDelegate.shared.isOpenFromNotification {
//            loadWebView(isNeedPreloadForCookieSync: false)
//        }
//         if !NetworkManager.isConnectedToNetwork() {
//            showAlert(title: NO_INTERNET_CONNECTION_TITLE, message: NO_INTERNET_CONNECTION_ALERT)
//        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        let historySize = webView.backForwardList.backList.count
        if historySize > 2 {
            let firstItem = webView.backForwardList.item(at: -2)
            
            // go to it!
            webView.go(to: firstItem!)
        } else {
            let firstItem = webView.backForwardList.item(at: -1)
            
            // go to it!
            webView.go(to: firstItem!)
        }
        
    }
    @objc func reloadWebView() {
        loadWebView(isNeedPreloadForCookieSync: true)
    }
    private func loadWebView(isNeedPreloadForCookieSync: Bool) {
      //  let isNeedPreloadForCookieSync = true
        self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
        self.loadCookie()
        if isNeedPreloadForCookieSync {
            // After running the app, before the first webview was loaded,
            // Cookies may not be set properly,
            // In that case, use the loader in advance to synchronize.
            // You can use the webview.
            let url = AppDelegate.shared.isOpenFromNotification ? AppDelegate.shared.notificationUrl : WEBVIEW_BASE_URL
            
            WKCookieWebView.preloadWithDomainForCookieSync(urlString: url) { [weak self] in
                self?.setupWebView()
                var request = URLRequest(url: URL(string: url)!)
                request.setValue(USER_AGENT, forHTTPHeaderField: "User-Agent")
                self?.webView.load(request)
            }
        } else {
            self.setupWebView()
              let url = AppDelegate.shared.isOpenFromNotification ? AppDelegate.shared.notificationUrl : WEBVIEW_BASE_URL
            var request = URLRequest(url: URL(string: url)!)
            request.setValue(USER_AGENT, forHTTPHeaderField: "User-Agent")
            self.webView.load(request)
        }
    }
  

    // MARK: - Private
    private func setupWebView() {
        containerView.addSubview(webView)
        
        let views: [String: Any] = ["webView": webView]

        view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[webView]-0-|",
            options: [],
            metrics: nil,
            views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-0-[webView]-0-|",
            options: [],
            metrics: nil,
            views: views))
        
        webView.onDecidePolicyForNavigationAction = { (webView, navigationAction, decisionHandler) in
            //self.loadCookie()

            self.isLogout = false
            AppDelegate.shared.isOpenFromNotification = false
            AppDelegate.shared.notificationUrl = ""
            
            if let host = navigationAction.request.url?.host {
                if host ==  HOST_URL {
                    self.navigationController?.setNavigationBarHidden(true, animated: false)
                    if let link = navigationAction.request.url?.absoluteString {
                        if (link.contains(UPLOAD_DOCUMENT) || link.contains(DOWNLOAD_FILE)) {
                            if (UIApplication.shared.canOpenURL(navigationAction.request.url!)) {
//                                UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
                                self.openLink(url: navigationAction.request.url!)
                                decisionHandler(.cancel)
                                return
                            }
                        }

                    }
                       self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
                    decisionHandler(.allow)
                    return
                } else if (UIApplication.shared.canOpenURL(navigationAction.request.url!)) {
//                    UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
                    if ( navigationAction.request.url!.absoluteString.contains(YOU_TUBE) && navigationAction.request.url!.absoluteString.contains(EMBED) ) {
                        decisionHandler(.allow)
                        return
                    }
                    self.openLink(url: navigationAction.request.url!)
                    decisionHandler(.cancel)
                    return
                }
            } else if (UIApplication.shared.canOpenURL(navigationAction.request.url!)) {
//                UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
                if ( navigationAction.request.url!.absoluteString.contains(YOU_TUBE) && navigationAction.request.url!.absoluteString.contains(EMBED) ) {
                    decisionHandler(.allow)
                    return
                }
                self.openLink(url: navigationAction.request.url!)
                decisionHandler(.cancel)
                return
            }
            
           decisionHandler(.cancel)
        }
                webView.onDecidePolicyForNavigationResponse = { (webView, navigationResponse, decisionHandler) in
                    
                   
                    
            
            if let host = navigationResponse.response.url?.host {
                if host ==  HOST_URL {
                    self.navigationController?.setNavigationBarHidden(true, animated: false)
                    if let link = navigationResponse.response.url?.absoluteString {
                        if (link.contains(UPLOAD_DOCUMENT) || link.contains(DOWNLOAD_FILE)) {
                            if (UIApplication.shared.canOpenURL(navigationResponse.response.url!)) {
//                                UIApplication.shared.open(navigationResponse.response.url!, options: [:], completionHandler: nil)
                                self.openLink(url: navigationResponse.response.url!)
                                decisionHandler(.cancel)
                                return
                            }
                        }
                        else if link.contains("Research-Case-Details") {
                          //  self.navigationController?.setNavigationBarHidden(false, animated: false)
                        } else if ( link.contains("Landing") /*|| link.contains("Reset-Password.aspx#")*/ )  {
                           // self.deleteCookies()
                            self.getAllCookie(completionHandler: {(cookies) in
                                for cookie in cookies {
                                    
                                    if cookie.name == COOKIE_APP_KEY  && cookie.value == COOKIE_APP_VALUE_LOGOUT {
                                        self.isLogout = true
                                        self.deleteCookies()
                                        //self.isLogout = true
                                        return
                                    }
                                }
                            })
                            decisionHandler(.allow)
                            return
                        } else if(link.contains("Reset-Password")){
                            
                            self.storeCookie(param: "navigation")
                            
                        } else{
                            self.isResetPasswordSet = false
                        }
                    }
                
                    self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
                    decisionHandler(.allow)
                    return
                } else if (UIApplication.shared.canOpenURL(navigationResponse.response.url!)) {
//                    UIApplication.shared.open(navigationResponse.response.url!, options: [:], completionHandler: nil)
                    
                    if (navigationResponse.response.url!.absoluteString.contains(YOU_TUBE) && navigationResponse.response.url!.absoluteString.contains(EMBED)) {
                        decisionHandler(.allow)
                        return
                    }
                    
                    self.openLink(url: navigationResponse.response.url!)
                    decisionHandler(.cancel)
                    return
                }
            } else if (UIApplication.shared.canOpenURL(navigationResponse.response.url!)) {
//                UIApplication.shared.open(navigationResponse.response.url!, options: [:], completionHandler: nil)
                if (navigationResponse.response.url!.absoluteString.contains(YOU_TUBE) && navigationResponse.response.url!.absoluteString.contains(EMBED)) {
                    decisionHandler(.allow)
                    return
                }
                self.openLink(url: navigationResponse.response.url!)
                decisionHandler(.cancel)
                return
            }
          self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
            decisionHandler(.allow)
        }
                webView.onUpdateCookieStorage = { [weak self] (webView) in
            if let url = webView.url?.absoluteString {
                if (url.contains("Home") ){
                    self?.logOut()
                    return
                } else if (url.contains("Landing")) {
                    //self?.isLogout = true
                    //self?.deleteCookies()
                    
                    return
                }
                self?.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
                let cookies = HTTPCookieStorage.shared.cookies ?? []
                for cookie in cookies {
                    if cookie.name == COOKIE_APP_KEY  && cookie.value == COOKIE_APP_VALUE_LOGOUT {
                        self?.isLogout = true
                        self?.deleteCookies()
                        return
                }
                }
            }
           
        }
    }
    
    // MARK: OPen External Link:
    func openLink(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        //old code
//        let svc = SFSafariViewController(url: URL(string:"mailto:contact@skorkel.com")!)
//        present(svc, animated: true, completion: nil)
    }
    //MARK:- SHOW ALERT -
    func showInternetError() {
         showAlert(title: NO_INTERNET_CONNECTION_TITLE, message: NO_INTERNET_CONNECTION_ALERT)
    }
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Reload", style: .default, handler: {[weak self] (action) in
            self?.loadWebView(isNeedPreloadForCookieSync: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Reload", style: UIAlertAction.Style.default, handler: {[weak self] (action) in
//            self?.loadWebView(isNeedPreloadForCookieSync: true)
//        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    //MARK:- SETUP COOKIE -
    func setRememberMeCookie(key: String, value: AnyObject) {
        let cookieProps: [HTTPCookiePropertyKey : Any] = [
            HTTPCookiePropertyKey.domain: DOMAIN_URL,
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.name: key,
            HTTPCookiePropertyKey.value: value,
            HTTPCookiePropertyKey.secure: "TRUE",
            HTTPCookiePropertyKey.expires: NSDate(timeIntervalSinceNow: 32333311)
        ]
        
        if let cookie = HTTPCookie(properties: cookieProps) {
            HTTPCookieStorage.shared.setCookie(cookie)
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            let value = "document.cookie='\(cookie.name)=\(cookie.value);domain=\(cookie.domain);path=\(cookie.path);secure;';"
             webView.configuration.userContentController.addUserScript(WKUserScript(source: value,
                                                             injectionTime: .atDocumentStart,
                                                             forMainFrameOnly: false))
        }
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        
    }
    //MARK:- DELETE COOKIES
    func deleteCookies() {
        
        let dataStore = WKWebsiteDataStore.default()
        if let _ = UserDefaults.standard.value(forKey: COOKIE_SESSION_KEY) {
            UserDefaults.standard.removeObject(forKey: COOKIE_SESSION_KEY)
        }
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
            for record in records {
                if record.displayName.contains("skorkel.com") {
        
                    dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {
                        print("[WebCacheCleaner] Record \(record) deleted")
                    })
               }
            }
            UserDefaults.standard.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
            self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)

        }
       
        let cookieJar = HTTPCookieStorage.shared
        
        for cookie in cookieJar.cookies! {
        
            cookieJar.deleteCookie(cookie)
            if #available(iOS 11.0, *) {
                webView.configuration.websiteDataStore.httpCookieStore.delete(cookie, completionHandler: nil)
            }
        }
         UserDefaults.standard.synchronize()
        if Constants.sharedInstance().getUserNotificationTopic() != "" {
            
            
            Messaging.messaging().unsubscribe(fromTopic: Constants.sharedInstance().getUserNotificationTopic(), completion: { (error) in
                print("UnSubscribed to \(Constants.sharedInstance().getUserNotificationTopic()) topic")
                Constants.sharedInstance().removeNotificationTopic()
            })
           

        }
        
        self.webView.configuration.userContentController = WKUserContentController()
        self.webView.configuration.processPool = WKProcessPool()
        self.webView.configuration.userContentController.removeAllUserScripts()
      
        var libraryPath : String = FileManager().urls(for: .libraryDirectory, in: .userDomainMask).first!.path
        libraryPath += "/Cookies"
        do {
            try FileManager.default.removeItem(atPath: libraryPath)
        } catch {
            print("error")
        }
       
         URLCache.shared.removeAllCachedResponses()
        
        
       // self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
        
        if isLogout == true {
            self.loadWebView(isNeedPreloadForCookieSync: true)
        }
        self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
       
    }
    
    func getAllCookie(completionHandler:@escaping ([HTTPCookie])->()){
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies({
            (cookies) in
            
            completionHandler(cookies)
        })
    }
    
    func logOut(){
        getAllCookie(completionHandler: {(cookies) in
            for cookie in cookies {
                
                if cookie.name == COOKIE_APP_KEY  && cookie.value == COOKIE_APP_VALUE_LOGOUT {
                    self.isLogout = true
                    self.deleteCookies()
                    return
                } else if cookie.name == COOKIE_SESSION_KEY {
                    guard let userId = cookie.value.components(separatedBy: "&").first?.components(separatedBy: "=").last else { return  }
                    let topic = TOPIC_NOTIFICATION_KEY + userId
                    Constants.sharedInstance().saveUserNotificationTopic(userTopic: topic)
                    Messaging.messaging().subscribe(toTopic: topic) { error in
                        print("Subscribed to \(topic) topic")
                    }
                }
            }
        })
    }
    
    //MARK:- STORE COOKIES
    func storeCookie(param:String) {
//        print("=====================WEBVIEW URL=====================")
//        print(webView.url?.absoluteString ?? "")
//        print("==========================================")
//        print("=====================Cookies=====================")
//        HTTPCookieStorage.shared.cookies?.forEach {
//            print($0)
//
//        }
//        print("=================================================")
        
       print("i m here" + param)
        
        getAllCookie(completionHandler: {(cookies) in
            print("go that")
            
                for cookie in cookies {
                if ( cookie.name == COOKIE_SESSION_KEY  ) {
                    self.setRememberMeCookie(key: COOKIE_SESSION_KEY, value: cookie as AnyObject)
                    self.setSessionCookieInUserDefault(cookie: [cookie])
                    guard let userId = cookie.value.components(separatedBy: "&").first?.components(separatedBy: "=").last else { return  }
                                    let topic = TOPIC_NOTIFICATION_KEY + userId
                                   Constants.sharedInstance().saveUserNotificationTopic(userTopic: topic)
                                    Messaging.messaging().subscribe(toTopic: topic) { error in
                                        print("Subscribed to \(topic) topic")
                              }
                    //completionHandler(true)
                    //break
                }
            }
        })
        
        
        URLCache.shared.removeAllCachedResponses()
        UserDefaults.standard.synchronize()
        
     // let cookies = HTTPCookieStorage.shared.cookies ?? []
//        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
//            for cookie in cookies {
//
//                print(cookie)
//
//
//        //for cookie in cookies {
//            if cookie.name == COOKIE_APP_KEY  && cookie.value == COOKIE_APP_VALUE_LOGOUT {
//                self.isLogout = true
//                self.deleteCookies()
//                //return
//            }
//                if cookie.name == COOKIE_SESSION_KEY {
//
//                    self.setRememberMeCookie(key: COOKIE_SESSION_KEY, value: cookie as AnyObject)
//
//
//                //self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
//
////                let value = "document.cookie='\(cookie.name)=\(cookie.value);domain=\(cookie.domain);path=\(cookie.path);secure;';"
////                self.webView.configuration.userContentController.addUserScript(WKUserScript(source: value,
////                                                                                       injectionTime: .atDocumentStart,
////                                                                                       forMainFrameOnly: false))
//                self.setSessionCookieInUserDefault(cookie: [cookie] )
//
//                guard let userId = cookie.value.components(separatedBy: "&").first?.components(separatedBy: "=").last else { return  }
//                let topic = TOPIC_NOTIFICATION_KEY + userId
//               Constants.sharedInstance().saveUserNotificationTopic(userTopic: topic)
//                Messaging.messaging().subscribe(toTopic: topic) { error in
//                    print("Subscribed to \(topic) topic")
//          }
//        }
//            }
 //   }
    }
    
    func setSessionCookieInUserDefault(cookie : [HTTPCookie]){
        
        
        guard  let temp = cookie as? [HTTPCookie]  else {
            return
        }
        let array = temp.compactMap { (cookie) -> [HTTPCookiePropertyKey: Any]? in
            cookie.properties
        }
        UserDefaults.standard.set(array, forKey: COOKIE_SESSION_KEY)
        UserDefaults.standard.synchronize()
        loadCookie()
    }
    
    func loadCookie(){
        guard let cookies = UserDefaults.standard.value(forKey: COOKIE_SESSION_KEY) as? [[HTTPCookiePropertyKey: Any]] else {
            return
        }
        cookies.forEach { (cookie) in
            guard let cookie = HTTPCookie.init(properties: cookie) else {
                return
            }
            
                HTTPCookieStorage.shared.setCookie(cookie)
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                let value = "document.cookie='\(cookie.name)=\(cookie.value);domain=\(cookie.domain);path=\(cookie.path);secure;';"
                webView.configuration.userContentController.addUserScript(WKUserScript(source: value,
                                                                                       injectionTime: .atDocumentStart,
                                                                                       forMainFrameOnly: false))
           // }
            HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
            self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            UserDefaults.standard.synchronize()

        }
    }
    
}

extension HomeViewController: WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
  
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
       URLCache.shared.removeAllCachedResponses()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // print("Start Provisioning")
        self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finish Webview load")
        
        self.splashView.isHidden = true
       
        if let link = webView.url?.absoluteString {
            if link.contains("Research-Case-Details") {
               // self.navigationController?.setNavigationBarHidden(false, animated: false)
            } else if ( link.contains("Landing") || link.contains("Reset-Password") || link.contains("Home"))  {
                if link.contains("Landing") {
//                    self.isLogout = true
//                    self.deleteCookies()
                } else {
                    URLCache.shared.removeAllCachedResponses()
                    //self.storeCookie()
                }
               
            
            } //else {
//               // URLCache.shared.removeAllCachedResponses()
//                let finalLink = link.dropLast()
//                if (finalLink == COOKIE_BASE_URL && self.isWrongCredentials == false) {
//                    let dataStore = WKWebsiteDataStore.default()
//                    dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
//                        for record in records {
//                            if record.displayName.contains("skorkel.com") {
//
//                                dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {
//                                    print("[WebCacheCleaner] Record \(record) deleted")
//                                })
//                            }
//                        }
//                        UserDefaults.standard.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
//                        self.setRememberMeCookie(key: COOKIE_APP_KEY, value: COOKIE_APP_VALUE_REMEM_ME as AnyObject)
//                        self.isWrongCredentials = true
//                        self.webView.reload()
//                }
//
//
//                }
//            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        //print("didFail.error : \(error)")
       //  showAlert(title: "Error", message: error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        //print("didFailProvisionalNavigation.error : \(error)")
      //  showAlert(title: "Error", message: error.localizedDescription)
    }
    
}
