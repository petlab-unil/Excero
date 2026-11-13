//
//  MainScene.swift
//  excero
//
//  Created by Alessandro Silacci on 25.08.22.
//

import Foundation
import SpriteKit
import HealthKit

class MainScene: AvatarDisplayScene {
    
    private let avatarController: AvatarController = AvatarController(prioritizeLocalData: true)
    
    override func didMove(to view: SKView) {
        super.displayStepIndicator = true
        super.displayAvatarCustomization = false
        super.displayGoalCompletionIndicator = true
        super.displayPeerGoalCompletionIndicator = false
        super.didMove(to: view)
        
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: "USER_AVATAR_VIEW")
    }
    
    func saveAvatarLocally(_ avatar: SKAvatar, username: String?) {
        if let avatarImage = avatar.toImage() {
            if let  directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL {
                do {
                    try avatarImage.pngData()!.write(to: directory.appendingPathComponent((username ?? "") + "." + Constants.USER_AVATAR_SPRITE_PREVIEW)!)
                } catch {
                    ResourcesManager.logger.error("MainScene.savePeerAvatarLocally could not save peer avatar. Detailed error \(error)")
                }
            }
        }
    }
    
    func getAvatarLocally(username: String?) -> SKSpriteNode? {
        if let  directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL {
            guard let avatarPath = directory.appendingPathComponent((username ?? "") + "." + Constants.USER_AVATAR_SPRITE_PREVIEW) else {
                ResourcesManager.logger.warning("MainScene.getPeerAvatarLocally could not retrieve saved peer avatar, impossible to create avatar path.")
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
        Task {
            do {
                if let user = try await ResourcesManager.instance.getCurrentUser().value {
                    do {
                        /*if let localAvatar = self.getAvatarLocally(username: user.username) {
                            localAvatar.position = .zero
                            localAvatar.size = CGSize(width: 173.3, height: 576)
                            localAvatar.zPosition = 100
                            self.scene?.addChild(localAvatar)
                            if let ratio = super.currentRatio {
                                localAvatar.setScale(ratio.height)
                            }
                        } else {*/
                            let avatar = try await self.avatarController.getAvatar(user: user)?.toSKAvatar(parentScene: self, forceLocal: true)
                            if let avatar {
                                avatar.spawn()
                                if let ratio = super.currentRatio {
                                    avatar.base.setScale(ratio.height)
                                }
                                self.saveAvatarLocally(avatar, username: user.username)
                            } else {
                                self.openAvatarCustomization()
                            }
                        //}
                    } catch {
                        ResourcesManager.logger.error("MainScene.loadAvatar could not load and convert current user avatar. Detailed error: \(error)")
                    }
                }
            } catch {
                ResourcesManager.logger.error("MainScene.loadAvatar could not load user information. Detailed error: \(error)")
                // -- MARK: Should go back to authentication.
            }
        }
    }
}
