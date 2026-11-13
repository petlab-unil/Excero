//
//  AccountActivationViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 31.08.2024.
//

import UIKit

class AccountActivationViewController: DataBundledViewController {
    
    public static let DATA_BUNDLE_ACTIVATION_TOKEN = "ch.unil.silacci.excero.AccountActivationViewController.DATA_BUNDLE_ACTIVATION_TOKEN"
    public static let DATA_BUNDLE_ACTIVATION_UID = "ch.unil.silacci.excero.AccountActivationViewController.DATA_BUNDLE_ACTIVATION_UID"
    
    public static let USER_ACTIVATION_RESULT_EVENT = "ch.unil.silacci.excero.AccountActivationViewController.USER_ACTIVATION_RESULT_EVENT"

    @IBOutlet weak var pwd1TextField: UITextField!
    @IBOutlet weak var pwd2TextField: UITextField!
    
    @IBOutlet weak var errorMessageLabel: PaddingLabel!
    @IBOutlet weak var keychainSaveSwitch: UISwitch!
    
    private var currentUserToken: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let bundle = super.dataBundle {
            if let token = bundle[AccountActivationViewController.DATA_BUNDLE_ACTIVATION_TOKEN] {
                self.currentUserToken = token as? String
            }
        }
        self.isModalInPresentation = true
    }
    
    @IBAction func validateButtonClicked(_ sender: Any) {
        guard let currentUserToken else {
            ResourcesManager.logger.error("AccountActivationViewController.validateButtonClicked user tried to validate new account password without providing token.")
            self.dismiss(animated: true)
            return
        }
        if let pwd1 = self.pwd1TextField.text, let pwd2 = self.pwd2TextField.text {
            if pwd1 == pwd2 {
                let authenticationController = AuthenticationController()
                Task {
                    do {
                        let user = try await authenticationController.activate(pwd1: pwd1, pwd2: pwd2, token: currentUserToken)
                        if let user = user {
                            let decoder = JSONDecoder()
                            do {
                                let activatedUser = try decoder.decode(ActivationUserCodable.self, from: user)
                                if let username = activatedUser.username {
                                    if self.keychainSaveSwitch.isOn {
                                        try authenticationController.saveCredentials(username: username, password: pwd1)
                                    }
                                    if let complete = complete {
                                        complete(self.keychainSaveSwitch.isOn)
                                    }
                                    self.dismiss(animated: true)
                                }
                            } catch {
                                ResourcesManager.logger.error("AccountActivationViewController.validateButtonClicked could not decode activation result using JSONDecoder. Detailed error: \(error)")
                                self.errorMessageLabel.text = "Une erreur est survenue lors de votre activation, merci de re-essayé plus tard ou contacter un administrateur."
                                self.errorMessageLabel.isHidden = false
                            }
                        }
                    } catch {
                        ResourcesManager.logger.error("AccountActivationViewController.validateButtonClicked could not activate account with data token(\(currentUserToken)). Detailed error: \(error)")
                        self.errorMessageLabel.text = "Vous avez dépassé le temps autorisé pour l'activation de votre compte, merci de contacter un administrateur."
                        self.errorMessageLabel.isHidden = false
                    }
                }
            } else {
                ResourcesManager.logger.warning("AccountActivationViewController.validateButtonClicked user tried to validate account with different passwords.")
                self.errorMessageLabel.text = "Les deux mots de passe ne correspondent pas."
                self.errorMessageLabel.isHidden = false
            }
        } else {
            ResourcesManager.logger.warning("AccountActivationViewController.validateButtonClicked user tried to validate new account password without providing matching fields.")
            self.errorMessageLabel.text = "Merci de remplir les deux champs ci-dessous avant de cliquer sur valider."
            self.errorMessageLabel.isHidden = false
        }
    }
    
    @IBAction func onPwd1EditingDidBegin(_ sender: Any) {
        if !self.errorMessageLabel.isHidden {
            self.errorMessageLabel.isHidden = true
        }
    }
    
    @IBAction func onPwd2EditingDidBegin(_ sender: Any) {
        if !self.errorMessageLabel.isHidden {
            self.errorMessageLabel.isHidden = true
        }
    }
    
    @IBAction func keychainSwitchValueChanged(_ sender: Any) {
    
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}
