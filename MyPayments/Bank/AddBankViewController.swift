//
//  AddBankViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit

class AddBankViewController: UIViewController {
    
    @IBOutlet weak var bankNameTF: UITextField!
    @IBOutlet weak var last4DigitisTF: UITextField!
    @IBOutlet weak var isCreditCardSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func addBankButtonTapped(_ sender: Any) {
    }
    
}
