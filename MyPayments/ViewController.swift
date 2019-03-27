//
//  ViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit
import AWSMobileClient
import AWSCore
import AWSDynamoDB

class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var banks: [Bank] = []
    
    static func getViewController() -> UIViewController {
        let viewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "ViewController") as! ViewController
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refresh()
    }

    func refresh() {
        getItemsFromDatabase()
    }

    @IBAction func addBankButtonTapped(_ sender: Any) {
        let addBankViewController = AddBankViewController(nibName: "AddBankViewController", bundle: nil)
        addBankViewController.bankDetailHandler = { [weak self] details in
            guard let self = self else {return}
            self.saveBankDetailsToDatabase(with: details)
            
        }
        navigationController?.pushViewController(addBankViewController, animated: true)
    }
    
    private func saveBankDetailsToDatabase(with element: (name: String, isCreditCard: Bool, last4Digits: Int)) {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        // Create data object using data models you downloaded from Mobile Hub
        let bank: Bank = Bank()
        
        bank._name = element.name
        bank._last4Digits = NSNumber(integerLiteral: element.last4Digits)
        bank._isCreditCard = NSNumber(booleanLiteral: element.isCreditCard)
        bank._createdOn = Date().description
        bank._modifiedOn = Date().description
        
        //Save a new item
        dynamoDbObjectMapper.save(bank, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
 
    }
    
    private func getItemsFromDatabase() {
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 20
        
        dynamoDbObjectMapper.scan(Bank.self, expression: scanExpression).continueWith(block: { [weak self] (task:AWSTask) -> Any? in
            guard let self = self else {return nil}
            if let error = task.error {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput = task.result {
                for i in 0..<paginatedOutput.items.count {
                    if let bank = paginatedOutput.items[i] as? Bank {
                        self.banks.append(bank)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            return nil
        })
    }
    
    func deleteItemFromDatabase(withElement element: (name: String, last4Digits: String, isCreditCard: Bool)) {
        /*
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let bankToDelete = Bank()
        bankToDelete?._name = element.name
        bankToDelete?._last4Digits = element.last4Digits
        
        dynamoDbObjectMapper.remove(bankToDelete!).continueWith(block: { (task:AWSTask) -> Any? in
            if let error = task.error {
                print("The request failed. Error: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            return nil
        })
        */
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return banks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let element = banks[indexPath.row]
        cell.textLabel?.text = element._name
        cell.detailTextLabel?.text = element._last4Digits?.description
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let bank = banks[indexPath.row]
            banks.remove(at: indexPath.row)
            //deleteItemFromDatabase(withElement: bank)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = TransactionTableViewController.getTableViewController
        vc.bank = banks[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "transactionSegue",
            let vc = segue.destination as? AddTransactionViewController,
            let bank = sender as? Bank {
            vc.bank = bank
        }
    }
}
