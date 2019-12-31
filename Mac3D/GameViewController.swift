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

var depth_init = 2
let root_path = "/Users/nicoleolson"
let sun_radius = 12.0
let dir_radius = 3.0
let moon_radius = 0.5
var scenes = [String: SCNScene]() // stores illustrated scenes

class GameViewController: NSViewController
{
    var end_of_solar_system = 0
    var sceneView:SCNView!
    var scene: SCNScene!
    var camera: SCNCamera!
    let center = SCNVector3(x: 0, y: 0, z: 0)
    var root = FSNode(name: "Root", kind: "NSFileTypeDirectory", path: root_path, depth: 0)
    var current_path = root_path
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initSpaceView()
    }

    func initSpaceView()
    {
        let scene = createScene(node: root, path: root_path)
        setScene(scene: scene)
        saveScene(scene: scene, path: root_path)
    }
    
    func saveScene(scene: SCNScene, path: String){ scenes[path] = scene }
    func sceneExists(path: String) -> Bool{ return (scenes[path] == nil ? false : true);}
    func retrieveScene(path: String) -> SCNScene{ return scenes[path]! } // pre-req: true from "sceneExists(path)"
 
    func createScene(node: FSNode, path: String) -> SCNScene
    {
        sceneView = self.view as? SCNView
        sceneView.allowsCameraControl = true // allows you to look around the scene
        scene = illustrate(root_of_scene: node, path: path) // returns the illustrated scene
        return scene
    }
    
    func changeScene(node: FSNode)
    {
        if sceneExists(path: node.path)
        {
            let scene = retrieveScene(path: node.path)
            current_path = node.path
            setScene(scene: scene)
        }
        else
        {
            // expand the directory tree (by +1 if planet and +2 if moon)
            // compare current_path to node path length
            let cp_arr = getArrFromPath(path: current_path)
            let node_arr = getArrFromPath(path: node.path)
            let difference = node_arr.count - cp_arr.count
            print("Difference between paths: ")
            print(difference)
            if difference == 1 { increaseBranchDepth(node: node)}
            
            if difference == 2
            {
                let parent_node = node.parent
                increaseBranchDepth(node: parent_node!)
                let children = node.children // they only have children after we increase depth of parent
                for child in children {increaseBranchDepth(node: child)}
            }
            
            // create scene
            let scene = createScene(node: node, path: node.path)
            
            // set and save
            setScene(scene: scene)
            saveScene(scene: scene, path: node.path)
        }
    }
    
    func setScene(scene: SCNScene)
    {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 10000000
        cameraNode.position = SCNVector3Make(0, 0, 100) // need to make last value dynamic
        scene.rootNode.addChildNode(cameraNode)

        sceneView.scene = scene // when the scene changes you change this on the sceneView
        sceneView.delegate = self // sets the delegate of the Scene Kit view to self. So that the view can call the
        sceneView.pointOfView = cameraNode
    }
    
    func increaseBranchDepth(node: FSNode)
    {
        for child_node in node.children
        {
            // get the children of each child node
            let children = getCDContents(path: child_node.path, full: false)
            // if children
            if children.count > 0
            {
                for c in children
                {
                    // get the file type of the child
                    var fileType = getFileType(path: child_node.path + "/" + c)
                    
                    if fileType != "NSFileTypeDirectory"
                    {
                        var myStringArr = fileType.components(separatedBy: ".")
                        if myStringArr.count >= 2 { fileType = myStringArr[1]}
                    }
                    
                    // make a node using different init that doesn't recurse
                    let newFSNode = FSNode(name: c, kind: fileType, path: child_node.path + "/" + c, depth: child_node.depth + 1, parent: child_node)
                    
                    child_node.children.append(newFSNode)
                }
            }
            child_node.child_count = child_node.children.count
        }
    }
    
    // for when user clicks something we check if it was on a planet or file
    @objc func sceneViewClicked(recognizer: NSClickGestureRecognizer)
    {
        print("Something clicked")
        // get the location of the click
        let location = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(location, options: nil)
        
        // if they clicked on nothing then nothing happens
        if hitResults.count > 0
        {
            let result = hitResults.first
            if let node = result?.node
            {
                print("Node clicked with name: " + node.name!)
                let fs_node = findNode(new_root_path: node.name!, root: root)
                if fs_node.kind == "NSFileTypeDirectory" { changeScene(node: fs_node) }
                else{print("opening . . .")}
            }
        }
    }
    
    //func spawnShape()
    //{
    //    // 1
    //    var geometry:SCNGeometry
    //
    //    geometry = SCNSphere(radius: 1)
    //
    //    geometry.materials.first?.diffuse.contents = NSColor.yellow
    //
    //    // 4
    //    let geometryNode = SCNNode(geometry: geometry)
    //    geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
    //
    //   // 1
    //    let randomX = Float.random(in: -45..<2)
    //    let randomY = Float.random(in: 10..<18)
    //    // 2
    //    let force = SCNVector3(x: CGFloat(randomX), y: CGFloat(randomY) , z: 0)
    //    // 3
    //    let position = SCNVector3(x: 0, y: 0, z: -150)
    //    // 4
    //    geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
    //
    //    // 5
    //    scene.rootNode.addChildNode(geometryNode)
    //}

    
}

extension GameViewController: SCNSceneRendererDelegate {
    // 2
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // 3
        //spawnShape()
        print("")
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

// creates a scene where the input is the "sun" and the children if dir: are planets with moons else: not illsutrateed yet
// adds the new illustration to Scenes struct
// returns the new Scene object, which has the "scene" that can be used to set the view
func illustrate(root_of_scene: FSNode, path: String) -> SCNScene // change to class "Scene"
{
    let planets = ["p1.png", "p2.png"]
    let m = ["m1.png","m2.png","m3.png","m4.png","m5.png","m6.png","m7.png","m8.png"]
    var x_min = Double(49)
    let scene = SCNScene(named: "space.scn")
    
    let sun = makeSun(scene: scene!, path: path)
    
    var count = 0
    var planet_count = 0
    var directories: [FSNode] = []
    var files: [FSNode] = []
    
    for childnode in root_of_scene.children
    {
        // create an array of the directories
        if childnode.kind == "NSFileTypeDirectory"{directories.append(childnode)}
        // create an array of the files
        else{files.append(childnode)} // files get illustrated as astroid belt half way through
    }
    
    //print("the " + root_of_scene.name + " directory is the sun now and has the following orbiting directories: ")
    //for d in directories{
    //    print(d.name)
    //}
    //print(directories)
    
    // sort by number of children in ascending order
    directories.sort(by: { $0.child_count < $1.child_count })
    
    let dir_count = directories.count
    
    let astroid_position = dir_count/2
    
    // for each directory
    for directory in directories
    {
        planet_count += 1
        
        if planet_count == astroid_position
        {
            // make the astroid belt
            print("astroid belt")
        }
        
        count += 1
        if count == 4 { count = 1 }
        if planet_count == 1 { planet_count = 0 }
        // create a planet
        let helper = SCNNode()
        helper.position = SCNVector3(x:0,y:0,z:0)
        let helper2 = SCNNode()
        helper2.position = SCNVector3(x:0,y:0,z:0)
        print(directory.path)
        let planet = makePlanet(is_moon: false, name: directory.path, texture_type: "image", texture: planets[planet_count], radius: Float(dir_radius))
        scene?.rootNode.addChildNode(planet)
        scene?.rootNode.addChildNode(helper)
        sun.addChildNode(planet)
        sun.addChildNode(helper)
        helper.addChildNode(planet)
        helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(60))))
        
        // count the subdirectories
        var subdirectories = 0

        for dc in directory.children
        {
            if dc.kind == "NSFileTypeDirectory"{subdirectories += 1}
        }
        
        let num_children = subdirectories
        
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
        print("text node: " + directory.name)
        
        let text_node = makeText(text: directory.name, size: 2, color: "green")
        planet.addChildNode(text_node)
        
        // position the text
        let x_offset = calculateTextOffset_X(length: directory.name.count, size: 0.5)
        let y_offset = calculateTextOffset_Y(radius: Double(dir_radius))
        
        text_node.position = SCNVector3(x: CGFloat(x_offset), y: CGFloat(y_offset), z: 0)
        var inner_count = 0
        // if there are moons
        
        if num_children > 0
        {
            var inner_count = 0
            var moon_count = 0
            var distance_from_planet = 5.0
            var duration = 50.0
            for moons in directory.children
            {
                duration += 0.05
                inner_count += 1
                moon_count += 1
                if inner_count > 4 {inner_count = 1}
                if moon_count == 6 {moon_count = 0}
                //var distance_from_planet = 5.0
                // create a helper
                let helper = SCNNode() // need to set size?
                helper.position = SCNVector3(x:0,y:0,z:0)
                
                var moon: SCNNode
                if moons.kind == "NSFileTypeDirectory"
                {
                    moon = makePlanet(is_moon: true, name: moons.name, texture_type: "image", texture: m[moon_count], radius: Float(moon_radius))
                    scene?.rootNode.addChildNode(moon)
                    scene?.rootNode.addChildNode(helper)
                    // create a text node
                    let text_node = makeText(text: moons.name, size: 0.2, color: "green")
                    moon.addChildNode(text_node)
                    
                    // position the text
                    let x_offset = calculateTextOffset_X(length: moons.name.count, size: 0.05)
                    let y_offset = calculateTextOffset_Y(radius: Double(moon_radius))
                    
                    text_node.position = SCNVector3(x: CGFloat(x_offset), y: CGFloat(y_offset), z: 0)
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
                    helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 5, z: 0, duration: Double(duration))))
                }
            }
        }
    }
    createStars(scene: scene!)
    
    return scene!
   
    // eventually return a scene object which is used to get the scene and store all illustrated scenes
    // lastly, initialize the object and return
    // let new_scene = Scene()
}

func createStars(scene: SCNScene)
{
    var x: Int
    var y: Int
    var z: Int
    var duration = 10.0
    
    // make stars below and above
    for i in 1...3000
    {
        
        x = Int(Double(Float.random(in: Float(-1000)..<Float(1000))))
        y = Int(Double(Float.random(in: Float(-500)..<Float(-20))))
        z = Int(Double(Float.random(in: Float(-1000)..<Float(1000))))
        
        if i % 2 == 0
        {
            y *= -1
            y += 50
        }
        
        let sphereGeometry = SCNSphere(radius: CGFloat(0.05))
        
        let sphereMaterial = SCNMaterial()
        sphereMaterial.locksAmbientWithDiffuse = true
        sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
        sphereMaterial.diffuse.contents = "starcolor2.png"
        
        if i % 12 == 0
        {
            sphereMaterial.diffuse.contents = NSColor.purple
        }
        if i % 16 == 0
        {
            sphereMaterial.diffuse.contents = NSColor.blue
        }
        if i % 10 == 0
        {
            sphereMaterial.diffuse.contents = NSColor.red
        }
        
        sphereGeometry.materials = [sphereMaterial]
        let sphere1 = SCNNode(geometry: sphereGeometry)
        
        scene.rootNode.addChildNode(sphere1)
        sphere1.position = SCNVector3(x: CGFloat(x), y: CGFloat(y), z: CGFloat(z))
        if i % 5 == 0
        {
            sphere1.runAction(SCNAction.scale(by: CGFloat(0.8), duration: 5))
            duration += 0.01
        }
        sphere1.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 5, z: 0, duration: Double(40))))
    }
}

func makeSun(scene: SCNScene, path: String) -> SCNNode
{
    let sun_name = getCwdFromPath(path: path)
    let sun = makePlanet(is_moon: false, name: sun_name, texture_type: "image", texture: "sun.png", radius: Float(sun_radius))
    scene.rootNode.addChildNode(sun)
    sun.position = SCNVector3(x: 0, y: 0, z: 0)
    let sun_halo = makePlanet(is_moon: false, name: "Root", texture_type: "solid", texture: "NSyellow", radius: Float(sun_radius + 0.5))
    scene.rootNode.addChildNode(sun_halo)
    sun_halo.position = SCNVector3(x: 0, y: 0, z: 0)
    let sun_halo2 = makePlanet(is_moon: false, name: "Root", texture_type: "solid", texture: "NSorange", radius: Float(sun_radius + 4.6))
    scene.rootNode.addChildNode(sun_halo2)
    sun_halo2.position = SCNVector3(x: 0, y: 0, z: 0)
    sun_halo2.light = SCNLight()
    sun_halo2.light!.type = SCNLight.LightType.omni
    sun_halo2.light!.color = NSColor(calibratedRed: CGFloat(1), green: CGFloat(1), blue: CGFloat(0.8), alpha: CGFloat(1))
    sun_halo2.light!.attenuationStartDistance = 100
    sun_halo2.light!.temperature = 5500
    sun_halo2.light!.intensity = 10000
    
    return sun
}

// helper function: create a planet node -> SCNNode
func makePlanet(is_moon: Bool, name: String, texture_type: String, texture: String, radius: Float) -> SCNNode
{
    let sphere_geometry = SCNSphere(radius: CGFloat(radius))
    let sphere_material = SCNMaterial()
    sphere_material.locksAmbientWithDiffuse = true
    sphere_material.lightingModel = SCNMaterial.LightingModel.blinn
    if texture_type == "solid"
    {
        if texture == "NSgray"
        {
            sphere_material.diffuse.contents = NSColor.gray
            sphere_material.diffuse.contents = NSColor.gray
        }
        else if texture == "NSyellow"
        {
            sphere_material.diffuse.contents = NSColor.red
            sphere_material.transparency = 0.1
        }
        else if texture == "NSorange"
        {
            sphere_material.diffuse.contents = NSColor.orange
            sphere_material.transparency = 0.1
        }
    }
    else if texture_type == "image"
    {
        if texture == "sun.png"
        {
            //sphere_material.shininess = 10
            sphere_material.diffuse.contents = "ss11.png"
            sphere_material.normal.contents = "ss7.png"
        }
        else
        {
            if !is_moon
            {
                sphere_material.shininess = 2
                
                let color = Int.random(in: Int(0)..<Int(10))
                
                switch color
                {
                case 0:
                    sphere_material.diffuse.contents = NSColor.yellow
                    sphere_material.emission.contents = NSColor.yellow
                case 1:
                    sphere_material.diffuse.contents = NSColor.magenta
                    sphere_material.emission.contents = NSColor.magenta
                case 2:
                    sphere_material.diffuse.contents = NSColor.red
                    sphere_material.emission.contents = NSColor.red
                case 3:
                    sphere_material.diffuse.contents = NSColor.blue
                    sphere_material.emission.contents = NSColor.blue
                case 4:
                    sphere_material.diffuse.contents = NSColor.orange
                    sphere_material.emission.contents = NSColor.orange
                case 5:
                    sphere_material.diffuse.contents = NSColor.cyan
                    sphere_material.emission.contents = NSColor.cyan
                case 6:
                    sphere_material.diffuse.contents = "b1.png"
                    sphere_material.emission.contents = "b1.png"
                case 7:
                    sphere_material.diffuse.contents = NSColor.purple
                    sphere_material.emission.contents = NSColor.purple
                case 8:
                    sphere_material.diffuse.contents = NSColor.brown
                    sphere_material.emission.contents = NSColor.brown
                case 9:
                    sphere_material.diffuse.contents = "b2.png"
                    sphere_material.emission.contents = "b2.png"
                default:
                    sphere_material.diffuse.contents = NSColor.gray
                    sphere_material.emission.contents = NSColor.gray
                }
                
                sphere_material.emission.intensity = 0.2
            }
            else
            {
                sphere_material.diffuse.contents = texture
                sphere_material.emission.contents = texture
                sphere_material.emission.intensity = 0.2
            }
        }
    }
    
    //sphere_material.diffuse.contents = NSColor.gray
    sphere_geometry.materials = [sphere_material]
    sphere_geometry.segmentCount = 80
    let dir_node = SCNNode(geometry: sphere_geometry)
    dir_node.name = name
    return dir_node
}

func makeAstroid() -> SCNNode
{
    let astroid_mat = SCNCone(topRadius: 0.1, bottomRadius: 0.4, height: 0.1)
    let astroid = SCNNode(geometry: astroid_mat)
    astroid.name = "" // EDIT
    return astroid
}


func makeText(text: String, size: Float, color: String) -> SCNNode
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
    if color == "green" {text_geometry.firstMaterial?.diffuse.contents = NSColor.green}
    else {text_geometry.firstMaterial?.diffuse.contents = NSColor.orange}
    return SCNNode(geometry: text_geometry)
}

func makeTorus(distance_from_sun: Double) -> SCNNode
{
    let torus_geometry = SCNTorus(ringRadius: CGFloat(distance_from_sun), pipeRadius: CGFloat(0.005))
    let torus_material = SCNMaterial()
    torus_material.transparency = 0.005 // brightness of sun illuminates
    torus_geometry.materials = [torus_material]
    return SCNNode(geometry: torus_geometry)
}

// helper function to calculate the text offset based on font size and number of letters
func calculateTextOffset_X(length: Int, size: Float) -> Float
{
    let halfLetterWidth = Double(length)/2.0
    
    if size == 0.5 // directory font
    {
        // -x moves to the left
        return Float(-1.1 * halfLetterWidth)
    }
    else // moon font
    {
        return Float(-0.1 * halfLetterWidth)
    }
}

func calculateTextOffset_Y(radius: Double) -> Double
{
    if radius == 3 { return 2.4}
    return -0.3
}

// name is a path
func findNode(new_root_path: String, root: FSNode) -> FSNode
{
    var path_dir_arr = getArrFromPath(path: new_root_path)
    
    var fs_node = root
    
    var node_path = root.path
    
    let root_paths = root.path.components(separatedBy: "/")
    
    let size = root_paths.count
    
    path_dir_arr.removeFirst(size) // remove
    var i = 0
    
    while fs_node.path != new_root_path
    {
        // get the children of fs_node
        let children = fs_node.children
        // go through them until you find the next thing in path_dir_arr
        for child in children
        {
            let child_name_arr = child.name.components(separatedBy: "/")
            let child_name = child_name_arr[size - 1]
            if child_name == path_dir_arr[i]
            {
                i += 1
                fs_node = child
                break
            }
        }
    }
    
    return fs_node
}

// convert path to array of path items
func getArrFromPath(path: String) -> Array<String>
{
    let items = path.components(separatedBy: "/")
    return items
}

func getCwdFromPath(path: String) -> String
{
    let arr = getArrFromPath(path: path)
    let size = arr.count
    let last = arr[size - 1]
    return last
}






// ---------------------------- Structs and Classes ------------------------ //

// Init of an FSNode includes recursive call to create children up to level defined in global "maxLevel"
class FSNode
{
    // recursing init builds tree from a root to a global defined "depth_init"
    init(name: String, kind: String, path: String, depth: Int) {
        self.kind = kind
        self.name = name
        self.path = path
        self.children = []
        self.child_count = 0
        self.depth = depth
        
        if depth == depth_init{return} // end recursive calls
        
        let children = getCDContents(path: path, full: false)
        
        if children.count > 0
        {
            for c in children
            {
                var fileType = getFileType(path: path + "/" + c)
                
                if fileType != "NSFileTypeDirectory"
                {
                    var myStringArr = fileType.components(separatedBy: ".")

                    if myStringArr.count >= 2
                    {
                        fileType = myStringArr[1]
                    }
                }
                
                let newFSNode = FSNode(name: c, kind: fileType, path: path + "/" + c, depth: depth + 1)
                newFSNode.parent = self
                self.children.append(newFSNode)
            }
            self.child_count = self.children.count
        }
    }
    
    // non-recursing init used in adding 1 depth to a particular branch
    init(name: String, kind: String, path: String, depth: Int, parent: FSNode)
    {
        self.kind = kind
        self.name = name
        self.path = path
        self.children = []
        self.child_count = 0
        self.depth = depth
        self.parent = parent
    }
    
    // class properties
    var kind: String
    var name: String
    var path: String
    var children: [FSNode] = []
    var child_count: Int
    var depth: Int
    weak var parent: FSNode?

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
 
 
 @objc
 func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
 // retrieve the SCNView
 let scnView = self.view as! SCNView
 
 // check what nodes are clicked
 let p = gestureRecognizer.location(in: scnView)
 let hitResults = scnView.hitTest(p, options: [:])
 // check that we clicked on at least one object
 if hitResults.count > 0 {
 // retrieved the first clicked object
 let result = hitResults[0]
 
 // get its material
 let material = result.node.geometry!.firstMaterial!
 
 // highlight it
 SCNTransaction.begin()
 SCNTransaction.animationDuration = 0.5
 
 // on completion - unhighlight
 SCNTransaction.completionBlock = {
 SCNTransaction.begin()
 SCNTransaction.animationDuration = 0.5
 
 material.emission.contents = NSColor.black
 
 SCNTransaction.commit()
 }
 
 material.emission.contents = NSColor.red
 
 SCNTransaction.commit()
 }

 */

//override func sceneviewcli
