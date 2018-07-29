//
//  AddBankViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit
import RxSwift

class AddBankViewController: UIViewController {
    
    //constants for this class
    private let noBankTitleString = "No Bank/Card Name"
    private let noBankMessageString = "Please enter a bank/card name"
    private let noLast4DigitsTitleString = "No last 4 digits"
    private let noLast4DigitsMessageString = "Please enter last 4 digits of the card. We need this to show a difference if you have multiple cards with same bank."
    private let numberOfDigitsTitleString = "Not enough digits"
    private let numberOfDigitsMessageString = "Please enter all 4 digits"
    private let defaultAlertTitle = "OK"
    
    @IBOutlet weak private var bankNameTF: UITextField!
    @IBOutlet weak private var last4DigitisTF: UITextField!
    @IBOutlet weak private var isCreditCardSwitch: UISwitch!
    
    let bankNameSubject = PublishSubject<(String, String, Bool)>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add a Bank"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //finally we need send onCompleted event to make the subject dispose
        bankNameSubject.onCompleted()
    }
    
    @IBAction private func addBankButtonTapped(_ sender: Any) {
        addingBankHandler()
    }
    
    private func addingBankHandler() {
        guard let bankName = bankNameTF.text, !bankName.isEmpty else {
            showAlert(withTitle: noBankTitleString, andMessage: noBankMessageString, andDefaultActionTitle: defaultAlertTitle, andCustomActions: nil)
            return
        }
        guard let last4Digits = last4DigitisTF.text, !last4Digits.isEmpty else {
            showAlert(withTitle: noLast4DigitsTitleString, andMessage: noLast4DigitsMessageString, andDefaultActionTitle: defaultAlertTitle, andCustomActions: nil)
            return
        }
        guard last4Digits.count > 3 else {
            showAlert(withTitle: numberOfDigitsTitleString, andMessage: numberOfDigitsMessageString, andDefaultActionTitle: defaultAlertTitle, andCustomActions: nil)
            return
        }
        bankNameSubject.onNext((bankName, last4Digits, isCreditCardSwitch.isOn))
        navigationController?.popViewController(animated: true)
    }
    
}
