//
//  UIViewController+Extension.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit

extension UIViewController {
    func showSpinner() {
        let spinnerView = UIView(frame: view.bounds)
        spinnerView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        spinnerView.tag = 9000
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            self.view.addSubview(spinnerView)
        }
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            for view in self.view.subviews {
                if view.tag == 9000 {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    func showAlert(withTitle title: String, andMessage message: String, andDefaultActionTitle defaultTitle: String, andCustomActions customActions: [UIAlertAction]?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let actions = customActions {
            for action in actions {
                alert.addAction(action)
            }
        }
        
        let cancelAction = UIAlertAction(title: defaultTitle, style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
