//
//  AddTransactionViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit
import AWSMobileClient
import AWSCore
import AWSDynamoDB

class AddTransactionViewController: UIViewController {
    
    @IBOutlet weak var amountTF: UITextField!
    @IBOutlet weak var categoryTF: UITextField!
    @IBOutlet weak var extraNotesTF: UITextField!
    
    var bank: Bank!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Transaction details"
    }
    
    @IBAction func addTransactionButtonTapped(_ sender: Any) {
        guard let amountString = amountTF.text, !amountString.isEmpty, let amount = Int(amountString) else {
            showAlert(withTitle: "No amount entered", andMessage: "Please enter amount", andDefaultActionTitle: "Got it", andCustomActions: nil)
            return
        }
        guard let spentOn = categoryTF.text, !spentOn.isEmpty else {
            showAlert(withTitle: "Where did you spend?", andMessage: "Please enter on what you spent", andDefaultActionTitle: "OK", andCustomActions: nil)
            return
        }
        saveTransactionDetails(amount: amount, spentOn: spentOn, notes: extraNotesTF.text)
    }
    
    private func saveTransactionDetails(amount: Int, spentOn: String, notes: String?) {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        // Create data object using data models you downloaded from Mobile Hub
        let transaction: Transaction = Transaction()
        
        
        transaction._bankName = bank._name
        transaction._spentOn = spentOn
        transaction._addedOn = Date().description
        transaction._amount = NSNumber(integerLiteral: amount)
        transaction._cardLast4Digits = bank._last4Digits
        transaction._modifiedOn = Date().description
        transaction._notes = notes
        
        //Save a new item
        dynamoDbObjectMapper.save(transaction, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
        
    }
}
