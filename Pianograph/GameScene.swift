//
//  GameScene.swift
//  Pianograph
//
//  Created by OHKI Yoshihito on 2020/05/17.
//  Copyright © 2020 Veronica Software. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, MIDIManagerDelegate {
    
    // MARK: MIDIManagerDelegate
    private var msgCount = 0
    
    func noteOn(ch: UInt8, note: UInt8, vel: UInt8) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            // Position: C3 = 60 (21-108)
            let unitW = self.size.width / 88.0
            let x = (CGFloat(note) - 64.5) * unitW
            n.position = CGPoint(x: x, y: self.size.height * -0.25)
            
            // Velocity: 0 - 127
            let dur = 2.0 / (Double(vel) / 127.0)
            n.strokeColor = SKColor(white: 1.0, alpha: 1.0)
            n.run(SKAction.moveBy(x: 0, y: self.size.height, duration: dur))
            
            self.addChild(n)
        }
    }
    
    func noteOff(ch: UInt8, note: UInt8, vel: UInt8) {
        
    }
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            //label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 1.0),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            let h = self.size.height
            n.position = CGPoint(x: pos.x, y: self.size.height * -0.5)
            n.strokeColor = SKColor(white: 1.0, alpha: 0.75)
            n.run(SKAction.moveBy(x: 0.0, y: self.size.height, duration: 2.5))
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
        
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
