//
//  GameViewController.swift
//  Mac3D
//
//  Created by Nicole Olson on 12/10/19.
//  Copyright © 2019 Nicole Olson. All rights reserved.
//

import SceneKit
import AppKit
import Foundation

class GameViewController: NSViewController
{
    
    var sceneView:SCNView!
    var scene: SCNScene!
    var camera: SCNCamera!
    //var leftButtonDown: Bool
    //var rightButtonDown: Bool
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupScene()
        setupNodes()
    }
    
    func setupScene()
    {
        sceneView = self.view as? SCNView
        sceneView.allowsCameraControl = true // allows you to look around the scene
        scene = SCNScene(named: "space.scn")
        sceneView.scene = scene
        
        let dehClickies = NSClickGestureRecognizer()
        dehClickies.action = #selector(GameViewController.sceneViewClicked(recognizer:))
        sceneView.gestureRecognizers = [dehClickies]
    }
    
    // each "scene"
    func setupNodes()
    {
        let center = SCNVector3(
            x: 0,
            y: 0,
            z: 0
        )
        
        // figure out how many top level directories there are
        
        // create the top level directories
        let contents = getContentsAtPath(path: "/")
        print(contents)
        
        var xCent = 0.0
        var zCent = 0.0
        var count = 0
        // get a location
        var xDirlocations = [Float]()
        var zDirlocations = [Float]()
        
        for dir in contents
        {
            for iSphere in 1...Int(contents.count) - 1
            {
                // compute the location of the current planet
                // draw numbers until we find a unique place
                var found = false

                while found == false
                {
                    xCent = Double(Float.random(in: Float(-45)..<Float(120)))
                    zCent = Double(Float.random(in: Float(-120)..<Float(5)))
                    
                    if xDirlocations.count > 0
                    {
                        var foundTooClose = false
                        for i in 0...xDirlocations.count - 1
                        {
                            let xPos = xDirlocations[i]
                            
                            if abs(Double(xPos) - xCent) < 3
                            {
                                foundTooClose = true
                                print("to close")
                                break
                            }
                        }
                        if !foundTooClose
                        {
                            found = true
                        }
                    }
                    else // there are no planets placed yet
                    {
                        found = true
                    }
                }
            }
            
            // now that we've found a place
            xDirlocations.append(Float(xCent))
            zDirlocations.append(Float(zCent))
            
            print(dir)
            let sizeOfDir = dir.count
            let offsetLetter = sizeOfDir / 2
            
            let textMaterial = SCNMaterial()
            textMaterial.ambient.contents = NSColor.blue
            textMaterial.diffuse.contents = NSColor.white
            textMaterial.specular.contents = NSColor.red
            textMaterial.lightingModel = SCNMaterial.LightingModel.physicallyBased
            textMaterial.shininess = 0.5
            
            let sphereGeometry = SCNSphere(radius: CGFloat(1))
            let textGeometry = SCNText(string: dir, extrusionDepth: CGFloat(0))
            textGeometry.font = NSFont(name: "Courier New",size: 0.5)
            textGeometry.materials = [textMaterial]
            textGeometry.firstMaterial?.diffuse.contents = NSColor.green
            let sphereMaterial = SCNMaterial()
            //sphereMaterial.diffuse.contents = NSColor.yellow
            sphereMaterial.locksAmbientWithDiffuse = true
            sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
            sphereMaterial.diffuse.contents = NSColor.gray
            sphereGeometry.materials = [sphereMaterial]
            let centerNode = SCNNode(geometry: sphereGeometry)
            let text = SCNNode(geometry: textGeometry)
            
            centerNode.addChildNode(text)
            scene.rootNode.addChildNode(centerNode)
            centerNode.position = SCNVector3(x: CGFloat(xCent), y: 0, z: CGFloat(zCent))
            centerNode.position = SCNVector3(x: CGFloat(xCent), y: 0, z: CGFloat(zCent))

            count += 1
            text.position = SCNVector3(x: CGFloat(-0.6 * Float(offsetLetter)), y: CGFloat(0.4), z: 0)
            
            var names = ["/Folder1", "/Folder2", "/Folder3", "/Folder4", "/Folder5", "/Folder6", "/Folder7", "/Folder8", "/Folder9", "/Folder10"]
            
            let numPlanets = Double(names.count)
            
            var speed = 1000.0
            let xMin = 1.0
            let xMax = numPlanets/3
            let zMin = 1.0
            let zMax = numPlanets/3
            var radius = 0.2
            let letterWidth = 0.07 // divide letter count by 2 and then x: -0.07 * result
            let halfLetterWidth = letterWidth/2.0
            var curName = ""
            var uneven = false
            var xlocations = [Float]()
            var zlocations = [Float]()
            
            for iSphere in 1...Int(numPlanets) - 1
            {
                // compute the location of the current planet
                // draw numbers until we find a unique place
                var found = false
                var xPlace = 0.0
                var zPlace = 0.0
                while found == false
                {
                    xPlace = Double(Float.random(in: Float(xMin)..<Float(xMax)))
                    zPlace = Double(Float.random(in: Float(zMin)..<Float(zMax)))
                    
                    if iSphere % 2 == 0
                    {
                        xPlace *= -1.0
                    }
                    if iSphere % 3 == 0
                    {
                        zPlace *= -1.0
                    }
                    
                    if xlocations.count > 0
                    {
                        var foundTooClose = false
                        for i in 0...xlocations.count - 1
                        {
                            let xPos = xlocations[i]
                            let zPos = zlocations[i]
                            
                            if abs(Double(xPos) - xPlace) < radius + 0.05
                            {
                                foundTooClose = true
                                break
                            }
                        }
                        if !foundTooClose
                        {
                            found = true
                        }
                    }
                    else // there are no planets placed yet
                    {
                        found = true
                    }
                }
                
                // now that we've found a place
                xlocations.append(Float(xPlace))
                zlocations.append(Float(zPlace))
                
                curName = names[iSphere]
                let count = curName.count
                
                if count % 2 != 0
                {
                    uneven = true
                }
                
                var letterShift = -(Double(count / 2) * letterWidth)
                if uneven
                {
                    letterShift -= halfLetterWidth
                }
                // reset
                uneven = false
                let sphereGeometry = SCNSphere(radius: CGFloat(radius))
                let textGeometry = SCNText(string: curName, extrusionDepth: CGFloat(0))
                textGeometry.font = NSFont(name: "Courier New",size: 0.1)
                textGeometry.materials = [textMaterial]
                textGeometry.firstMaterial?.diffuse.contents = NSColor.green
                let sphereMaterial = SCNMaterial()
                //sphereMaterial.diffuse.contents = NSColor.yellow
                sphereMaterial.locksAmbientWithDiffuse = true
                sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
                let textures = ["world.png", "multicolor.png", "fireworks.png"]
                sphereMaterial.diffuse.contents = textures[iSphere % 3]
                sphereGeometry.materials = [sphereMaterial]
                let sphere1 = SCNNode(geometry: sphereGeometry)
                let text = SCNNode(geometry: textGeometry)
                let helper = SCNNode()
                helper.position = center
                
                scene.rootNode.addChildNode(sphere1)
                sphere1.addChildNode(text)
                scene.rootNode.addChildNode(helper)
                scene.rootNode.addChildNode(text)
                centerNode.addChildNode(sphere1)
                centerNode.addChildNode(helper)
                helper.addChildNode(sphere1)
                sphere1.addChildNode(text)
                
                
                sphere1.position = SCNVector3(x: CGFloat(xPlace), y: 0, z: -CGFloat(zPlace))
                
                
                text.position = SCNVector3(x: CGFloat(letterShift), y: CGFloat(radius - 1), z: 0)
                
                speed -= (numPlanets/5)
                radius += 0.008
                helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 3, z: 0, duration: Double(speed))))
                //text.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 3, z: 0, duration: Double(0.4))))
            }
        }
        
    }
    
    
    // Mouse Events
    /*
    override func mouseDown(with event: NSEvent)
    {
        if event.associatedEventsMask.contains(NSEvent.EventType.leftMouseDown)
        {
            
        }
    }
    
    override func mouseMoved(with event: NSEvent)
    {
        
    }
    */
    
    //override func sceneviewcli
    
    
    // for when user clicks something we check if it was on a planet or file
    @objc func sceneViewClicked(recognizer: NSClickGestureRecognizer)
    {
        // get the location of the click
        let location = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(location, options: nil)
        
        // if they clicked on nothing then nothing happens
        if hitResults.count > 0
        {
            let result = hitResults.first
            if let node = result?.node
            {
                // search file system for the name
                
                for child in node.childNodes
                {
                    child.localRotate(by: SCNQuaternion(0, 1, 0, 0))
                }
            }
        }
        
        
    }
    
}


class FSContainer
{
    init(root: FSNode) {
        // start with nothing
        self.root = root
    }
    var root: FSNode
    
    // cwd determined by calling function either in initial build or by scene name, which is named after the path
    // user double clicks on a directory planet, game opens new scene of that name
    func add(cwd: String, x: Float, y: Float, z: Float, children: [FSNode], name: String, kind: String)
    {
        // create a new FSNode, naming it internally based on the cwd, ie cwd_<name>
        
        
        // find the directory on the path of the cwd and add the node
    }
    
    // returns an FSNode
    func findNode(name: String, parentName: String)
    {
        
    }
    
    
    func _getDirectory(dir: String, parent: String)
    {
        
    }
}

class FSNode
{
    init(x: Float, y: Float, z: Float, children: [FSNode], name: String, kind: String, parent: FSNode, path: String) {
        self.x = x
        self.y = y
        self.z = z
        self.children = children
        self.kind = kind
        self.name = name       // name displayed to user
        self.parent = parent
        self.path = path       // name in scene
    }
    
    var kind: String
    var name: String
    var path: String
    var x: Float
    var y: Float
    var z: Float
    var children: [FSNode] = []
    weak var parent: FSNode? // may not be necessary given the "path" var
    
    func addChild(node: FSNode)
    {
        self.children.append(node)
    }
}

func getContentsAtPath(path: String) -> Array<String>
{
    var files = [""]
    let fileManager = FileManager.default
    
    // Get contents in directory: '.' (current one)
    
    do {
        files = try fileManager.contentsOfDirectory(atPath: path)
        
        print(files)
        
        //return files
    }
    catch let error as NSError {
        print("Ooops! Something went wrong: \(error)")
    }
    
    return files
}
