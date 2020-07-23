//
//  NoNetworkManager.swift
//  Shiprocket
//
//  Created by Manoj Gupta on 17/01/19.
//  Copyright © 2019 Shiprocket. All rights reserved.
//

import UIKit

class NoNetworkManager: NSObject {

   var takeoverViewController : OfflineViewController!
    private static var sharedNetworkManager: NoNetworkManager = {
        let networkManager = NoNetworkManager()
        
        // Configuration
        // ...
        
        return networkManager
    }()
    
    // MARK: - Accessors
    
    class func networkShared() -> NoNetworkManager {
        return sharedNetworkManager
    }
    
   
    
    func enableLackOfNetworkTakeover() -> Void {
        NetworkManager.isUnreachable { _ in
            self.showOfflinePage()
        }
        
        NetworkManager.isReachable { _ in
            
        }
        
        
        NetworkManager.sharedInstance.reachability.whenUnreachable = { reachability in
         
            self.showOfflinePage()
        }
        
        NetworkManager.sharedInstance.reachability.whenReachable = { reachability in
            let topMostViewController = UIApplication.shared.topMostViewController()
            if topMostViewController?.presentedViewController != nil  {
                self.takeoverViewController.dismiss(animated: true, completion: {
                    let topMostViewController = UIApplication.shared.topMostViewController() as! UINavigationController
                    let homeVC = topMostViewController.viewControllers.first as! HomeViewController
                    homeVC.reloadWebView()
                })
            }
            

        }

    }
    
    func showOfflinePage() -> Void {
//        let topMostViewController = UIApplication.shared.topMostViewController() as! UINavigationController
//        let homeVC = topMostViewController.viewControllers.first as! HomeViewController
//        homeVC.showInternetError()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.takeoverViewController = storyboard.instantiateViewController(withIdentifier: "OfflineViewController") as? OfflineViewController
        self.takeoverViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.takeoverViewController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        let topMostViewController = UIApplication.shared.topMostViewController()
        topMostViewController?.present(self.takeoverViewController, animated: true, completion: {
            
        })
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController
        //return (self.keyWindow?.rootViewController as? UITabBarController)?.selectedViewController
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}
