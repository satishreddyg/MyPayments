//
//  TransactionDetailViewController.swift
//  MyPayments
//
//  Created by Satish Garlapati on 4/12/19.
//  Copyright © 2019 Blackmoon. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import AWSCognitoIdentityProviderASF
import AWSS3

class TransactionDetailViewController: UIViewController {
    
    @IBOutlet weak var spentAtLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var transaction: Transaction!
    private let s3Url = "https://mypayments-userfiles-mobilehub-317933950.s3.amazonaws.com/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: CognitoIdentityUserPoolRegion, identityPoolId: "us-east-1:84f86ad3-dd38-48fe-9da2-ebec7a5ba968")
        let configuration = AWSServiceConfiguration(region: CognitoIdentityUserPoolRegion, credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AWSS3.register(with: configuration!, forKey: "defaultKey")
        
        let listRequest: AWSS3ListObjectsRequest = AWSS3ListObjectsRequest()
        listRequest.bucket = "mypayments-userfiles-mobilehub-317933950"

        spentAtLabel.text = "You Spent at: \(transaction._spentOn!)"
        dateLabel.text = "added on: \(transaction._addedOn!.date()?.dateString() ?? "")"
        amountLabel.text = "$\(transaction._amount!)"
        
        let finalUrl = self.s3Url + transaction._s3ImageKey!
        imageView.loadImageUsingCache(withUrl: finalUrl)
    }

}

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    func loadImageUsingCache(withUrl urlString : String) {
        let url = URL(string: urlString)
        
        // check cached image
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        // if not, download image from url
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                guard let _data = data else {print("not correct to") ;return}
                if let image = UIImage(data: _data) {
                    self.image = image
                    imageCache.setObject(image, forKey: urlString as NSString)
                } else {
                    print("not ab;le to")
                }
            }
            
        }).resume()
    }
}

extension String {
    func date(fromLocale locale: Locale = .current, withFormat format: String = "yyyy-MM-dd HH:mm:ss Z") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.locale = Locale.current
        return dateFormatter.date(from: self)
    }
}

extension Date {
    func dateString(withFormat format: String = "MMM dd, yyyy 'at' h:mm a z") -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd, yyyy 'at' h:mm a z"
        return dateFormatterPrint.string(from: self)
    }
}
