//
//  DuoScene.swift
//  excero
//
//  Created by Alessandro on 15.02.24.
//

import Foundation
import SpriteKit
import HealthKit

class DuoScene: AvatarDisplayScene {
    
    private let alert: UIAlertController = UIAlertController(title: "Information", message: "Il semblerait que ton/ta pair.e n'a pas encore créé son avatar, mais tu le/la verra bientôt apparaître à cette place.", preferredStyle: .alert)
    
    override func didMove(to view: SKView) {
        super.displayStepIndicator = true
        super.displayAvatarCustomization = false
        super.displayGoalCompletionIndicator = true
        super.displayPeerGoalCompletionIndicator = true
        super.didMove(to: view)
        self.alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: "DUO_PEER_AVATAR_VIEW")
    }
    
    func savePeerAvatarLocally(_ avatar: SKAvatar, username: String?) {
        if let avatarImage = avatar.toImage() {
            if let  directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL {
                do {
                    try avatarImage.pngData()!.write(to: directory.appendingPathComponent((username ?? "") + "." + Constants.PEER_AVATAR_SPRITE_PREVIEW)!)
                } catch {
                    ResourcesManager.logger.error("DuoScene.savePeerAvatarLocally could not save peer avatar. Detailed error \(error)")
                }
            }
        }
    }
    
    func getPeerAvatarLocally(username: String?) -> SKSpriteNode? {
        if let  directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL {
            guard let avatarPath = directory.appendingPathComponent((username ?? "") + "." + Constants.PEER_AVATAR_SPRITE_PREVIEW) else {
                ResourcesManager.logger.warning("DuoScene.getPeerAvatarLocally could not retrieve saved peer avatar, impossible to create avatar path.")
                return nil
            }
            if FileManager.default.fileExists(atPath: avatarPath.path) {
                guard let image = UIImage(fileURL: avatarPath) else { return nil }
                let texture = SKTexture(image: image)
                return SKSpriteNode(texture: texture)
            }
        }
        return nil
    }
    
    override func loadAvatar() {
        let avatarController = AvatarController(prioritizeLocalData: true)
        if let condition = ResourcesManager.instance.user?.lastExperimentalCondition {
            switch(ExperimentalConditionAcronyms(rawValue: condition.acronym)) {
            case .SEP:
                Task {
                    do {
                        if let user = try await ResourcesManager.instance.getCurrentUser().value {
                            if let sep = user.simulatedPeer, let sepModel = sep.model {
                                do {
                                    if let avatar = sepModel.avatar, let skAvatar = try await avatar.toSKAvatar(parentScene: self) {
                                        skAvatar.spawn()
                                        if let ratio = super.currentRatio {
                                            skAvatar.base.setScale(ratio.height)
                                        }
                                        self.savePeerAvatarLocally(skAvatar, username: sep.name)
                                    }
                                } catch {
                                    ResourcesManager.logger.error("DuoScene.loadAvatar could not load SEP avatar. Detailed error \(error)")
                                }
                            }
                        }
                    } catch {
                        ResourcesManager.logger.error("DuoScene.loadAvatar could not load current user when loading SEP avatar. Detailed error \(error)")
                        // -- MARK: Should go back to authentication.
                    }
                }
                break
            case .HUM:
                Task {
                    do {
                        if let user = try await ResourcesManager.instance.getCurrentUser().value {
                            let convController = ConversationController(user: user)
                            do {
                                let texture = SKTexture(image: UIImage(named: "human_avatar_placeholder")!)
                                var placeholder: SKSpriteNode? = SKSpriteNode(texture: texture)
                                placeholder?.position = .zero
                                placeholder?.size = CGSize(width: 173.3, height: 576)
                                placeholder?.zPosition = 100
                                placeholder?.alpha = 0.8
                                var isAvatarDisplayed: Bool = false
                                if let placeholder {
                                    self.scene?.addChild(placeholder)
                                }
                                
                                if let ratio = super.currentRatio, let placeholder {
                                    placeholder.setScale(ratio.height)
                                }
                                
                                if let peer = await convController.getUserPeer() {
                                    if let avatar = self.getPeerAvatarLocally(username: peer.username) {
                                        placeholder?.removeFromParent()
                                        placeholder = nil
                                        avatar.position = .zero
                                        avatar.size = CGSize(width: 173.3, height: 576)
                                        avatar.zPosition = 100
                                        self.scene?.addChild(avatar)
                                        if let ratio = super.currentRatio {
                                            avatar.setScale(ratio.height)
                                        }
                                        isAvatarDisplayed = true
                                    }
                                    if let peerAvatar = try await peer.avatar,
                                       let peerSKAvatar = try await peerAvatar.toSKAvatar(parentScene: self) {
                                        placeholder?.removeFromParent()
                                        if !isAvatarDisplayed {
                                            peerSKAvatar.spawn()
                                            if let ratio = super.currentRatio {
                                                peerSKAvatar.base.setScale(ratio.height)
                                            }
                                        }
                                        self.savePeerAvatarLocally(peerSKAvatar, username: peer.username)
                                    } else {
                                        self.view?.window?.rootViewController?.present(self.alert, animated: true, completion: nil)
                                    }
                                }
                            } catch {
                                ResourcesManager.logger.error("DuoScene.loadAvatar could not load Human peer avatar. Detailed error \(error)")
                            }
                        }
                    } catch {
                        ResourcesManager.logger.error("DuoScene.loadAvatar could not load current user when loading Human avatar. Detailed error \(error)")
                        // -- MARK: Should go back to authentication.
                    }
                }
                break
            default:
                break
            }
        }
    }
}
