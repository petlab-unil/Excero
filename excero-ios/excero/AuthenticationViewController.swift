//
//  AuthenticationViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 27.09.22.
//

import UIKit

class AuthenticationViewController: UIViewController {
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwdTextfield: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var forgotPwdButton: UIButton!
    @IBOutlet weak var errorMessage: UILabel!
    
    
    @IBOutlet weak var useKeychainSwitch: UISwitch!
    @IBOutlet weak var forgotPwdBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var uiLoginBackgroundBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var uiLoginBackgroundTopConstraint: NSLayoutConstraint!
    
    var connectButtonBottomConstraintConstantOrig: CGFloat = 0
    var uiLoginBackgroundBottomConstraintConstantOrig: CGFloat = 0
    var uiLoginBackgroundTopConstraintConstantOrig: CGFloat = 0
    var offsetConstraints: CGFloat = 10
    
    private let authController: AuthenticationController = AuthenticationController()
    
    let apiAuthentication = Api(url: Constants.BASE_API_URL, header: [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailTextfield.frame.size.height = 50
        self.passwdTextfield.frame.size.height = 50
        
        self.emailTextfield.layer.borderWidth = 2
        self.emailTextfield.layer.borderColor = ColorUtility.colorWithHexString(hexString: "0098B2").cgColor
        self.passwdTextfield.layer.borderWidth = 2
        self.passwdTextfield.layer.borderColor = ColorUtility.colorWithHexString(hexString: "0098B2").cgColor
        let tap = UITapGestureRecognizer(target: self, action: #selector(AuthenticationViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        self.errorMessage.layer.borderWidth = 2
        self.errorMessage.layer.borderColor = UIColor.red.cgColor
        self.connectButtonBottomConstraintConstantOrig = self.forgotPwdBottomConstraint.constant
        self.uiLoginBackgroundBottomConstraintConstantOrig = self.uiLoginBackgroundBottomConstraint.constant
        self.uiLoginBackgroundTopConstraintConstantOrig = self.uiLoginBackgroundTopConstraint.constant
        NotificationCenter.default.addObserver(self, selector: #selector(AuthenticationViewController.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AuthenticationViewController.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        if !Constants.IS_APP_DEV_MODE {
            if let userDefaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME) {
                self.useKeychainSwitch.isOn = userDefaults.bool(forKey: Constants.USER_DEFAULTS_AUTOCONNECT)
            }
        
            if self.useKeychainSwitch.isOn {
                do {
                    let credentials = try self.authController.getCredentials()
                    self.emailTextfield.text = credentials.username
                    self.passwdTextfield.text = credentials.password
                    self.connectButtonClicked(self)
                } catch {
                    ResourcesManager.logger.warning("AuthenticationViewController.viewDidLoad use keychain switch is on, but credentials could not be retrieved. Detailed error \(error)")
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ResourcesManager.instance.openingURL.subscribe(onNext: { value in
            guard let value = value else { return }
            let token = value.valueOf("t")
            ResourcesManager.logger.info("AuthenticationViewController.viewDidAppear opening activation view with token(\(token)).")
            let bundle = [AccountActivationViewController.DATA_BUNDLE_ACTIVATION_TOKEN: token]
            self.displayViewControllerAsSheet(storyBoardName: "Authentication", viewControllerName: "Activation", detents: [.medium()], data: bundle as Dictionary<String, Any>, showGrabber: false) { keyChainIsOn in
                guard let keyChainIsOn = keyChainIsOn as? Bool else {
                    ResourcesManager.logger.warning("AuthenticationViewController.viewDidAppear keychain return value from Activation view is nil.")
                    return
                }
                self.useKeychainSwitch.setOn(keyChainIsOn, animated: false)
                if keyChainIsOn {
                    do {
                        let credentials = try self.authController.getCredentials()
                        self.emailTextfield.text = credentials.username
                        self.passwdTextfield.text = credentials.password
                        self.connectButtonClicked(self)
                    } catch {
                        ResourcesManager.logger.error("AuthenticationViewController.viewDidAppear error while getting credentials from the keychain. Detailed error \(error)")
                    }
                }
            }
        })
    }
    
    @IBAction func onUseKeychainSwitchValueChanged(_ sender: Any) {
        if self.useKeychainSwitch.isOn {
            do {
                let credentials = try self.authController.getCredentials()
                self.emailTextfield.text = credentials.username
                self.passwdTextfield.text = credentials.password
                self.connectButtonClicked(self)
            } catch {
                ResourcesManager.logger.warning("AuthenticationViewController.onUseKeychainSwitchValueChanged use keychain switch has been set to on, but credentials could not be retrieved. Detailed error \(error)")
            }
        }
        if let userDefaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME) {
            userDefaults.set(self.useKeychainSwitch.isOn, forKey: Constants.USER_DEFAULTS_AUTOCONNECT)
        }
    }
    
    @IBAction func connectButtonClicked(_ sender: Any) {
        Task { @MainActor in
            self.view.endEditing(true)
            self.showActivityIndicator(text: "Chargement...", subtext: nil, display: true)
            guard let rootWindow = self.view.window else { return }
            guard let email = self.emailTextfield.text else { return }
            guard let password = self.passwdTextfield.text else { return }
            if let _ = await apiAuthentication.authenticate(username: email, password: password) {
                let apiAuth = AuthenticatedApiFacade()
                let userSelfData = try await apiAuth.get(endpointPath: "users/self/", header: nil) // FIXME: token is still empty in the database at this moment
                if let userSelfData = userSelfData {
                    let decoder = JSONDecoder()
                    var userSelf: [UserCodable]?
                    do {
                        userSelf = try decoder.decode([UserCodable].self, from: userSelfData)
                        if self.useKeychainSwitch.isOn {
                            do {
                                try self.authController.saveCredentials(username: email, password: password)
                            } catch {
                                ResourcesManager.logger.warning("AuthenticationViewController.connectButtonClicked use keychain switch is set to on, but credentials could not be saved. Detailed error \(error)")
                                self.showActivityIndicator(text: "", subtext: nil, display: false)
                            }
                        }
                    } catch {
                        ResourcesManager.logger.error("AuthenticationViewController.connectButtonClicked error encountered while decoding user codable. Detailed error \(error)")
                        self.showActivityIndicator(text: "", subtext: nil, display: false)
                    }
                    if let userSelf = userSelf {
                        ResourcesManager.instance.user = try await UserRepresentation.fromCodable(user: userSelf[0])
                        let _ = ResourcesManager.instance.user?.toCodable()
                        try CoreDataController.instance.mainContext.save()
                    }
                } else {
                    ResourcesManager.logger.warning("AuthenticationViewController.connectButtonClicked user self data is empty.")
                    self.showActivityIndicator(text: "", subtext: nil, display: false)
                }
                
                if let _ = userSelfData {
                    self.showActivityIndicator(text: "", subtext: nil, display: false)
                    let event = EventDispatcher.DispatchableEvent(identifier: AppOrchestrator.ORCHESTRATOR_EVENT_LOAD_STORYBOARD)
                    if (await !HealthKitUtility.instance.hasStepPermissions()) {
                        ResourcesManager.logger.info("AuthenticationViewController.connectButtonClicked has not set permissions for Healthkit use.")
                        event.content = AppOrchestrator.StoryBoardBundle(storyboardName: "FirstInit", viewName: "FirstInit", rootWindow: rootWindow) as AnyObject
                    } else {
                        event.content = AppOrchestrator.StoryBoardBundle(storyboardName: "Main", viewName: "Main", rootWindow: rootWindow) as AnyObject
                    }
                    EventDispatcher.instance.emit(event)
                }
            } else {
                self.showActivityIndicator(text: "", subtext: nil, display: false)
                self.errorMessage.text = Constants.TEXT_AUTH_ERROR
                self.errorMessage.isHidden = false
            }
        }
    }
    
    @IBAction func forgotPwdButtonClicked(_ sender: Any) {
        if let url = URL(string: Constants.PASSWORD_RESET_LINK), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension AuthenticationViewController {
   
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if !self.errorMessage.isHidden {
            self.errorMessage.isHidden = true
        }
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            ResourcesManager.logger.warning("AuthenticationViewController.keyboardWillShow keyboard size is nil.")
            return
        }
        let keyboardHeight = keyboardSize.height
        if let userInfo = notification.userInfo {
            switch (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double, userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) {
            case let (.some(duration), .some(curve)):
                guard let curveAnimation = UIView.AnimationCurve(rawValue: curve) else { break }
                self.forgotPwdBottomConstraint.constant = keyboardHeight + self.offsetConstraints
                self.uiLoginBackgroundBottomConstraint.constant = keyboardHeight + self.offsetConstraints
                self.uiLoginBackgroundTopConstraint.constant = -1 * (keyboardHeight + self.offsetConstraints)
                let animator = UIViewPropertyAnimator(duration: duration, curve: curveAnimation) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
                animator.startAnimation()
            default:
                break
            }
            
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        guard let _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            ResourcesManager.logger.warning("AuthenticationViewController.keyboardWillHide keyboard size is nil.")
            return
        }
        if let userInfo = notification.userInfo {
            switch (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double, userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) {
            case let (.some(duration), .some(curve)):
                guard let curveAnimation = UIView.AnimationCurve(rawValue: curve) else { break }
                self.forgotPwdBottomConstraint.constant = self.connectButtonBottomConstraintConstantOrig
                self.uiLoginBackgroundBottomConstraint.constant = self.uiLoginBackgroundBottomConstraintConstantOrig
                self.uiLoginBackgroundTopConstraint.constant = self.uiLoginBackgroundTopConstraintConstantOrig
                let animator = UIViewPropertyAnimator(duration: duration, curve: curveAnimation) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
                animator.startAnimation()
            default:
                
                break
            }
            
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
