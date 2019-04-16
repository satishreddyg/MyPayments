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
import AWSS3

class AddTransactionViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var amountTF: UITextField!
    @IBOutlet weak var categoryTF: UITextField!
    @IBOutlet weak var extraNotesTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    var bank: Bank!
    private var imagePicker: UIImagePickerController!
    //call backs
    var transactionHandler: ((_ transaction: Transaction)->())!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Transaction details"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(takePicture))
        imageView.addGestureRecognizer(tapGesture)
        setupTextViewAttributes()
    }
    
    private func setupTextViewAttributes() {
        extraNotesTextView.layer.cornerRadius = 3
        extraNotesTextView.layer.borderWidth = 0.3
        extraNotesTextView.layer.borderColor = UIColor.lightGray.cgColor
        extraNotesTextView.delegate = self
        extraNotesTextView.text = "Extra Notes..."
        extraNotesTextView.textColor = UIColor.lightGray
        extraNotesTextView.font = UIFont(name: "Georgia-SemiBold", size: 15)
        extraNotesTextView.selectedTextRange = extraNotesTextView.textRange(from: extraNotesTextView.beginningOfDocument, to: extraNotesTextView.beginningOfDocument)
    }
    
    @objc private func takePicture() {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func addTransactionButtonTapped(_ sender: Any) {
        guard let amountString = amountTF.text, !amountString.isEmpty, let amount = Double(amountString) else {
            showAlert(withTitle: "No amount entered", andMessage: "Please enter amount", andDefaultActionTitle: "Got it", andCustomActions: nil)
            return
        }
        guard let spentOn = categoryTF.text, !spentOn.isEmpty else {
            showAlert(withTitle: "Where did you spend?", andMessage: "Please enter on what you spent", andDefaultActionTitle: "OK", andCustomActions: nil)
            return
        }
        saveTransactionDetails(amount: amount, spentOn: spentOn, notes: extraNotesTextView.text)
    }
    
    private func saveTransactionDetails(amount: Double, spentOn: String, notes: String?) {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        // Create data object using data models you downloaded from Mobile Hub
        let transaction: Transaction = Transaction()
        
        transaction._associatedBankId = bank._id
        transaction._spentOn = spentOn
        let addedOn = Date()
        transaction._addedOn = addedOn.description
        transaction._amount = NSNumber(floatLiteral: Double(round(1000*amount)/1000))
        transaction._modifiedOn = Date().description
        transaction._notes = notes
        
        var imageKey = String(format: "%ld", getMilliSeconds(for: addedOn))
        imageKey = imageKey + ".jpg"
        uploadData(with: imageKey)
        transaction._s3ImageKey = imageKey
        
        showSpinner()
        dynamoDbObjectMapper.save(transaction, completionHandler: { [weak self]
            (error: Error?) -> Void in
            guard let self = self else {return}
            self.removeSpinner()
            guard error == nil else {
                print("error was: \(error!)")
                return
            }
            self.transactionHandler(transaction)
        })
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            imagePicker.dismiss(animated: true, completion: nil)
            imageView.image = info[.originalImage] as? UIImage
    }
    
    func getMilliSeconds(for date: Date)->Int64 {
        return Int64(date.timeIntervalSince1970 * 1000)
    }
    
    func uploadData(with key: String) {
        guard let image = imageView.image,
            let data = image.jpegData(compressionQuality: 0.25) else {return}
        
        var bucket = "mypayments-userfiles-mobilehub-317933950"
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                print("upload in process \(progress)")
            })
        }
        
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                // Do something e.g. Alert a user for transfer completion.
                // On failed uploads, `error` contains the error object.
                bucket = task.bucket
                print("upload completed1 \(task.bucket)")
                print("upload completed2 \(String(describing: task.response))")
                print("upload completed3 \(task.key)")
            })
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadData(data,
                                   bucket: bucket,
                                   key: key,
                                   contentType: "image/jpeg",
                                   expression: expression,
                                   completionHandler: completionHandler).continueWith {
                                    (task) -> AnyObject? in
                                    if let error = task.error {
                                        print("Error: \(error.localizedDescription)")
                                    }
                                    
                                    if let _ = task.result {
                                        // Do something with uploadTask.
                                        
                                        print("something upload completed \(String(describing: task.result.debugDescription))")
                                        
                                    }
                                    return nil;
        }
    }
}

extension AddTransactionViewController: UITextViewDelegate, UITextFieldDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            
            textView.text = "Extra Notes..."
            textView.textColor = UIColor.lightGray
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }
            
            // Else if the text view's placeholder is showing and the
            // length of the replacement string is greater than 0, set
            // the text color to black then set its text to the
            // replacement string
        else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            textView.textColor = UIColor.black
            textView.text = text
        }
            
            // For every other case, the text should change with the usual
            // behavior...
        else {
            return true
        }
        
        // ...otherwise return false since the updates have already
        // been made
        return false
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case amountTF:
            amountTF.resignFirstResponder()
            categoryTF.becomeFirstResponder()
        case categoryTF:
            categoryTF.resignFirstResponder()
            extraNotesTextView.becomeFirstResponder()
        default: break
        }
        return true
    }
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}
