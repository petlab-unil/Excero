//
//  ReportBugViewController.swift
//  excero
//
//  Created by Alessandro on 23.04.24.
//

import UIKit

class ReportBugViewController: DataBundledViewController {
    
    
    @IBOutlet weak var reportReasonTextView: UITextView!
    
    private var keyboardHeight: CGFloat = 0.0
    private var keyboardIsOpen: Bool = false
    
    @IBOutlet weak var bottomTextViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var topHeaderConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName())
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapDetected(sender:))))
    }
    
    @objc func onViewTapDetected(sender: UITapGestureRecognizer) {
        ResourcesManager.instance.registerUserEvent(action: .FIELD_TYPE, target: "HIDE_KEYBOARD")
        if self.keyboardIsOpen {
            self.view.endEditing(true)
        }
    }
    
    @objc func keyboardWillAppear(_ notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            ResourcesManager.instance.registerUserEvent(action: .FIELD_TYPE, target: "SHOW_KEYBOARD")
            self.keyboardHeight = keyboardSize.height
            if self.view.frame.origin.y == 0 {
                self.topHeaderConstraint.constant -= keyboardSize.height
                self.bottomTextViewConstraint.constant += keyboardSize.height
                self.keyboardIsOpen = true
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    @objc func keyboardWillDisappear(_ notification: NSNotification) {
        self.topHeaderConstraint.constant += self.keyboardHeight
        self.bottomTextViewConstraint.constant -= self.keyboardHeight
        self.keyboardIsOpen = false
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func onSendClicked(_ sender: Any) {
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "SEND_BUG_REPORT")
        if let user = ResourcesManager.instance.user {
            let api = AuthenticatedApiFacade()
            if FileManager.default.fileExists(atPath: ResourcesManager.instance.logDocumentPath) {
                do {
                    let file: Data = try Data(contentsOf: URL(fileURLWithPath: ResourcesManager.instance.logDocumentPath), options: .uncached)
                    let additionalData: Dictionary<String, String> = ["issuer": user.url!, "issue": reportReasonTextView.text]
                    Task {
                        let _ = try await api.postFormData(endpointPath: "admin/reports/bugs", file: file, header: nil)
                        self.dismiss(animated: true)
                    }
                } catch {
                    ResourcesManager.logger.error("ReportBugViewController.onSendClick log file cannot be read. Detailed error: \(error)")
                }
            }
        }
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        self.dismiss(animated: true)
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "CANCEL_BUG_REPORT")
    }
}
