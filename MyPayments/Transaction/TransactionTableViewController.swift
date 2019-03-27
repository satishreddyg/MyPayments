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

class TransactionTableViewController: UITableViewController {
    
    var transactions: [Transaction] = []
    var bank: Bank!
    
    static var getTableViewController: TransactionTableViewController {
        return TransactionTableViewController(nibName: "TransactionTableViewController", bundle: nil)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(bank._name!) transactions"
        getItemsFromDatabase()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        let addTransactionButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTransaction))
        self.navigationItem.rightBarButtonItem = addTransactionButton
        
        tableView.register(UINib(nibName: "TransactionCell", bundle: nil), forCellReuseIdentifier: "transactionCell")
    }
    
    @objc private func addTransaction() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTransactionViewController") as! AddTransactionViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func getItemsFromDatabase() {
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 20
        
        dynamoDbObjectMapper.scan(Transaction.self, expression: scanExpression).continueWith(block: { [weak self] (task:AWSTask) -> Any? in
            guard let self = self else {return nil}
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
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}
