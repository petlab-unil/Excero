//
//  ChatView.swift
//  excero
//
//  Created by Alessandro Silacci on 16.09.22.
//

import Foundation
import MessageKit
import FirebaseAuth
class ChatView: MessagesCollectionView {
    
    private var messages: [FirebaseMessage] = []
    private var user: FirebaseAuth.User
    
    
    internal init() {
        self.user = Auth.auth().currentUser!
        super.init(frame: CGRect(x: 0, y: 102, width: 414, height: 794), collectionViewLayout: MessagesCollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.user = Auth.auth().currentUser!
        super.init(coder: aDecoder)
        self.frame = CGRect(x: 0, y: 102, width: 414, height: 794)
    }
    
    func addMessage(message: FirebaseMessage) {
        print("added message")
        print(self.frame.size)
        self.messages.append(message)
        self.reloadData()
    }
}

extension ChatView: MessagesDataSource {
    var currentSender: SenderType {
        return Sender(senderId: user.uid, displayName: user.email!)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
}
