//
//  BankViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit
import AWSMobileClient
import AWSCore
import AWSDynamoDB

class BankViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
    var banks: [Bank] = []
    
    static func getViewController() -> BankViewController {
        let viewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "ViewController") as! BankViewController
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Banks"
        getItemsFromDatabase()
        tableView.tableFooterView = UIView()
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
        
        let bank: Bank = Bank()
        bank._id = "\(element.name)-\(element.last4Digits)"
        bank._name = element.name
        bank._last4Digits = NSNumber(integerLiteral: element.last4Digits)
        bank._isCreditCard = NSNumber(booleanLiteral: element.isCreditCard)
        bank._createdOn = Date().description
        bank._modifiedOn = Date().description
        
        showSpinner()
        dynamoDbObjectMapper.save(bank, completionHandler: { [weak self]
            (error: Error?) -> Void in
            guard let self = self else {return}
            self.removeSpinner()
            guard error == nil else {
                print("Amazon DynamoDB Save Error: \(error!)")
                return
            }
            self.banks.append(bank)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
    
    private func getItemsFromDatabase() {
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 20
        showSpinner()
        dynamoDbObjectMapper.scan(Bank.self, expression: scanExpression)
            .continueWith(block: { [weak self] (task:AWSTask) -> Any? in
            guard let self = self else {return nil}
                self.removeSpinner()
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
    
    func delete(bank: Bank) {
        showSpinner()
        dynamoDbObjectMapper.remove(bank)
            .continueWith(block: { [weak self] (task:AWSTask) -> Any? in
            guard let self = self else {return nil}
                self.removeSpinner()
            if let error = task.error {
                print("The request failed. Error: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            return nil
        })
    }
}

extension BankViewController: UITableViewDelegate, UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return banks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let element = banks[indexPath.row]
        cell.textLabel?.text = element._name
        cell.detailTextLabel?.text = "xxxx-\(element._last4Digits?.description ?? "n/a")"
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Do you mean delete!", message: "This will delete bank and all its releated transactions. Do you wanna proceed deleting?", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Proceed", style: .default, handler: { [weak self] _ in
                guard let self = self else {return}
                self.delete(bank: self.banks.remove(at: indexPath.row))
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
