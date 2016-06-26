//
//  QAComposeController.swift
//  Duke CSA
//
//  Created by Bill Yu on 6/24/16.
//  Copyright © 2016 Zhe Wang. All rights reserved.
//

import UIKit

class QAComposeAnswerController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var contentTextView: UITextView!
    
    let PLACEHOLDER_ANSWER_CONTENT: String = "Let me tell you..."
    
    var validContent = false
    
    var postConnectSuccess = false
    var postAllowed = true
    
    let TIME_OUT_IN_SEC: NSTimeInterval = 5.0
    
    var newPost = QAPost(type: PFKey.QA.TYPE.ANSWER)
    
    @IBAction func onPost(sender: AnyObject) {
        if !postAllowed{
            return
        }
        
        self.view.endEditing(true)
        if (!validateInput()) {
            return
        }
        
        newPost.content = contentTextView.text
        print(AppData.QAData.selectedQAPost)
        print(AppData.QAData.selectedQAPost.PFInstance)
        newPost.question = AppData.QAData.selectedQAPost.PFInstance
        
        //change app status
        postConnectSuccess = false
        postAllowed = true
        self.view.makeToastActivity(position: HRToastPositionCenterAbove, message: "Posting...")
        AppFunc.pauseApp()
        
        //set time out
        NSTimer.scheduledTimerWithTimeInterval(TIME_OUT_IN_SEC, target: self, selector: #selector(postTimeOut), userInfo: nil, repeats: false)
        
        //post
        newPost.saveWithBlock { (success:Bool, error:NSError?) -> Void in
            //change app status
            self.postConnectSuccess = true
            self.postAllowed = true
            AppFunc.resumeApp()
            self.view.hideToastActivity()
            
            //case handle
            if success{
                AppStatus.QAStatus.tableShouldRefresh = true
                self.cleanPostView(shouldPop: true)
            } else {
                self.view.makeToast(message: "Failed to post. Please check your internet connection.", duration: 1.5, position: HRToastPositionCenterAbove)
            }
        }
        
        AppData.QAData.selectedQAPost.answers.append(newPost.PFInstance)
        AppData.QAData.selectedQAPost.saveWithBlock { (sucess: Bool, error: NSError?) in
            if let error = error {
                print("error saving answer to question: \(error)")
            }
        }
    }
    
    func validateInput() -> Bool{
        validContent = contentTextView.text! != PLACEHOLDER_ANSWER_CONTENT
        
        if !validContent {
            self.view.makeToast(message: "Details Needed", duration: 1.0, position: HRToastPositionCenterAbove)
            return false
        }
        return true
    }
    
    func postTimeOut() {
        if !postConnectSuccess{
            print("Post time out")
            AppFunc.resumeApp()
            self.view.hideToastActivity()
            self.view.makeToast(message: "Connecting timed out, job sended into background. Please wait.", duration: 1.5, position: HRToastPositionCenterAbove)
        }
    }
    
    //// MARK: - text delegate
    //textview
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView.text == PLACEHOLDER_ANSWER_CONTENT {
            textView.text = ""
            textView.textColor = UIColor.blackColor()
        }
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == nil || textView.text == "" {
            textView.text = PLACEHOLDER_ANSWER_CONTENT
            textView.textColor = AppConstants.Color.placeholder
        }
    }
    
    //textfield
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func cleanPostView(shouldPop shouldPop:Bool){
        contentTextView.text = nil
        validContent = false
        
        if shouldPop {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad - QAComposeAnswerViewController ")
        contentTextView.delegate = self
    }
    
    deinit{
        print("Release - QAComposeAnswerViewController")
    }
}