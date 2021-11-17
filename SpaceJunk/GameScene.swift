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
        playerNode.physicsBody?.categoryBitMask = PhysicsCatagory.Ship
        playerNode.physicsBody?.collisionBitMask = PhysicsCatagory.Debris
        playerNode.physicsBody?.contactTestBitMask = PhysicsCatagory.Debris
        
        physicsWorld.contactDelegate = self
        
        let spawnDebris = SKAction.run { self.spawnDebris() }
        
        let spawnStuff = SKAction.repeatForever(
            .sequence([spawnDebris,.wait(forDuration: 1)])
        )
        
        run(spawnStuff)
        run(playBackgroundMusic())

        addShipFireParticles()
        
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
    
    
    // MARK: Swapn debris
    func spawnDebris() {
        // Create the debris
        let debris = SKSpriteNode(imageNamed: self.getRandomeSprite())
        debris.name = "debris"
        
        // ADDING PHYSICS TO DEBRIS
        
        let debrisRadius = max(debris.size.width/2, debris.size.height/2)
        debris.physicsBody = SKPhysicsBody(circleOfRadius: debrisRadius)
        
        debris.physicsBody?.categoryBitMask = PhysicsCatagory.Debris
        debris.physicsBody?.collisionBitMask = PhysicsCatagory.Ship | PhysicsCatagory.Debris
        debris.physicsBody?.contactTestBitMask = PhysicsCatagory.Ship | PhysicsCatagory.Debris

        // positino them at top
        debris.position = self.setToTopWithRandomeXPoint()
        
        // add debris to acreen
        self.addChild(debris)
        
        // physics falling
        debris.physicsBody?.affectedByGravity = false
        let dy = (CGFloat.random(in: 100..<150) * -1)
        debris.physicsBody?.applyImpulse(CGVector(dx: 0, dy: dy))
        
        // physics spinning
        debris.physicsBody?.applyAngularImpulse(0.03)
        
       
        // TODO: Destroy debris when off screen
        
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

// MARK: PhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    /// getss called when 2 physics bodies start touching
    func didBegin(_ contact: SKPhysicsContact) {
        
        let shipMask = PhysicsCatagory.Ship
        let debrisMask = PhysicsCatagory.Debris
        
        let nodeA = contact.bodyA.node!
        let nodeB = contact.bodyB.node!
        
        let contactAMAsk = contact.bodyA.categoryBitMask
        let contactBMAsk = contact.bodyB.categoryBitMask
        
        let collision = contactAMAsk | contactBMAsk
        
        switch collision {
            
        /// if collision was between ship and debris
        case shipMask | debrisMask:
            print("ship collided with debris")
            
            // remove debris from parent
            if nodeA.name == "debris"{ nodeA.removeFromParent() }
            else { nodeB.removeFromParent() }
            
            // game over
            self.run(.group([ playExplosionSound(), SKAction.run(presentGameOverScene) ]))
            
        /// if collision was between debris and debris
        case debrisMask:
            print("Two debris's collided")
            
        default:
            break
        }
    }
    
    /// getss called when 2 physics bodies end touching
    func didEnd(_ contact: SKPhysicsContact) {
        return
    }
}



// MARK: Physics Model
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
