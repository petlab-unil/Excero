//
//  Message.swift
//  excero
//
//  Created by Alessandro Silacci on 13.09.22.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import MessageKit
import CryptoKit

struct FirebaseMessage: MessageType {
  let id: String?
  var messageId: String {
    return id ?? UUID().uuidString
  }
  let content: String
  let sentDate: Date
  let sender: SenderType
  var kind: MessageKind {
      return .text(content)
  }

  var image: UIImage?
  var downloadURL: URL?

    init(user: FirebaseAuth.User, content: String) {
    sender = Sender(senderId: user.uid, displayName: "A good user")
    self.content = content
    sentDate = Date() //NSDate().timeIntervalSince1970
    id = nil
  }
    
    init(userHash: String, content: String) {
        sender = Sender(senderId: userHash, displayName: "App User")
        self.content = content
        sentDate = Date()
        id = nil
    }

    init(user: FirebaseAuth.User, image: UIImage) {
    sender = Sender(senderId: user.uid, displayName: "A good user")
    self.image = image
    content = ""
    sentDate = Date() //NSDate().timeIntervalSince1970
    id = nil
  }

  init?(document: QueryDocumentSnapshot) {
    let data = document.data()
    guard
      let sentDate = data["created"] as? Timestamp,
      let senderId = data["senderId"] as? String
    else {
      return nil
    }

    id = document.documentID

    self.sentDate = sentDate.dateValue()
    sender = Sender(senderId: senderId, displayName: "")

    if let content = data["content"] as? String {
      self.content = content
      downloadURL = nil
    } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
      downloadURL = url
      content = ""
    } else {
      return nil
    }
  }
}

// MARK: - DatabaseRepresentation
extension FirebaseMessage: DatabaseRepresentation {
  var representation: [String: Any] {
    var rep: [String: Any] = [
      "created": sentDate,
      "senderId": sender.senderId,
      "senderName": sender.displayName
    ]

    if let url = downloadURL {
      rep["url"] = url.absoluteString
    } else {
      rep["content"] = content
    }

    return rep
  }
}

// MARK: - Comparable
extension FirebaseMessage: Comparable {
  static func == (lhs: FirebaseMessage, rhs: FirebaseMessage) -> Bool {
    return lhs.id == rhs.id
  }

  static func < (lhs: FirebaseMessage, rhs: FirebaseMessage) -> Bool {
    return lhs.sentDate < rhs.sentDate
  }
}
