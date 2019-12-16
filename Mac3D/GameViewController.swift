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

var level_max = 3
let rootPath = "/Users/nicoleolson"
let sun_radius = 7.0
let dir_radius = 3.0
let moon_radius = 0.5


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
    }
    
    // uses FSNodes to construct scene
    func initSpaceView()
    {
        setupScene()
    }
    
    func setupScene()
    {
        sceneView = self.view as? SCNView
        sceneView.allowsCameraControl = true // allows you to look around the scene
        scene = illustrate(node: root)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 10000000
        cameraNode.position = SCNVector3Make(0, 0, 100) // need to make last value dynamic
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.scene = scene // when the scene changes you change this on the sceneView
        sceneView.delegate = self // sets the delegate of the Scene Kit view to self. So that the view can call the
        sceneView.pointOfView = cameraNode
 
        let dehClickies = NSClickGestureRecognizer()
        dehClickies.action = #selector(GameViewController.sceneViewClicked(recognizer:))
        sceneView.gestureRecognizers = [dehClickies]
        createStars()
    }
    
 
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
            
            
            let sphereGeometry = SCNSphere(radius: CGFloat(0.01))
            
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

// creates a scene where the input is the "sun" and the children if dir: are planets with moons else: not illsutrateed yet
// adds the new illustration to Scenes struct
// returns the new Scene object, which has the "scene" that can be used to set the view
func illustrate(node: FSNode) -> SCNScene // change to class "Scene"
{
    var total_diameter = Double(0)
    // scene has camera
    let scene = SCNScene(named: "space.scn")
    // put a sun in the center
    let sun = makePlanet(name: "Root", texture_type: "image", texture: "sun.png", radius: Float(sun_radius))
    scene?.rootNode.addChildNode(sun)
    sun.position = SCNVector3(x: 0, y: 0, z: 0)
    var textures = ["world.png", "multicolor.png", "orange.png", "creamcicle.png"]
    
    //corresponds with above
    var x_min = Double(19)
    //var z_min = Double(5)
    
    var count = 0
    // for each child of root node
    for child in node.children
    {
        count += 1
        if count == 5 { count = 1 }
        
        // if directory it needs moons
        if child.kind == "NSFileTypeDirectory"
        {
            // create a planet
            let planet = makePlanet(name: child.name, texture_type: "solid", texture: "NSgray", radius: Float(dir_radius))
            sun.addChildNode(planet) // I don't know why I need to ? here
            
            // get a count of the moons
            let num_children = child.children.count
            
            // calculate the space needed to illustrate
            // (radius of subdirs are 0.2, need 0.2 between them, and then another 1 for spacing between)
            let diameter = Double(2.0 * (Float(num_children) * 0.6)) + Double(8)
            
            // use diameter to calculte the distance from the sun that the center of the planet needs to be
            let distance_from_sun = x_min + (diameter / Double(2))
            
            // make a torus at that distance
            let torus = makeTorus(distance_from_sun: distance_from_sun)
            scene?.rootNode.addChildNode(torus)
            
            // advance x_min for next planet
            x_min += diameter
            
            let start_x: Double
            let start_z: Double
            var a = Double(0)
            
            if count == 1 {a = Double(Float.random(in: Float(0)..<Float(85)))}
    
            if count == 2 {a = Double(Float.random(in: Float(95)..<Float(175)))}
  
            if count == 3 {a = Double(Float.random(in: Float(185)..<Float(265)))}
 
            if count == 4 {a = Double(Float.random(in: Float(275)..<Float(355)))}

            start_x = 0 + distance_from_sun * cos(a) // x = cx + r * cos(a)
            start_z = 0 + distance_from_sun * sin(a) // y = cy + r * sin(a)
            
            // now we know where the planet starts
            planet.position = SCNVector3(x: CGFloat(start_x), y: 0, z: CGFloat(start_z))
            
            // create a text node
            let text_node = makeText(text: child.name, size: 2)
            planet.addChildNode(text_node)
            
            // position the text
            let x_offset = calculateTextOffset_X(length: child.name.count, size: 0.5)
            let y_offset = calculateTextOffset_Y(radius: Double(dir_radius))
            
            text_node.position = SCNVector3(x: CGFloat(x_offset), y: CGFloat(y_offset), z: 0)
            
            // if there are moons
            if num_children > 0
            {
                var inner_count = 0
                var distance_from_planet = 5.0
                var duration = 5.0
                for moons in child.children
                {
                    duration += 0.05
                    inner_count += 1
                    if inner_count > 4 {inner_count = 1}
                    //var distance_from_planet = 5.0
                    // create a helper
                    let helper = SCNNode() // need to set size?
                    helper.position = SCNVector3(x:0,y:0,z:0)
                    
                    let moon = makePlanet(name: child.name, texture_type: "image", texture: textures[inner_count - 1], radius: Float(moon_radius))
                    scene?.rootNode.addChildNode(moon)
                    scene?.rootNode.addChildNode(helper)
                    // --- add text node here ---
                    
                    planet.addChildNode(moon)
                    planet.addChildNode(helper)
                    helper.addChildNode(moon)
                    //  --- add text node here ---
                    
                    let start_x: Double
                    let start_z: Double
                    var a = Double(0)
                    
                    if inner_count == 1 {a = Double(Float.random(in: Float(0)..<Float(85)))}
                    
                    if inner_count == 2 {a = Double(Float.random(in: Float(95)..<Float(175)))}
                    
                    if inner_count == 3 {a = Double(Float.random(in: Float(185)..<Float(265)))}
                    
                    if inner_count == 4 {a = Double(Float.random(in: Float(275)..<Float(355)))}
                    
                    start_x = 0 + distance_from_planet * cos(a) // x = cx + r * cos(a)
                    start_z = 0 + distance_from_planet * sin(a) // y = cy + r * sin(a)
                    distance_from_planet += 0.5
                    // now we know where the planet starts
                    moon.position = SCNVector3(x: CGFloat(start_x), y: 0, z: CGFloat(start_z))
                    
                    // create a text node
                    //let text_node = makeText(text: child.name, size: 0.5)
                    //moon.addChildNode(text_node)
                    
                    // position the text
                    //let x_offset = calculateTextOffset_X(length: child.name.count, size: 0.5)
                    //let y_offset = calculateTextOffset_Y(radius: Double(dir_radius))
                    
                    //text_node.position = SCNVector3(x: CGFloat(x_offset), y: CGFloat(y_offset), z: 0)
                    helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 3, z: 0, duration: Double(duration))))
                }
            }
        }
        
        //total_diameter += x_min
        //required_depth = total_diameter
        
        // added later
        // it's not a directory, so it does not need moons
        //else
        //{
        //
        //}
    }

    return scene!
   
    // eventually return a scene object which is used to get the scene and store all illustrated scenes
    // lastly, initialize the object and return
    // let new_scene = Scene()
}

// helper function: create a planet node -> SCNNode
func makePlanet(name: String, texture_type: String, texture: String, radius: Float) -> SCNNode
{
    let sphere_geometry = SCNSphere(radius: CGFloat(radius))
    let sphere_material = SCNMaterial()
    sphere_material.locksAmbientWithDiffuse = true
    sphere_material.lightingModel = SCNMaterial.LightingModel.blinn
    if texture_type == "solid"
    {
        if texture == "NSgray"{sphere_material.diffuse.contents = NSColor.gray}
        sphere_material.diffuse.contents = NSColor.gray
    }
    else if texture_type == "image" {sphere_material.diffuse.contents = texture}
    
    //sphere_material.diffuse.contents = NSColor.gray
    sphere_geometry.materials = [sphere_material]
    let dir_node = SCNNode(geometry: sphere_geometry)
    
    return dir_node
    
}

func makeText(text: String, size: Float) -> SCNNode
{
    let text_material = SCNMaterial()
    text_material.ambient.contents = NSColor.blue
    text_material.diffuse.contents = NSColor.white
    text_material.specular.contents = NSColor.red
    text_material.lightingModel = SCNMaterial.LightingModel.physicallyBased
    text_material.shininess = 0.5
    let text_geometry = SCNText(string: text, extrusionDepth: CGFloat(0))
    text_geometry.font = NSFont(name: "Courier New",size: CGFloat(size))
    text_geometry.materials = [text_material]
    text_geometry.firstMaterial?.diffuse.contents = NSColor.green
    return SCNNode(geometry: text_geometry)
}

func makeTorus(distance_from_sun: Double) -> SCNNode
{
    let torus_geometry = SCNTorus(ringRadius: CGFloat(distance_from_sun), pipeRadius: CGFloat(0.01))
    let torus_material = SCNMaterial()
    torus_material.transparency = 0.03 // attempt to make it transparent
    torus_geometry.materials = [torus_material]
    return SCNNode(geometry: torus_geometry)
}

// helper function to calculate the text offset based on font size and number of letters
// function is a work in progress
func calculateTextOffset_X(length: Int, size: Float) -> Float
{
    //-0.6 //0.07 // divide letter count by 2 and then x: -0.07 * result
    let halfLetterWidth = Double(length)/2.0
    
    if size == 0.5
    {
        return Float(-0.6 * halfLetterWidth)
    }
    
    return 0.0 // change
}

func calculateTextOffset_Y(radius: Double) -> Double
{
    if radius == 3
    {
        return 2.4
    }
    
    return 0
}




// ---------------------------- Structs and Classes ------------------------ //

struct Location
{
    var x:Double
    var y:Double
    var z:Double
}

struct Planet
{
    var moons: Array<SCNNode> = [] // moons of the planet
    var location: Location
}

struct Moon
{
    var moon: SCNNode
    var type: String // file or directory (determines what happens upon click)
    var location: Location
}

struct IllustratedDirectory
{
    var sun:SCNNode?  // sun is placed -x, z = 0, y = 0, x determined based on size of directory
    var max_x:Double? // used for placing stars at the edge of the scene
    var min_x:Double?
    var max_z:Double?
    var min_z:Double?
    var planets: Array<Planet> // planets have moons
    var stars: Array<SCNNode>
}

struct PathIllusration
{
    var path: String
    var illustrated_directories: Array<IllustratedDirectory>
}

// all scenes that have been illustrated
struct Scenes
{
    var scenes: Array<Scene>
}


// Init of an FSNode includes recursive call to create children up to level defined in global "maxLevel"
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
        self.scene = nil       // set after tree is built
        
        if level == level_max{return}
        // check if it has children by getting the list of items at that file path
        let children = getCDContents(path: path, full: false)
        
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
                newFSNode.parent = self
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
    weak var scene: Scene?
    
    // add the illustration object
    func addScene(scene: Scene)
    {
        self.scene = scene
    }
}

// Scene objects hold an entire illustrated scene at a specified path
class Scene
{
    var scene: SCNScene
    var illustration: IllustratedDirectory
    
    init(scene: SCNScene, illustration: IllustratedDirectory)
    {
        self.scene = scene
        self.illustration = illustration
    }
    
}

/*
 Reference for adding text nodes to moons (for ordering)
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
 
*/
