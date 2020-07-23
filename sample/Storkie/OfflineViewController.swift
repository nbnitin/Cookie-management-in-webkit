//
//  OfflineViewController.swift
//  reachability-playground
//
//  Created by Neo Ighodaro on 28/10/2017.
//  Copyright © 2017 CreativityKills Co. All rights reserved.
//

import UIKit

class OfflineViewController: UIViewController {
    
    let network = NetworkManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

//        network.reachability.whenReachable = { reachability in
//            self.showMainController()
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    @IBAction func tryAgainAction(_ sender: AnyObject) {
        NetworkManager.isReachable { _ in
            self.dismiss(animated: true, completion: {
                NSLog("kdmhfdfj")
            })
        }
    }
    private func showMainController() -> Void {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: false)
        }
    }
}
