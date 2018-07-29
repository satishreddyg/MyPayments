//
//  ViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 7/28/18.
//  Copyright © 2018 Blackmoon. All rights reserved.
//

import UIKit
import RxSwift

class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    let disposeBag = DisposeBag()
    var banks = Variable<[(name: String, last4Digits: String, isCreditCard: Bool)]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        banks.asObservable()
            .subscribe(onNext: { [weak self] event in
            self?.tableView.reloadData()
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
            }.disposed(by: disposeBag)
        navigationController?.pushViewController(addBankViewController, animated: true)
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
}
