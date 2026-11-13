//
//  ExceroMessageViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 16.09.22.
//

import UIKit

class ExceroMessageViewController: UIViewController {
    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var usenameLabel: UILabel!
    @IBOutlet weak var userReportButton: SKUIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var messageView: UIView!
    
    private var storedMessage: String?
    private var chatVC: ChatViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            if let user = try await ResourcesManager.instance.getCurrentUser().value {
                var username: String?
                let conversationController = ConversationController(user: user)
                switch(user.lastExperimentalCondition?.acronym) {
                case "SEP":
                    let sep = await conversationController.getSEPPeer()
                    self.usenameLabel.text = sep?.name
                    username = sep?.name
                    break
                case "HUM":
                    let user = await conversationController.getUserPeer()
                    self.usenameLabel.text = user?.username
                    username = user?.username
                    break
                default:
                    self.usenameLabel.text = ""
                }
                self.loadPeerProfilePicture(username: username)
            }
        }
        
        self.containerView.layer.shadowColor = UIColor.black.cgColor
        self.containerView.layer.shadowOffset = CGSize(width:0, height: 3)
        self.containerView.layer.shadowOpacity = 0.3
        self.containerView.layer.shadowRadius = 2.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName())
        Task {
            if let user = try await ResourcesManager.instance.getCurrentUser().value {
                var username: String?
                let conversationController = ConversationController(user: user)
                switch(user.lastExperimentalCondition?.acronym) {
                case "SEP":
                    let sep = await conversationController.getSEPPeer()
                    self.usenameLabel.text = sep?.name
                    username = sep?.name
                    break
                case "HUM":
                    let user = await conversationController.getUserPeer()
                    self.usenameLabel.text = user?.username
                    username = user?.username
                    break
                default:
                    self.usenameLabel.text = ""
                }
                self.loadPeerProfilePicture(username: username)
            }
        }
    }
    
    
    @IBAction func onReportUserClicked(_ sender: Any) {
        if let chatVC = self.chatVC {
            chatVC.reportPeer()
        }
    }
    
    func setPredefinedMessage(message: String) {
        self.storedMessage = message
        if let chatVC = self.chatVC {
            if let msg = storedMessage {
                chatVC.setMessage(message: msg)
                return
            }
        }
        
    }
    
    func loadPeerProfilePicture(username: String?) {
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            ResourcesManager.logger.warning("ExceroMessageViewController.loadPeerProfilePicture could not find avatar folder.")
            return
        }
        let baseImage = UIImageView()
        let imageURL = URL(fileURLWithPath: directory.absoluteString).appendingPathComponent((username ?? "") + "." + Constants.PEER_AVATAR_SPRITE_PREVIEW)
        print(imageURL.absoluteString)
        baseImage.image = UIImage(fileURL: imageURL)
        /*baseImage.image = UIImage(contentsOfFile: URL(fileURLWithPath: directory.absoluteString).appendingPathComponent((self.usenameLabel.text ?? "") + "." + Constants.PEER_AVATAR_SPRITE_PREVIEW).absoluteString)*/
        guard let img = baseImage.image else {
            ResourcesManager.logger.warning("ExceroMessageViewController.loadPeerProfilePicture could not load peer avatar profile picture.")
            return
        }
        let height = (userIcon.frame.size.width * img.size.height) / img.size.width
        let newBaseImage = baseImage.image?.resize(size: CGSize(width: userIcon.frame.size.width, height: height))

        baseImage.image = newBaseImage
        baseImage.sizeToFit()
        baseImage.layer.position = CGPoint(x: 25, y: height/2)
        UIGraphicsBeginImageContextWithOptions(self.userIcon.frame.size, false, 0)
        let background = CGRect(x: 0, y: 0, width: userIcon.frame.size.width, height: userIcon.frame.size.height)
        ColorUtility.colorWithHexString(hexString: "aedde6").setFill()
        UIRectFill(background)
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let backgroundImageView = UIImageView(image: backgroundImage)
        self.userIcon.addSubview(backgroundImageView)
        self.userIcon.addSubview(baseImage)
        
        self.userIcon.layer.cornerRadius = 25
        self.userIcon.clipsToBounds = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "messageToSend" {
            guard let chatVC = segue.destination as? ChatViewController else {return}
            self.chatVC = chatVC
            if let msg = storedMessage {
                chatVC.setMessage(message: msg)
            }
            self.storedMessage = nil
        }
    }
    

}
