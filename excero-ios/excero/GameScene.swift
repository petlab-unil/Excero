//
//  GameScene.swift
//  excero
//
//  Created by Alessandro Silacci on 20.07.22.
//

import SpriteKit
import GameplayKit

class GameScene: EmbeddedSKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private var baseSpriteNode: SKAvatar?
    private var scale = 1.0;
    
    private var safeArea: SafeAreaInsets {
        guard let view = self.view else { return .zero }
        let halfedWidth = view.bounds.width/2
        let halfedHeight = view.bounds.height/2
        return SafeAreaInsets(top: halfedHeight - view.safeAreaInsets.top,
                              bottom: (-1 * halfedHeight) + view.safeAreaInsets.bottom,
                              left: (-1 * halfedWidth) + view.safeAreaInsets.left,
                              right: halfedWidth - view.safeAreaInsets.right)
    }
    
    private var avatarBasePieces: [SKAvatarPiece] = []
    private var avatarHairPieces: [SKAvatarPiece] = []
    private var avatarHeadPieces: [SKAvatarPiece] = []
    private var avatarShirtPieces: [SKAvatarPiece] = []
    private var avatarTrousersPieces: [SKAvatarPiece] = []
    private var avatarShoesPieces: [SKAvatarPiece] = []
    
    private var avatarPieces: [AvatarPieceGroup: [AvatarPieceRepresentation]] = [:]
    
    private var buttonPrevious: SKSpriteNode?
    private var buttonNext: SKSpriteNode?
    
    private var pieceIndex: Int = 0
    private var defaultDimensions: CGSize = CGSize(width: 428, height: 926)
    private var currentRatio: CGSize?
    
    private var controls: Dictionary<String, () -> Void> = Dictionary()
    
    private var customizers: Dictionary<AvatarPieceGroup, AvatarPieceChooser> = Dictionary()
    private var colorSwatches: [[UIColor]] = [[UIColor]]()
    
    private var progressIndicatorView: UIShapeableProgressView?
    
    private var loadingView: UILoadingView?
    
    private var selectedAvatarType: AvatarTypeRepresentation?
    
    private let avatarController: AvatarController = AvatarController()
    
    private var api: AuthenticatedApiFacade = AuthenticatedApiFacade()
    
    private var isInTypeChooseMode: Bool = true
    
    private var validateButton: SKUIButton?
    
    override func willMove(from view: SKView) {
        self.removeAllActions()
        self.removeAllChildren()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        self.currentRatio = CGSize(width: self.view!.bounds.width/self.defaultDimensions.width,
                                   height: self.view!.bounds.height/self.defaultDimensions.height)
        let bg = SKSpriteNode(imageNamed: "ui_editscreenbg")
        bg.size = CGSize(width: self.view!.bounds.width, height: self.view!.bounds.height)
        bg.zPosition = -10
        self.addChild(bg)
        let frameSize = CGSize(width: 250.0, height: 150.0)
        let progressSize = CGSize(width: 50.0, height: 50.0)
        let frame = CGRect(x: view.frame.size.width/2 - frameSize.width/2, y: view.frame.size.height/2 - frameSize.height/2, width: frameSize.width, height: frameSize.height)
        self.loadingView = UILoadingView(frame: frame)
        self.progressIndicatorView = UIShapeableProgressView(frame: CGRect(x: frameSize.width / 2, y: 50, width: progressSize.width, height: progressSize.height))
        if let indicator = self.progressIndicatorView {
            indicator.trackTintColor = .gray
            indicator.progressTintColor = UIColor.dynamicHEXColor(light: Constants.DEFAULT_PRIMARY_COLOR_LIGHT, dark: Constants.DEFAULT_PRIMARY_COLOR_DARK)
            indicator.pathWidth = 10.0
            self.loadingView?.loadingIndicatorView = indicator
            self.loadingView?.loadingText = "Chargement des éléments de l'avatar"
            self.view?.addSubview(self.loadingView!)
        }
        if let defaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME) {
            self.isInTypeChooseMode = defaults.string(forKey: Constants.USER_DEFAULTS_SAVED_AVATAR_TYPE) == nil
        }
        self.switchCustomizationMode(self.isInTypeChooseMode, view: view)
    }
    
    func switchCustomizationMode(_ typeSelection: Bool, view: SKView) {
        for customizer in self.customizers.values {
            customizer.removeControls()
        }
        let headingLabel: String = typeSelection ? "Choisis ton type d'avatar" : "Personnalise ton avatar"
        if let label = self.label {
            label.text = headingLabel
        } else {
            let font = UIFont.preferredFont(forTextStyle: .largeTitle)
            self.label = SKLabelNode(text: headingLabel)
            self.label?.fontSize = font.pointSize
            self.label?.zPosition = 100
            self.label?.fontColor = UIColor.dynamicHEXColor(light: Constants.DEFAULT_TEXT_COLOR_LIGHT, dark: Constants.DEFAULT_TEXT_COLOR_DARK)
            self.label?.fontName = font.fontName.replacingOccurrences(of: ".", with: "")
            self.label?.position = CGPoint(x: self.safeArea.left + (self.label!.frame.width / 2) + 10 * (self.currentRatio?.width ?? 1.0), y: self.safeArea.top - self.label!.frame.height - 10.0)
            self.addChild(self.label!)
        }
        if typeSelection {
            ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: "AVATAR_PERSONALIZATION_GENDER")
            if let base = self.baseSpriteNode {
                base.removeFromScene()
            }
            spawn(ratio: self.currentRatio!)
            Task {
                do {
                    if let types = await self.avatarController.getAvatarTypes() {
                        try await self.setupBodyTypeSelectionMode(types, filter: "human")
                        self.loadingView?.removeFromSuperview()
                    }
                } catch {
                    ResourcesManager.logger.error("GameScene.switchCustomizationMode error while switching to body type selection mode. Detailed error: \(error)")
                }
            }
        } else {
            ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: "AVATAR_PERSONALIZATION_CLOTHES")
            let avatarChangeType = SKUIButton(imageName: "ui_gender_select", size: CGSize(width: 30, height: 30),
                                              position: CGPoint(x: self.safeArea.right - 30,
                                                                y: self.safeArea.top - 60)) { () in
                self.isInTypeChooseMode = true
                self.switchCustomizationMode(self.isInTypeChooseMode, view: view)
            }
            avatarChangeType.zPosition = 1000
            self.addChild(avatarChangeType)
            Task {
                if let defaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME),
                    let avatarTypeURL = defaults.string(forKey: Constants.USER_DEFAULTS_SAVED_AVATAR_TYPE),
                    let type = await self.avatarController.getAvatarTypeWithURL(url: avatarTypeURL) {
                    self.selectedAvatarType = type
                    if let pieces = await self.avatarController.getAvatarPiecesWithType(type: type) {
                        self.avatarPieces = pieces
                        if self.baseSpriteNode == nil {
                            do {
                                if let baseRep = self.avatarPieces[.BODY]?.first,
                                    let base = try await baseRep.toSKAvatarPiece(parentScene: self) {
                                    if let currentRatio = self.currentRatio {
                                        base.setScale(currentRatio.height)
                                    }
                                    self.baseSpriteNode = SKAvatar(base: base,
                                                                   head: nil,
                                                                   hairs: nil,
                                                                   shirt: nil,
                                                                   trousers: nil,
                                                                   shoes: nil,
                                                                   parentScene: self)
                                    
                                    var insetsCorrection: CGFloat = 0
                                    if let view = self.view {
                                        insetsCorrection = -1 * view.safeAreaInsets.top
                                    }
                                    self.baseSpriteNode?.spawn(basePosition: CGPoint(x: 0, y: insetsCorrection))
                                }
                            } catch {
                                ResourcesManager.logger.error("GameScene.switchCustomizationMode could not get base sprite avatar for selected type. Detailed error: \(error)")
                            }
                        } else {
                            self.baseSpriteNode?.spawn(basePosition: CGPoint(x: 0, y: -1 * self.view!.safeAreaInsets.top))
                        }

                    }
                }
                fillColorSwatches()
                spawn(ratio: self.currentRatio!)
                await prepareControls(view: view)
                self.loadingView?.removeFromSuperview()
            }
        }
    }
    
    func fillColorSwatches() {
        if self.colorSwatches.count == 0 {
            self.colorSwatches.append([UIColor.fromHex(hexString: "FBBA94"), UIColor.fromHex(hexString: "F8A279")])
            self.colorSwatches.append([UIColor.fromHex(hexString: "FBC0A5"), UIColor.fromHex(hexString: "F4AB89")])
            self.colorSwatches.append([UIColor.fromHex(hexString: "FCCAB4"), UIColor.fromHex(hexString: "F4AF93")])
            self.colorSwatches.append([UIColor.fromHex(hexString: "995B4E"), UIColor.fromHex(hexString: "8D4D3F")])
        }
    }
    
    func prepareControls(view: SKView) async {
        for pieceGroup in self.avatarPieces.keys {
            if pieceGroup == .BODY { continue }
            guard let pieces = self.avatarPieces[pieceGroup] else { continue }
            var skPieces: [SKAvatarPiece] = []
            for piece in pieces {
                do {
                    if let skPiece = try await piece.toSKAvatarPiece(parentScene: self) {
                        skPieces.append(skPiece)
                    }
                } catch {
                    ResourcesManager.logger.error("GameScene.prepareControls avatar piece conversion failed. Detailed error: \(error)")
                }
            }
            if skPieces.count == 0 { continue }
            let customizer = AvatarPieceChooser(avatarPieces: skPieces, position: CGPoint(x: view.bounds.width/2,
                                                                                          y: (self.baseSpriteNode!.getBasePosition().y + skPieces[0].getRelativePosition().y) * self.scale),
                                                parentScene: self, avatar: self.baseSpriteNode!,
                                                ratio: self.currentRatio!,
                                                scale: self.scale, startPosition: CGPoint(x: -1 * ((self.size.width/2) + 50), y: 0),
                                                endPosition: CGPoint(x: (self.size.width/2) + 50, y: 0),
                                                previousSpriteName: nil, nextSpriteName: nil, pieceZPosition: 200)
            
            if let nextCommand = customizer.getNextID() {
                self.controls[nextCommand] = customizer.callNext
            }
            if let previousCommand = customizer.getPreviousID() {
                self.controls[previousCommand] = customizer.callPrevious
            }
            customizer.spawnControls()
            self.customizers[pieceGroup] = customizer
        }
        if !self.isInTypeChooseMode {
            let swatches = SKNode()
            let positionIncrement = 60
            var startPosition = -1 * ((colorSwatches.count-1) * positionIncrement / 2)
            let horizontal = true
            for colorSwatch in self.colorSwatches {
                let chooser = UIGradientColorPicker(colorSwatches: colorSwatch, horizontal: horizontal) { swatch in
                    self.bodyTintSelectionCallback(colorSwatch: swatch)
                }
                if horizontal {
                    chooser.position = CGPoint(x: startPosition, y: 0)
                } else {
                    chooser.position = CGPoint(x: 0, y: startPosition)
                }
                
                swatches.addChild(chooser)
                startPosition += positionIncrement
            }
            var labelMargin: CGFloat = 0
            if let label = self.label {
                labelMargin = label.position.y - label.frame.height
            }
            swatches.position = CGPoint(x: 0, y: (labelMargin - (swatches.frame.height) - 20.0))
            self.addChild(swatches)
        }
    }
    
    func spawn(ratio: CGSize) {
        let avatarModelController = ModelController<Avatar>()
        var validateXPosition: CGFloat = 0
        if let _ = avatarModelController.getLast() {
            let cancelButton = SKUIButton(color: "#b3b3b3",
                                          text: "Annuler",
                                          size: CGSize(width: 100, height: 50),
                                          position: CGPoint(x: (self.safeArea.left + 100) * ratio.width, y: self.safeArea.bottom * ratio.height),
                                          cornerRadius: 10,
                                          callback: self.buttonCancelCallback)
            if let currentRatio = self.currentRatio {
                cancelButton.setScale(currentRatio.height)
            }
            cancelButton.zPosition = 900
            self.addChild(cancelButton)
            validateXPosition = self.safeArea.right - 100
        }
        self.validateButton = SKUIButton(color: "#008DA5",
                                      text: "Valider",
                                      size: CGSize(width: 100, height: 50),
                                      position: CGPoint(x: (validateXPosition) * ratio.width, y: self.safeArea.bottom * ratio.height),
                                      cornerRadius: 10,
                                      callback: self.buttonValidateCallback)
        if let currentRatio = self.currentRatio {
            validateButton?.setScale(currentRatio.height)
        }
        validateButton?.zPosition = 900
        if let validateButton = self.validateButton {
            self.addChild(validateButton)
        }
        
       
    }
        
    func buttonCancelCallback() -> Void {
        super.goToView(viewName: "MainScene")
        ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "CANCEL_PERSONALIZATION")
    }
    
    func buttonValidateCallback() -> Void {
        if !self.isInTypeChooseMode {
            self.validateButton?.disabled = true
            ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "VALIDATE_CLOTHES")
            guard let avatar = self.baseSpriteNode else { return }
            avatar.hairs = self.customizers[.HAIRS]?.getCurrentSelection()
            avatar.head = self.customizers[.HEAD]?.getCurrentSelection()
            avatar.shirt = self.customizers[.TOP]?.getCurrentSelection()
            avatar.trousers = self.customizers[.LEGS]?.getCurrentSelection()
            avatar.shoes = self.customizers[.SHOES]?.getCurrentSelection()
            guard let avatarRepresentation = AvatarRepresentation.fromSKAvatar(avatar) else { return }
            avatarRepresentation.type = self.selectedAvatarType?.url
            Task {
                do {
                    if let user = try await ResourcesManager.instance.getCurrentUser().value {
                        let result = await self.avatarController.createAvatar(avatarRepresentation, user: user)
                        if ResourcesManager.instance.networkAvailable {
                            let _ = result?.toCDAvatar(isSelf: true)
                        }
                        switch(user.lastExperimentalCondition?.acronym) {
                        case ExperimentalConditionAcronyms.BASE.rawValue:
                            break
                        case ExperimentalConditionAcronyms.SEP.rawValue, ExperimentalConditionAcronyms.HUM.rawValue:
                            super.goToView(viewName: "DuoScene")
                            break
                        case ExperimentalConditionAcronyms.CON.rawValue:
                            super.goToView(viewName: "MainScene")
                            break
                        default:
                            break
                        }
                    }
                } catch {
                    ResourcesManager.logger.error("GameScene.buttonValidateCallback could not retrieve current user while saving avatar. Detailed error: \(error)")
                    // -- MARK: Should go back to authentication view.
                }
            }
        } else {
            ResourcesManager.instance.registerUserEvent(action: .BTN_CLICK, target: "VALIDATE_GENDER")
            if let customizer = self.customizers[.BODY] {
                self.baseSpriteNode = SKAvatar(base: customizer.getCurrentSelection(), head: nil, hairs: nil,
                                               shirt: nil, trousers: nil, shoes: nil, parentScene: self)
                customizer.removeControls()
                self.customizers.removeValue(forKey: .BODY)
                self.isInTypeChooseMode = false
                self.selectedAvatarType = customizer.getCurrentMetadata() as? AvatarTypeRepresentation
                if let defaults = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME) {
                    defaults.set(self.selectedAvatarType?.url, forKey: Constants.USER_DEFAULTS_SAVED_AVATAR_TYPE)
                }
                Task {
                    if let selectedAvatarType = self.selectedAvatarType,
                       let pieces = await self.avatarController.getAvatarPiecesWithType(type: selectedAvatarType) {
                        self.avatarPieces = pieces
                        self.switchCustomizationMode(self.isInTypeChooseMode, view: self.view!)
                    }
                }
            }
            
        }
    }
    
    func setupBodyTypeSelectionMode(_ types: [AvatarTypeRepresentation], filter: String? = nil) async throws {
        var bodyReps: [AvatarPieceRepresentation] = []
        var bodyTypeMetadata: [AvatarTypeRepresentation] = []
        for type in types {
            if let filter {
                if let name = type.name, name.contains(filter),
                   let groupedPieces = await self.avatarController.getAvatarPiecesWithType(type: type),
                    let pieces = groupedPieces[.BODY] {
                        bodyReps.append(contentsOf: pieces)
                        for _ in 0..<pieces.count {
                            bodyTypeMetadata.append(type)
                        }
                }
            } else {
                if let groupedPieces = await self.avatarController.getAvatarPiecesWithType(type: type),
                   let pieces = groupedPieces[.BODY] {
                    bodyReps.append(contentsOf: pieces)
                    for _ in 0..<pieces.count {
                        bodyTypeMetadata.append(type)
                    }
                }
            }
        }
        var bodies: [SKAvatarPiece] = []
        if bodyReps.count > 0 {
            for i in 0..<bodyReps.count {
                let bodyRep = bodyReps[i]
                if let converted = try await bodyRep.toSKAvatarPiece(parentScene: self) {
                    bodies.append(converted)
                } else {
                    bodyTypeMetadata.remove(at: i)
                }
            }
        }
        // -- MARK: if bodies is nil here, it means the user has never used the app with the internet, we should show a message.
        let customizer = AvatarPieceChooser(avatarPieces: bodies, position: CGPoint(x: self.view!.bounds.width/2, y: ( bodies[0].getRelativePosition().y * self.scale)), parentScene: self, ratio: self.currentRatio!, scale: self.scale, startPosition: CGPoint(x: -1 * ((self.size.width/2) + 50), y: 0), endPosition: CGPoint(x: (self.size.width/2) + 50, y: 0), previousSpriteName: nil, nextSpriteName: nil, pieceZPosition: 200, additionalMetadata: bodyTypeMetadata)
        customizer.spawnControls()
        self.customizers[.BODY] = customizer
        if let nextCommand = customizer.getNextID() {
            self.controls[nextCommand] = customizer.callNext
        }
        if let previousCommand = customizer.getPreviousID() {
            self.controls[previousCommand] = customizer.callPrevious
        }
    }
    
    func bodyTintSelectionCallback(colorSwatch: [UIColor]) -> Void {
        self.baseSpriteNode?.base.color = colorSwatch[0]
        self.baseSpriteNode?.base.colorBlendFactor = 0.7
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
       
    }
    
    func touchUp(atPoint pos : CGPoint) {
        let node = self.atPoint(pos)
        if let name = node.name {
            if let controlFunction: () -> Void = self.controls[name] {
                controlFunction()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
