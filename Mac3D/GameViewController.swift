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

var levelMax = 3
let rootPath = "/Users/nicoleolson"

// to represent locations of planets
struct Location {
    var x:Double
    var y:Double
    var z:Double
}

struct IllustratedDirectory
{
    var center:Location
    var max_x:Double
    var min_x:Double
    var max_z:Double
    var min_z:Double
    var moonLocations: Array<Location> // moons orbit but we want to not put other things on their path
}

struct LevelIllusration
{
    var level: Int
    var illustratedDirectories: Array<IllustratedDirectory>
}

class GameViewController: NSViewController
{
    var sceneView:SCNView!
    var scene: SCNScene!
    var camera: SCNCamera!
    let center = SCNVector3(x: 0, y: 0, z: 0)
    var root = FSNode(x: 0, y: 0, z: 0, name: "Root", kind: "NSFileTypeDirectory", path: rootPath, level: 1)
    var currentPath = "/Users/nicoleolson"
    var current_illustrated_directories: Array<IllustratedDirectory> = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initSpaceView()
        setupScene()
        // setupNodes()
    }
    
    // uses FSNodes to construct scene
    func initSpaceView()
    {
        let children = root.children
        var directory_names = [String]()
        var non_directory_names = [String]()
        var child_directory_names = [String]()
        var child_non_directory_names = [String]()

        for c in children
        {
            if c.kind == "NSFileTypeDirectory"
            {
                directory_names.append(c.name)
                // get the moons of the directories
                let dir_children = c.children
                
                for d_c in dir_children
                {
                    if d_c.kind == "NSFileTypeDirectory"
                    {
                        child_directory_names.append(d_c.name)
                    }
                    else
                    {
                        child_non_directory_names.append(d_c.name)
                    }
                }
                
            }
                
            else{non_directory_names.append(c.name)}
        }
    }
    
    func setupScene()
    {
        sceneView = self.view as? SCNView
        sceneView.allowsCameraControl = true // allows you to look around the scene
        scene = SCNScene(named: "space.scn")
        sceneView.scene = scene
        sceneView.delegate = self // sets the delegate of the Scene Kit view to self. So that the view can call the delegate methods that are implemented in GameViewController
        
        let dehClickies = NSClickGestureRecognizer()
        dehClickies.action = #selector(GameViewController.sceneViewClicked(recognizer:))
        sceneView.gestureRecognizers = [dehClickies]
        createStars()
    }
    
    // each "scene"
    /*func setupNodes()
    {
        let contents = getCDContents(path: rootPath, full: false) // must be user variable eventually
        
        var xCent = 0.0
        var zCent = 0.0
        var count = 0
        var xDirlocations = [Float]()
        var zDirlocations = [Float]()
        
        for dir in contents
        {
            var curPath = rootPath + "/" + dir
            let moons = getCDContents(path: curPath, full: false)
            //print("contents at " + curPath)
            //print(moons)
            
            
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
                                //print("to close")
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
            
            //print(dir)
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
            
            var speed = 300.0
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
                
                
                if iSphere - 1 < moons.count
                {
                    //print(moons.count)
                    //print(iSphere)
                    curName = moons[iSphere-1]
                }
                else
                {
                    curName = names[iSphere]
                }
                
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
                let textures = ["world.png", "multicolor.png", "fireworks.png", "orange.png", "redblue.png", "creamcicle.png", "greenblue.png", "world.png", "multicolor.png", "fireworks.png"]
                sphereMaterial.diffuse.contents = textures[iSphere]
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
                
                speed -= (numPlanets)
                radius += 0.008
                helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 3, z: 0, duration: Double(speed))))
                //text.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 3, z: 0, duration: Double(0.4))))
            }
        }
        
    }*/
    

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
    
    func spawnShape()
    {
        // 1
        var geometry:SCNGeometry
        
        geometry = SCNSphere(radius: 1)
        
        geometry.materials.first?.diffuse.contents = NSColor.yellow
        
        // 4
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        
        // 1
        let randomX = Float.random(in: -45..<2)
        let randomY = Float.random(in: 10..<18)
        // 2
        let force = SCNVector3(x: CGFloat(randomX), y: CGFloat(randomY) , z: 0)
        // 3
        let position = SCNVector3(x: 0, y: 0, z: -150)
        // 4
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        
        // 5
        scene.rootNode.addChildNode(geometryNode)
    }

    func createStars()
    {
        var x = 0
        var y = 0
        var z = 0
        var duration = 10.0
        
        for i in 1...3000
        {
            
            x = Int(Double(Float.random(in: Float(-200)..<Float(200))))
            y = Int(Double(Float.random(in: Float(-50)..<Float(50))))
            z = Int(Double(Float.random(in: Float(-200)..<Float(100))))
            
            
            let sphereGeometry = SCNSphere(radius: CGFloat(0.1))
            
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = NSColor.yellow
            sphereMaterial.locksAmbientWithDiffuse = true
            sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
            sphereMaterial.diffuse.contents = "starcolor2.png"
            sphereGeometry.materials = [sphereMaterial]
            let sphere1 = SCNNode(geometry: sphereGeometry)
            
            scene.rootNode.addChildNode(sphere1)
            sphere1.position = SCNVector3(x: CGFloat(x), y: CGFloat(y), z: CGFloat(z))
            if i % 5 == 0
            {
                sphere1.runAction(SCNAction.scale(by: CGFloat(0.5), duration: 5))
                duration += 0.01
            }
        }
        
    }
    
}

extension GameViewController: SCNSceneRendererDelegate {
    // 2
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // 3
        spawnShape()
    }
}

class FSNode
{
    init(x: Float, y: Float, z: Float, name: String, kind: String, path: String, level: Int) {
        self.x = x
        self.y = y
        self.z = z
        self.kind = kind
        self.name = name       // name displayed to user
        self.path = path       // name in scene
        self.children = []
        
        if level == levelMax{return}
        // check if it has children by getting the list of items at that file path
        var children = getCDContents(path: path, full: false)
        
        // if children
        if children.count > 0
        {
            for c in children
            {
                // get the file type of the child
                var fileType = getFileType(path: path + "/" + c)
                
                // if it's not a directory, get the extension
                if fileType != "NSFileTypeDirectory"
                {
                    var myStringArr = fileType.components(separatedBy: ".")
                    //print(myStringArr)
                    //print(myStringArr.count)
                    if myStringArr.count >= 2
                    {
                        fileType = myStringArr[1]
                    }
                }
                
                // make a node
                let newFSNode = FSNode(x: 0, y: 0, z: 0, name: c, kind: fileType, path: path + "/" + c, level: level + 1)
                // add to array
                self.children.append(newFSNode)
            }
        }
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


func getCDContents(path: String, full: Bool) -> Array<String>
{
    let fullContents = getContentsAtPath(path: path)
    if fullContents.count == 0
    {
        if path == "/Users/nicoleolson"
        {
            print("Unable to get contents at root. Exiting ... ")
            return fullContents
        }
    }
        
    if full {return fullContents}
    else
    {
        let filteredContents = getLSContents(fullContents: fullContents)
        return filteredContents
    }
}


// helping function
func getContentsAtPath(path: String) -> Array<String>
{
    var files = [String]()
    let fileManager = FileManager.default
    
    do {
        files = try fileManager.contentsOfDirectory(atPath: path)
        
        //print(files)
        //print("successfully got files at " + path)
        return files
    }
    catch let error as NSError {
        //print("Ooops! Something went wrong: \(error)")
        files = []
        //print("Error getting files at " + path)
        return files
    }
}

// helper function filters out directory contents that start with "."
func getLSContents(fullContents: Array<String>) -> Array<String>
{
    var refinedContents = [String]()
    for content in fullContents{ if content.first != "."{refinedContents.append(content)}}
    return refinedContents
}

// helper to get file type
func getFileType(path: String) -> String
{
    let fileManager = FileManager.default
    let attributes = try! fileManager.attributesOfItem(atPath: path)
    let type = attributes[.type] as! String
    //var type = attributes.fileType();
    //print(type)
    return type
}

//func getRandom(min: Double, max: Double)
//{
    
//}

// returns the proximity between the incoming point to other points
//func checkProximity(x: Double, y: Double, z: Double, otherPoints: Array<Location>) -> Double
//{
//    return 0.0
//}

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


