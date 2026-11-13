//
//  ReportUserViewController.swift
//  excero
//
//  Created by Alessandro on 23.04.24.
//

import UIKit

class ReportUserViewController: DataBundledViewController {
    
    public static let DATA_BUNDLE_REPORTED_USER_KEY = "ch.unil.silacci.excero.ReportUserViewController.DATA_BUNDLE_REPORTED_USER_KEY"

    @IBOutlet weak var reportReasonTextView: UITextView!
    @IBOutlet var sendReportButton: UIView!
    @IBOutlet var cancelButton: UIView!
    
    @IBOutlet weak var reportedUserUsername: UILabel!
    @IBOutlet weak var bottomTextViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var topHeaderConstraint: NSLayoutConstraint!
    
    private var keyboardHeight: CGFloat = 0.0
    private var keyboardIsOpen: Bool = false
    
    private var reportedUser: UserRepresentation?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName())
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapDetected(sender:))))
        if let dataBundle = super.dataBundle, dataBundle[ReportUserViewController.DATA_BUNDLE_REPORTED_USER_KEY] != nil {
            self.reportedUser = dataBundle[ReportUserViewController.DATA_BUNDLE_REPORTED_USER_KEY] as? UserRepresentation
            self.reportedUserUsername.text = self.reportedUser?.username
        }
    }
    
    @objc func onViewTapDetected(sender: UITapGestureRecognizer) {
        if self.keyboardIsOpen {
            ResourcesManager.instance.registerUserEvent(action: .FIELD_TYPE, target: "HIDE_KEYBOARD")
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
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "SEND_USER_REPORT")
        if let user = ResourcesManager.instance.user, let issuerURL = user.url {
            if let reportedUser = self.reportedUser, let reportedUserURL = reportedUser.url {
                let api = AuthenticatedApiFacade()
                Task {
                    let userReport = UserReportCodable(issuer: issuerURL, reportedUser: reportedUserURL, issue: self.reportReasonTextView.text)
                    do {
                        let _ = try await api.post(endpointPath: "admin/reports/users/", data: userReport, header: nil)
                    } catch {
                        ResourcesManager.logger.error("ReportUserViewController.onSendClicked could not send user report. Detailed error: \(error)")
                        fatalError("Error when sending user report request \(error)")
                    }
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        self.dismiss(animated: true)
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "CANCEL_USER_REPORT")
    }
    
}
