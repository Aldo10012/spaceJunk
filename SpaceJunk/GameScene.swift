//
//  GameScene.swift
//  SpaceJunk
//
//  Created by Alberto Dominguez on 10/20/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: Properties
    var screenHeight: CGFloat = 0
    var screenWidth: CGFloat = 0
    
    var playerNode = SKNode()
    let thrusterFlame = SKEmitterNode(fileNamed: "thrusterFlame.sks")!

    
    
    // MARK: Life Cycle
    
    /// Called when scene loads, gets called once (like ViewDidLoad)
    override func didMove(to view: SKView) {
        screenHeight = size.height
        screenWidth = size.width
        playerNode = childNode(withName: "player")!
        
        let spawnDebris = SKAction.run { self.spawnDebris() }
        
        let spawnStuff = SKAction.repeatForever(
            .sequence([spawnDebris,.wait(forDuration: 1)])
        )
        
        run(spawnStuff)
        run(playBackgroundMusic())

        addShipFireParticles()
        
    }
    
    /// Called before each frame is rendered (60x per second )
    override func update(_ currentTime: TimeInterval) {
        checkIfPlayerHasCollidedWithAstroid()
    }
    
    /// Called when user touches screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            let touchLocation = touch.location(in: self)
            
            if touchLocation.x < (playerNode.position.x) {
                // Left side of the screen
                
                let vector: CGVector = CGVector(dx: -50, dy: 0)
                let duration: TimeInterval = 0.5
                
                playerNode.run(.move(by: vector, duration: duration))
                thrusterFlame.run(.move(by: vector, duration: duration))
            } else {
                // Right side of the screen
                
                let vector: CGVector = CGVector(dx: 50, dy: 0)
                let duration: TimeInterval = 0.5
                
                playerNode.run(.move(by: vector, duration: duration))
                thrusterFlame.run(.move(by: vector, duration: duration))
            }
        }
                
        
    }
    /// Called when user drags finger on screen
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let playerNode = childNode(withName: "player")!
        
        for touch in touches{
            let touchLocation = touch.location(in: self)
            
            let mvoePlayer = SKAction.moveTo(x: touchLocation.x, duration: 0.25)
            playerNode.run(mvoePlayer)
            thrusterFlame.run(mvoePlayer)
        }
    }
    
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        
    }
    
    
    // MARK: Helpers
    func getRandomeSprite() -> String {
        return [
            "meteorBrown_big3",
            "meteorGrey_big4",
            "meteorGrey_med1",
            "wingGreen_6",
            "wingRed_2"
        ].randomElement() as! String
    }
    
    
    
    func getRandomeXPoint() -> CGFloat{
        return CGFloat.random(in: 0...screenWidth)
    }
    
    func setToTopWithRandomeXPoint() -> CGPoint {
        return CGPoint(x: getRandomeXPoint(), y: screenHeight)
    }
    
    func backToTop() -> SKAction {
        return SKAction.move(to: self.setToTopWithRandomeXPoint(), duration: 0)
    }
    
    func debrisFallingAndSpinning(duration: TimeInterval) -> SKAction {
        let vector = CGVector(dx: 0, dy: -(screenHeight+50))
        let debrisFalling = SKAction.move(by: vector, duration: duration)
        let rotationAction = SKAction.rotate(byAngle: .pi * 2, duration: duration)
        
        let debrisFallingAndSpinning = SKAction.group([
            debrisFalling,
            rotationAction
        ])
        
        return debrisFallingAndSpinning
    }
    
    func movePlayerOnTouch() {
         // TODO: move layer left or right depending on where u touch
    }
    
    // MARK: Swapn debris
    func spawnDebris() {
        // Create the debris
        let debris = SKSpriteNode(imageNamed: self.getRandomeSprite())
        debris.name = "debris"

        // positino them at top
        debris.position = self.setToTopWithRandomeXPoint()

        // add debris to acreen
        self.addChild(debris)
        

        // add action to move down add spin
        let debrisFallingAndSpinning = self.debrisFallingAndSpinning(duration: .random(in: 2...5))
        
        let destroy = SKAction.removeFromParent()
        
        debris.run(
            .repeatForever(
                .sequence([debrisFallingAndSpinning, destroy])
            )
        )
    }
    
    // MARK: Collision
    func checkIfPlayerHasCollidedWithAstroid() {
        // TODO: check if player has touched astroid. If so, destroy debris. (present Game Over scene)
        
        enumerateChildNodes(withName: "debris") { debrisNode, _ in
            let debrisFrame = debrisNode.frame
            
            let playerNode = self.childNode(withName: "player")!
            let playerFrame = playerNode.frame
            
            let doesDebrisIntersectWithPlayer = debrisFrame.intersects(playerFrame)
            
            if doesDebrisIntersectWithPlayer {
                debrisNode.removeFromParent()
                self.run(self.playExplosionSound())
                self.presentGameOverScene()
            }
        }
        
    }
    
    // MARK: Game Over
    func presentGameOverScene() {
        let gameOverScene = SKScene(fileNamed: "GameOver")
        gameOverScene?.scaleMode = .aspectFill
        view?.presentScene(gameOverScene)
    }
    
    
    // MARK: Audio
    func playBackgroundMusic() -> SKAction {
        let backgroundSound = SKAction.playSoundFileNamed("backgroundSound.wav", waitForCompletion: true)
        return SKAction.repeatForever(backgroundSound)
    }
    
    func playExplosionSound() -> SKAction {
        let explosionSound = SKAction.playSoundFileNamed("explosionSound.wav", waitForCompletion: true)
        return explosionSound
    }
    
    // MARK: Particles
    func addShipFireParticles() {
        var playerPosition = childNode(withName: "player")?.position
        playerPosition?.y -= 50
        thrusterFlame.position = playerPosition!
        addChild(thrusterFlame)
    }
    
    
}

/// This creates the CatagoryBitMask
/// its like an identifier for each object type
/// if two objects have a 1 on the save column, they can colide
/// 0001 and 0010 can't collide
/// 0001 and 0011 can collide
struct PhysicsCatagory {
    static let None:    UInt32 = 0       // 0000000 0
    static let Ship:    UInt32 = 0b1     // 0000001 1
    static let Debris:  UInt32 = 0b10    // 0000010 2
    static let Edge:    UInt32 = 0b100   // 0000100 4
}

/// This creates the ContactBitMask, allowing objects to make contaqct with other objects depending on their PhysicdCatagory bit mask
struct PhysicsContact {
    static let None:    UInt32 = 0       // 0000000 0   Doesn't make contact with anything
    static let Ship:    UInt32 = 0b10    // 0000010 2   Ship can collide with debris
    static let Debris:  UInt32 = 0b11    // 0000011 3   Debris can collide with ship and other debris
    static let Edge:    UInt32 = 0b10    // 0000010 2   Edge can collide with debris
}
