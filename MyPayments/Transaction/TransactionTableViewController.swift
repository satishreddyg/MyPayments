//
//  TransactionTableViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 3/23/19.
//  Copyright © 2019 Blackmoon. All rights reserved.
//

import UIKit
import AWSMobileClient
import AWSCore
import AWSDynamoDB
import AWSCognitoIdentityProvider
import AWSCognitoIdentityProviderASF
import AWSS3

class TransactionTableViewController: UITableViewController {
    
    var transactions: [Transaction] = []
    var bank: Bank!
    private let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()

    static var getTableViewController: TransactionTableViewController {
        return TransactionTableViewController(nibName: "TransactionTableViewController", bundle: nil)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(bank._name!) transactions"
        getItemsFromDatabase()

        let addTransactionButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTransaction))
        self.navigationItem.rightBarButtonItem = addTransactionButton
        tableView.register(UINib(nibName: "TransactionCell", bundle: nil), forCellReuseIdentifier: "transactionCell")
        tableView.tableFooterView = UIView()
    }
    
    @objc private func addTransaction() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTransactionViewController") as! AddTransactionViewController
        vc.bank = bank
        vc.transactionHandler = { [weak self] transaction in
            guard let self = self else {return}
            self.transactions.append(transaction)
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
                self.tableView.reloadData()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func getItemsFromDatabase() {
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 20
        scanExpression.expressionAttributeNames = [
            "#_associatedBankId": "associatedBankId"
        ]
        scanExpression.filterExpression = "#_associatedBankId = :associatedBankId"
        scanExpression.expressionAttributeValues = [":associatedBankId" : "\(bank._name!)-\(bank._last4Digits!)"]
        
        showSpinner()
        dynamoDbObjectMapper.scan(Transaction.self, expression: scanExpression).continueWith(block: { [weak self] (task:AWSTask) -> Any? in
            guard let self = self else {return nil}
            self.removeSpinner()
            if let error = task.error {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput = task.result {
                for i in 0..<paginatedOutput.items.count {
                    if let transaction = paginatedOutput.items[i] as? Transaction {
                        self.transactions.append(transaction)
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            return nil
        })
    }
    
    /**
     deletes the transaction data from dynamoDB
     */
    func delete(transaction: Transaction) {
        showSpinner()
        self.deleteS3Object(imageKey: transaction._s3ImageKey!)
        dynamoDbObjectMapper.remove(transaction,
                                    completionHandler: { [weak self] (error: Error?) -> Void in
            guard let self = self else {return}
            self.removeSpinner()
            guard error == nil else {
                print("The request failed. Error: \(error!)")
                return
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath)
        let transaction = transactions[indexPath.row]
        cell.textLabel?.text = transaction._spentOn
        cell.detailTextLabel?.text = "$\(transaction._amount?.description ?? "")"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = TransactionDetailViewController(nibName: "TransactionDetailViewController", bundle: nil)
        vc.transaction = transactions[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
 
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Do you mean delete!", message: "This will delete the transaction permanently. Do you wanna proceed deleting?", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Proceed", style: .default, handler: { [weak self] _ in
                guard let self = self else {return}
                self.delete(transaction: self.transactions.remove(at: indexPath.row))
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    /**
     deletes the image data from S3 bucket
    */
    func deleteS3Object(imageKey : String){
        
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: CognitoIdentityUserPoolRegion, identityPoolId: "us-east-1:84f86ad3-dd38-48fe-9da2-ebec7a5ba968")
        let configuration = AWSServiceConfiguration(region: CognitoIdentityUserPoolRegion, credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AWSS3.register(with: configuration!, forKey: "defaultKey")
        let s3 = AWSS3.s3(forKey: "defaultKey")
        let deleteObjectRequest = AWSS3DeleteObjectRequest()
        deleteObjectRequest?.bucket = "mypayments-userfiles-mobilehub-317933950"
        deleteObjectRequest?.key = imageKey // File name
        s3.deleteObject(deleteObjectRequest!).continueWith { (task:AWSTask) -> AnyObject? in
            if let error = task.error {
                print("Error occurred: \(error)")
                return nil
            }
            print("Bucket deleted successfully.")
            return nil
        }
        
    }
}
