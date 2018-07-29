//
//  ViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit
import RxSwift
import AWSMobileClient
import AWSCore
import AWSDynamoDB

class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    let disposeBag = DisposeBag()
    var banks = Variable<[(name: String, last4Digits: String, isCreditCard: Bool)]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getItemsFromDatabase()
        banks.asObservable()
            .subscribe(onNext: { [weak self] event in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }, onCompleted: {
                print("completed")
            }).disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func addBankButtonTapped(_ sender: Any) {
        let addBankViewController = AddBankViewController(nibName: "AddBankViewController", bundle: nil)
        addBankViewController.bankNameSubject
            .asObservable()
            .subscribe { [weak self] event in
                guard let element = event.element else { return }
                self?.banks.value.append(element)
                self?.saveBankDetailsToDatabase(with: element)
            }.disposed(by: disposeBag)
        navigationController?.pushViewController(addBankViewController, animated: true)
    }
    
    private func saveBankDetailsToDatabase(with element: (name: String, last4Digits: String, isCreditCard: Bool)) {
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        // Create data object using data models you downloaded from Mobile Hub
        let bank: Bank = Bank()
        
        bank._userId = AWSIdentityManager.default().identityId
        bank._name = element.name
        bank._last4Digits = element.last4Digits
        bank._isCreditCard = 1
        
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
            if let error = task.error {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput = task.result {
                for i in 0..<paginatedOutput.items.count {
                    if let bank = paginatedOutput.items[i] as? Bank,
                        let bankName = bank._name,
                        let last4Digits = bank._last4Digits,
                        let isCreditCard = bank._isCreditCard {
                        self?.banks.value.append((bankName, last4Digits, (isCreditCard == 1)))
                    }
                }
            }
            return nil
        })
    }
    
    func deleteItemFromDatabase(withElement element: (name: String, last4Digits: String, isCreditCard: Bool)) {
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
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return banks.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let element = banks.value[indexPath.row]
        cell.textLabel?.text = element.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let bank = banks.value[indexPath.row]
            banks.value.remove(at: indexPath.row)
            deleteItemFromDatabase(withElement: bank)
        }
    }
}

/*
 Delete call is failing becoz we didn't send all the variable values
 
 we need change the banks array type to BANK, so that we will have user_id which we need to delete
 */
