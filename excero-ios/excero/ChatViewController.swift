//
//  ChatViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 13.09.22.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import InputBarAccessoryView
import MessageKit
import CryptoKit

class ChatViewController: MessagesViewController {
    
    private var channel: Channel
    private let dbFirestore: Firestore = Firestore.firestore()
    
    private var messages: [FirebaseMessage] = []
    
    private var messageCollectionRef: CollectionReference?
    private var chatListener: ListenerRegistration?
    
    private let dateFormatter: DateFormatter = DateFormatter()
    
    private var user: FirebaseAuth.User?
    
    private var currentUserHash: String
        
    private var authApi: AuthenticatedApiFacade?
    
    private var conversation: ConversationRepresentation?
    
    private var peerUser: UserRepresentation?
    private var peerSep: SimulatedPeerRepresentation?
    
    internal init() {
        self.authApi = AuthenticatedApiFacade()
        self.channel = Channel(name: "test-channel")
        self.currentUserHash = ""
        super.init(nibName: nil, bundle: nil)
        self.messagesCollectionView = MessagesCollectionView(frame: CGRect(x: 0, y: 102, width: 414, height: 794), collectionViewLayout: MessagesCollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.authApi = AuthenticatedApiFacade()
        self.channel = Channel(name: "test-channel")
        self.currentUserHash = ""
        super.init(coder: aDecoder)
        self.messagesCollectionView = MessagesCollectionView(frame: CGRect(x: 0, y: 102, width: 414, height: 794), collectionViewLayout: MessagesCollectionViewFlowLayout())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dateFormatter.dateFormat = "HH:mm"
        Task {
            var fbToken: FirebaseTokenCodable? = nil
            do {
                guard let firebaseToken = try await self.authApi?.get(endpointPath: "fb/token/", header: nil) else { return }
                let decoder = JSONDecoder()
                fbToken = try decoder.decode(FirebaseTokenCodable.self, from: firebaseToken)
            } catch {
                ResourcesManager.logger.error("ChatViewController.viewDidLoad could not retrieve firebase authentication token from backend. Detailed error: \(error)")
                // -- MARK: might need to get back to auth if the reason is the token.
            }
            if let fbToken {
                do {
                    let _ = try await Auth.auth().signIn(withCustomToken: fbToken.token)
                    self.user = Auth.auth().currentUser!
                } catch {
                    ResourcesManager.logger.error("ChatViewController.viewDidLoad could not authenticate user on Firebase. Detailed error: \(error)")
                    // -- MARK: lock send message part?
                }
            }
            
            if let user = try await ResourcesManager.instance.getCurrentUser().value {
                let conversationController = ConversationController(user: user)
                self.conversation = await conversationController.getConversation()
                if let conv = self.conversation, let documentPath = conv.documentPath {
                    self.messageCollectionRef = self.dbFirestore.collection(documentPath)
                } else {
                    ResourcesManager.logger.error("ChatViewController.viewDidLoad cannot create firebase CollectionReference as conversation or documentPath is empty.")
                    // -- MARK: lock send message part?
                }
                if let expCond = user.lastExperimentalCondition {
                    switch(expCond.acronym) {
                    case "SEP":
                        self.peerSep = await conversationController.getSEPPeer()
                        updateTitleView(title: "Chat avec \(self.peerSep?.name ?? "ton agent")", subtitle: "")
                        break
                    case "HUM":
                        self.peerUser = await conversationController.getUserPeer()
                        updateTitleView(title: "Chat avec \(self.peerUser?.username ?? "ton équipier")", subtitle: "")
                        break
                    default:
                        break
                    }
                }
                guard let channelDocumentPath = self.messageCollectionRef?.document().path else {
                    ResourcesManager.logger.warning("ChatViewController.viewDidLoad could not get Firebase document.")
                    return
                }
                self.channel = Channel(name: channelDocumentPath)
                self.chatListener = self.messageCollectionRef?.addSnapshotListener { [weak self] query, error in
                    guard let self = self else {
                        ResourcesManager.logger.warning("ChatViewController.viewDidLoad could not get self reference in document snapshotListener.")
                        return
                    }
                    guard let querySnapshot = query else {
                        ResourcesManager.logger.warning("ChatViewController.viewDidLoad could not receive query listener for Firebase document.")
                        return
                    }
                    querySnapshot.documentChanges.forEach { change in
                        self.handleNewMessage(change)
                    }
                    self.messages.sort()
                    self.messagesCollectionView.messagesDataSource = self
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                }
            }
        }
        self.removeUnreadNotifications()
        
        let sendImage = UIImage(named: "ui_send")?.withTintColor(UIColor.dynamicHEXColor(light: Constants.CHAT_SEND_ICON_LIGHT, dark: Constants.CHAT_SEND_ICON_DARK))
        self.messageInputBar.sendButton.image = sendImage?.resize(size: CGSize(width: 20, height: 20))
        self.messageInputBar.sendButton.title = ""
        
        if ResourcesManager.instance.networkAvailable {
            self.messageInputBar.inputTextView.isEditable = true
        } else {
            self.messageInputBar.inputTextView.isEditable = false
            self.messageInputBar.sendButton.isEnabled = false
            self.messageInputBar.inputTextView.text = "Tu n'es actuellement pas connecté"
        }
        
        if Constants.CHAT_SEP_LIMITED_ACCESS_MODE {
            self.setupSEPMode()
        }
        
        self.scrollsToLastItemOnKeyboardBeginsEditing = true

        self.messageInputBar.delegate = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDisplayDelegate = self
        self.messagesCollectionView.messagesDataSource = self
        self.messagesCollectionView.messageCellDelegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.messagesCollectionView.scrollToLastItem(animated: false)
    }
    
    private func removeUnreadNotifications() {
        ResourcesManager.instance.clearNotifications(withResourceType: "chat", removeBadges: true, storedCountName: "chat_badge_count")
    }
        
    private func setupSEPMode() {
        self.messageInputBar.inputTextView.isEditable = false
        self.messageInputBar.inputTextView.placeholder = "Clique ici pour sélectionner un message"
        let tapGestureRec = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        self.messageInputBar.inputTextView.addGestureRecognizer(tapGestureRec)
    }
    
    private func handleNewMessage(_ change: DocumentChange) {
        if change.type != .added {
            return
        }
        guard let message = FirebaseMessage(document: change.document) else {
            ResourcesManager.logger.warning("ChatViewController.handleNewMessage new message is nil.")
            return
        }
        
        self.addMessage(message: message)
    }
    
    private func addMessage(message: FirebaseMessage) {
        self.messages.append(message)
        self.messagesCollectionView.reloadData()
    }
    
    private func sendMessage(message: FirebaseMessage) {
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "SEND_MESSAGE")
        self.messageCollectionRef?.addDocument(data: message.representation) {_ in
            self.messagesCollectionView.scrollToLastItem()
        }
        Task {
            if let conversationUrl = self.conversation?.url {
                if let messageRepresentation = MessageRepresentation.fromFirebase(element: message, conversation: self.conversation) {
                    let _ = messageRepresentation.toCD()
                    let api = AuthenticatedApiFacade()
                    do {
                        let _ = try await api.post(fullUrl: conversationUrl + "messages/", data: messageRepresentation.toCodable(),
                                                   header: nil)
                    } catch {
                        ResourcesManager.logger.error("ChatViewController.sendMessage message could not be saved on backend. Detailed error: \(error)")
                    }
                }
            }
        }
    }
    
    @objc func hideKeyboard() {
        self.messageInputBar.endEditing(true)
        ResourcesManager.instance.registerUserEvent(action: .FIELD_TYPE, target: "HIDE_KEYBOARD")
    }
    
    @objc func didTapView() {
        let pickerViewController = UIViewController()
        pickerViewController.preferredContentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height/2)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width,
                                                    height: self.view.frame.size.height/2))
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(0, inComponent: 0, animated: false)
        pickerViewController.view.addSubview(pickerView)
        pickerView.centerXAnchor.constraint(equalTo: pickerViewController.view.centerXAnchor).isActive = true
        pickerView.centerYAnchor.constraint(equalTo: pickerViewController.view.centerYAnchor).isActive = true
        
        let alertView = UIAlertController(title: "Sélectionne un message à envoyer à \("Test")", message: "", preferredStyle: .actionSheet)
        alertView.popoverPresentationController?.sourceView = self.messageInputBar.inputTextView
        alertView.popoverPresentationController?.sourceRect = self.messageInputBar.inputTextView.bounds
        alertView.setValue(pickerViewController, forKey: "contentViewController")
        alertView.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        alertView.addAction(UIAlertAction(title: "Sélectionner", style: .default, handler: { action in
            //self.messageInputBar.inputTextView.text = self.definedMessages[pickerView.selectedRow(inComponent: 0)]
        }))
        self.present(alertView, animated: true, completion: nil)
    }
    
    func setMessage(message: String) {
        self.messageInputBar.inputTextView.text = message
    }
    
    func reportPeer() {
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "REPORT_USER")
        if let peerUser = self.peerUser {
            let bundle = [ReportUserViewController.DATA_BUNDLE_REPORTED_USER_KEY: peerUser]
            self.displayViewControllerAsSheet(viewControllerName: "ReportUser", data: bundle) { _ in
                ResourcesManager.logger.info("ChatViewController.reportPeer user has reported another user, sheet has been closed at least.")
            }
        }
    }
    
}

extension ChatViewController: MessagesLayoutDelegate {
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 10
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    func messageBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        if isFromCurrentSender(message: message) {
            return LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 10))
        } else {
            return LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 0))
        }
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize? {
        return CGSize(width: 0, height: 0)
    }
    
}


extension ChatViewController: MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: "à \(dateFormatter.string(from: message.sentDate))", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapBackground(in cell: MessageCollectionViewCell) {
        self.messageInputBar.inputTextView.resignFirstResponder()
    }
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return UIColor.dynamicHEXColor(light: Constants.CHAT_BUBBLE_COLOR_AUTHOR_LIGHT, dark: Constants.CHAT_BUBBLE_COLOR_AUTHOR_DARK)
        } else {
            return UIColor.dynamicHEXColor(light: Constants.CHAT_BUBBLE_COLOR_PEER_LIGHT, dark: Constants.CHAT_BUBBLE_COLOR_PEER_DARK)
        }
    }

}

extension ChatViewController: MessagesDataSource {
    var currentSender: SenderType {
        var userHash: String
        if let user = ResourcesManager.instance.user, let usernameHash = user.usernameHash {
            userHash = usernameHash
        } else {
            userHash = ""
        }
        return Sender(senderId: userHash, displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        var userHash: String
        if let user = ResourcesManager.instance.user, let usernameHash = user.usernameHash {
            userHash = usernameHash
        } else {
            userHash = ""
        }
        let message = FirebaseMessage(userHash: userHash, content: text)
        sendMessage(message: message)
        inputBar.inputTextView.text = ""
    }
}

extension ChatViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //label.text = self.definedMessages[row]
        label.sizeToFit()
        return label
    }
}

extension ChatViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //return self.definedMessages.count
        return 0
    }
}

