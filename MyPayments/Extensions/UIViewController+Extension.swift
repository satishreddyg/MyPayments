//
//  UIViewController+Extension.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit

extension UIViewController {
    
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
