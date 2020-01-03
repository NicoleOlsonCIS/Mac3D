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

var depth_init = 3
let root_path = "/Users/nicoleolson"
let sun_radius = 64.0
let dir_radius = 20.0
let moon_radius = 1.5
var scenes = [String: SCNScene]()

class GameViewController: NSViewController
{
    var end_of_solar_system = 0
    var sceneView:SCNView!
    var scene: SCNScene!
    var camera: SCNCamera!
    let center = SCNVector3(x: 0, y: 0, z: 0)
    var root = FSNode(name: root_path, kind: "NSFileTypeDirectory", path: root_path, depth: 0)
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
            pingDepthAndCreate(new_sun: node)
            let scene = createScene(node: node, path: node.path)
            setScene(scene: scene)
            saveScene(scene: scene, path: node.path)
            current_path = node.path
        }
    }
    
    func setScene(scene: SCNScene)
    {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 10000000
        cameraNode.position = SCNVector3Make(0, 10, 1000) // need to make last value dynamic
        scene.rootNode.addChildNode(cameraNode)
        
        
        //let lightnode = SCNNode()
        //lightnode.light = SCNLight()
        //lightnode.light!.type = SCNLight.LightType.ambient
        //scene.rootNode.addChildNode(lightnode)

        sceneView.scene = scene // when the scene changes you change this on the sceneView
        sceneView.delegate = self //as! SCNSceneRendererDelegate // sets the delegate of the Scene Kit view to self. So that the view can call the
        sceneView.pointOfView = cameraNode
        let dehClickies = NSClickGestureRecognizer()
        dehClickies.action = #selector(GameViewController.sceneViewClicked(recognizer:))
        sceneView.gestureRecognizers = [dehClickies]
    }
    
    // create three full levels below new sun, is new sun is leaf then nothing changes
    func pingDepthAndCreate(new_sun: FSNode)
    {
        if new_sun.child_count == -1 {new_sun.addChildren(parent: new_sun.parent!)}
        if new_sun.child_count != 0 // if after attempt it is not a leaf
        {
            // +1 depth
            var need_fill = [FSNode]()
            for child in new_sun.children { if child.child_count != -1 { need_fill.append(child)}}
            for child in need_fill{ child.addChildren(parent: child)} // those that haven't been attempted
            need_fill.removeAll()
            for child in new_sun.children {if child.child_count != 0 {need_fill.append(child)}}
            for child in need_fill{ child.addChildren(parent: child)}
            need_fill.removeAll()
            
            // +2 depth
            let children = new_sun.children
            for child in children {if child.child_count != -1 { need_fill.append(child)}}
            for child in need_fill{ child.addChildren(parent: child)} // those that haven't been attempted
            need_fill.removeAll()
            for child in children {if child.child_count != 0 {need_fill.append(child)}}
            for child in need_fill{ child.addChildren(parent: child)}
            need_fill.removeAll()
            
            // +3 depth
            for child in children
            {
                for c in child.children { if c.child_count != -1 { need_fill.append(c)} }
                for d in need_fill {d.addChildren(parent: d)}
                need_fill.removeAll()
                for c in child.children { if c.child_count != 0 { need_fill.append(c)} }
                for e in need_fill{ e.addChildren(parent: e)}
            }
        }
    }
    
    // navigational clicks on directories, file clicks open files
    @objc func sceneViewClicked(recognizer: NSClickGestureRecognizer)
    {
        let location = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(location, options: nil)
        
        if hitResults.count > 0
        {
            let result = hitResults.first
            if let node = result?.node
            {
                if node.name != nil
                {
                    var fs_node: FSNode
                    let check = node.name!.components(separatedBy: "//")
                    if check.count > 1
                    {
                        var path_arr = node.name!.components(separatedBy: "/")
                        var path = ""
                        for p in path_arr{ if p != "" && p != "sun" {path += ("/" + p)}}
                        if path == "/Users/nicoleolson" {return}
                        path_arr = path.components(separatedBy: "/")
                        path_arr.removeFirst()
                        path_arr.removeLast()
                        path = ""
                        for p in path_arr{ path += ("/" + p)}
                        fs_node = findNode(new_root_path: path, root: root)
                    }
                    else {fs_node = findNode(new_root_path: node.name!, root: root)}
                    if fs_node.kind == "NSFileTypeDirectory" { changeScene(node: fs_node) }
                    
                    // it has a name and a node was located and it's a file
                    else{print("opening . . .")}
                }
            }
        }
    }
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
    catch let _ as NSError {
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

func illustrate(root_of_scene: FSNode, path: String) -> SCNScene
{
    let scene = SCNScene(named: "space.scn")
    //scene?.background.contents = NSImage(named: "milkyway2")
    var textures = ["ceres2", "moon2", "saturn4", "mars2", "venus6",  "haumea2", "makemake2","jupiter_dark"]
    var textures2 = ["neptune", "mercury2","venus7", "eris2", "uranus3", "eclouds", "mars4","venus_surface"]
    
    let sun = makeSun(scene: scene!, path: path)
    var x_min = Double(350)
    var directories: [FSNode] = []
    var files: [FSNode] = []
    
    for childnode in root_of_scene.children
    {
        if childnode.kind == "NSFileTypeDirectory"{directories.append(childnode)}
        else{files.append(childnode)}
    }

    for d in directories
    {
        var count = 0
        for c in d.children { if c.kind == "NSFileTypeDirectory"{ count += 1}}
        d.subdirectory_count = count // set subdirectory count
    }
    
    directories.sort(by: { $0.subdirectory_count < $1.subdirectory_count })
    
    let dir_count = directories.count
    let astroid_count = files.count
    
    let astroid_scene1 = SCNScene(named: "fullsize_astroid.dae")
    let node = astroid_scene1?.rootNode.childNode(withName: "Sphere", recursively: true)
    //let astroid_scene2 = SCNScene(named: "quarter_asteroid.dae")
    //let node2 = astroid_scene2?.rootNode.childNode(withName: "Cube", recursively: true)
    let astroid_scene3 = SCNScene(named: "Asteroid_Small_6X.dae")
    let node3 = astroid_scene3?.rootNode.childNode(withName: "Aster_Small_4_", recursively: true)
    
    let node2 = node3
    let node4 = node3
    //let astroid_scene4 = SCNScene(named: "tq_astroid.dae")
    //let node4 = astroid_scene4?.rootNode.childNode(withName: "Cube", recursively: true)
    
    if dir_count == 0 && astroid_count == 0 {return scene!}
    var first_directories = [FSNode]()
    var second_directories = [FSNode]()
    
    if dir_count > 0
    {
        for i in 0...dir_count/2 {first_directories.append(directories[i])}
        for i in dir_count/2...dir_count-1{second_directories.append(directories[i])}
    }
    
    var first_astroids = [FSNode]()
    var second_astroids = [FSNode]()
    
    if astroid_count > 10
    {
        for i in 0...astroid_count/2{first_astroids.append(files[i])}
        for i in astroid_count/2...astroid_count-1{second_astroids.append(files[i])}
    }
    else {first_astroids = files}
    

    x_min = makeDirectories(scene: scene!, sun: sun, x_min: x_min, directories: first_directories, textures: textures)


    x_min = makeAsteroids(scene: scene!, sun: sun, node: node!, node2: node2!, node3: node3!, node4: node4!, x_start: x_min, astroids: first_astroids)
    x_min = makeDirectories(scene: scene!, sun: sun, x_min: x_min, directories: second_directories, textures: textures2)
    x_min = makeAsteroids(scene: scene!, sun: sun, node: node!, node2: node2!, node3: node3!, node4: node4!, x_start: x_min, astroids: second_astroids)
    createStars(scene: scene!)
    addNebulas(scene: scene!)
    
    return scene!
}

func makeDirectories(scene: SCNScene, sun: SCNNode, x_min: Double, directories: Array<FSNode>, textures: Array<String>) -> Double
{
    var count = 0
    var x_s = x_min
    var illustration_lenght = Double(0)
    var texture_count = 0
    
    for directory in directories
    {
        print(directory.name + ": image is: " + textures[texture_count])
        count += 1
        if count == 4 { count = 1 }

        let helper = SCNNode()
        helper.position = SCNVector3(x:0,y:0,z:0)
        let helper2 = SCNNode()
        helper2.position = SCNVector3(x:0,y:0,z:0)

        let planet = makePlanet(is_moon: false, name: directory.path, texture_type: "image", texture: textures[texture_count], radius: Float(dir_radius))
        
        scene.rootNode.addChildNode(planet)
        scene.rootNode.addChildNode(helper)
        sun.addChildNode(planet)
        sun.addChildNode(helper)
        helper.addChildNode(planet)
        helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(400))))
        
        var subdirectories = 0
        for dc in directory.children { if dc.kind == "NSFileTypeDirectory"{subdirectories += 1}}
        let num_children = subdirectories
        if num_children > 15 {illustration_lenght = (Double(num_children) * Double(2.3)) + Double(30)}
        else {illustration_lenght = Double(3.0 * (Float(num_children) * 5)) + Double(30)}
        let distance_from_sun = x_s + (illustration_lenght / Double(2)) // find center
        let torus = makeTorus(distance_from_sun: distance_from_sun)
        scene.rootNode.addChildNode(torus)
        x_s += illustration_lenght
        
        positionNodeAtDistance(node: planet, distance: distance_from_sun, count: count, hasY: false)
        
        let text_node = makeText(scene: scene, text: directory.name, size: 16, color: "purple")
        planet.addChildNode(text_node)
        let x_offset = calculateTextOffset_X(length: directory.name.count, size: 16)
        let y_offset = calculateTextOffset_Y(radius: Double(dir_radius))
        text_node.position = SCNVector3(x: CGFloat(x_offset), y: CGFloat(y_offset), z: 0)
        texture_count += 1
        if texture_count == textures.count {texture_count = 0}
        
        if num_children > 0 {makeMoons(scene: scene, distance: distance_from_sun, planet: planet, directory: directory)}
    }
    
    return x_s
}

func makeMoons(scene: SCNScene, distance: Double, planet: SCNNode, directory: FSNode)
{
    var inner_count = 0
    var moon_count = 0
    var distance_from_planet = 25.0
    var duration = 10.0
    let m = ["m1.png","m2.png","m3.png","m4.png","m5.png","m6.png","m7.png","m8.png"]
    
    for element in directory.children
    {
        inner_count += 1
        moon_count += 1
        if inner_count > 4 {inner_count = 1}
        if moon_count == 6 {moon_count = 0}
        let helper = SCNNode() // need to set size?
        helper.position = SCNVector3(x:0,y:0,z:0)
        
        var moon: SCNNode
        if element.kind == "NSFileTypeDirectory"
        {
            moon = makePlanet(is_moon: true, name: element.path, texture_type: "image", texture: m[moon_count], radius: Float(moon_radius))
            scene.rootNode.addChildNode(moon)
            scene.rootNode.addChildNode(helper)

            var name = ""
            
            if element.name.count > 12
            {
                var count = 1
                for letter in element.name
                {
                    name = name + String(letter)
                    count = count + 1
                    if count == 12
                    {
                        name = name + "\n"
                    }
                }
            }
            else {name = element.name}
            
            
            let text_node = makeText(scene: scene, text: name, size: 2, color: "green")
            moon.addChildNode(text_node)
            let x_offset = calculateTextOffset_X(length: element.name.count, size: 2)
            let y_offset = calculateTextOffset_Y(radius: Double(moon_radius))
            text_node.position = SCNVector3(x: CGFloat(x_offset), y: CGFloat(y_offset), z: 0)
            
            planet.addChildNode(moon)
            planet.addChildNode(helper)
            helper.addChildNode(moon)

            positionNodeAtDistance(node: moon, distance: distance_from_planet, count: inner_count, hasY: false)
            distance_from_planet += 5
            
            helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 5, z: 0, duration: Double(duration))))
            duration += 5
        }
    }
}

func makeAsteroids(scene: SCNScene, sun: SCNNode, node: SCNNode, node2: SCNNode, node3: SCNNode, node4: SCNNode, x_start: Double, astroids: Array<FSNode>) -> Double
{
    var x_s = x_start
    if astroids.count > 0 {x_s += 15} // extra space before the astroid belt
    var as_count = 0
    
    for astroid in astroids
    {
        as_count += 1
        if as_count == 5 {as_count = 1}
        let new_node = node.clone()
        let helper = SCNNode()
        
        helper.position = SCNVector3(x:0,y:0,z:0)
        scene.rootNode.addChildNode(new_node)
        scene.rootNode.addChildNode(helper)
        sun.addChildNode(new_node)
        sun.addChildNode(helper)
        helper.addChildNode(new_node)
        
        let speed = Int(Int.random(in: Int(30)..<Int(90)))
        helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(speed))))
        
        positionNodeAtDistance(node: new_node, distance: x_s, count: as_count, hasY: false)
        x_s += 2
        var name = ""
        
        if astroid.name.count > 12
        {
            var count = 1
            for letter in astroid.name
            {
                name = name + String(letter)
                count = count + 1
                if count == 12
                {
                    name = name + "\n"
                }
            }
        }
        else {name = astroid.name}
        
        let text_node = makeText(scene: scene, text: name, size: 6, color: "red")
        new_node.addChildNode(text_node)
        new_node.addChildNode(text_node)
        
        x_s = makeSubAsteroids(scene: scene, sun: sun, node2: node2, node3: node3, node4: node4, x: x_s, count: 30)
    }
    
    if astroids.count > 0 {x_s += 15} // extra space after the astroid belt
    return x_s
}

// non-files decorative astroid belt content, do not advance x_min, vary in z for every x of a real file
func makeSubAsteroids(scene: SCNScene, sun: SCNNode, node2: SCNNode, node3: SCNNode, node4: SCNNode, x: Double, count: Int) -> Double
{
    var x_s = x
    var sa_count = 0
    for i in 1...count
    {
        sa_count += 1
        if sa_count == 5 {sa_count = 1}
        var qnode = node2.clone()
        if i % 2 == 0 {qnode = node4.clone()}
        if i % 3 == 0 {qnode = node3.clone()}
        let helper = SCNNode()
        helper.position = SCNVector3(x:0,y:0,z:0)
        scene.rootNode.addChildNode(qnode)
        scene.rootNode.addChildNode(helper)
        sun.addChildNode(qnode)
        sun.addChildNode(helper)
        helper.addChildNode(qnode)
        let speed = Int(Int.random(in: Int(90)..<Int(170)))
        positionNodeAtDistance(node: qnode, distance: x_s, count: sa_count, hasY: true)
        x_s += 0.01
        helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(speed))))
    }
    
    return x_s
}

func addNebulas(scene: SCNScene)
{
    // make stars below and above
    //let x = Int(Double(Float.random(in: Float(1000)..<Float(6000))))
    //let y = Int(Double(Float.random(in: Float(0)..<Float(5000))))
    //let z = Int(Double(Float.random(in: Float(1000)..<Float(6000))))
    let cubeGeometry = SCNSphere(radius: 5000)
    
    let sphereMaterial = SCNMaterial()
    sphereMaterial.locksAmbientWithDiffuse = true
    sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
    sphereMaterial.diffuse.contents = "nebula3"
    sphereMaterial.transparency = 0.01
    cubeGeometry.materials = [sphereMaterial]
    let sphere1 = SCNNode(geometry: cubeGeometry)
    
    scene.rootNode.addChildNode(sphere1)
    sphere1.position = SCNVector3(x: CGFloat(500000), y: CGFloat(0), z: CGFloat(500000))
    
    var parentx = 500000
    var parentz = 500000
    var parenty = 0
    
    
    for i in 1...10
    {
        
        let x = Int(Double(Float.random(in: Float(1000000)..<Float(2000000))))
        let y = Int(Double(Float.random(in: Float(1)..<Float(10000))))
        let z = Int(Double(Float.random(in: Float(1000000)..<Float(2000000))))
        
        let cubeGeometry = SCNSphere(radius: CGFloat(50000 + (i*500)))
        
        let sphereMaterial = SCNMaterial()
        sphereMaterial.locksAmbientWithDiffuse = true
        sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
        sphereMaterial.diffuse.contents = "nebula3"
        sphereMaterial.transparency = 0.005
        if i % 3 == 0
        {
            sphereMaterial.diffuse.contents = "nebula4"
            sphereMaterial.transparency = 0.001
        }
        cubeGeometry.materials = [sphereMaterial]
        let child_sphere1 = SCNNode(geometry: cubeGeometry)
        
        scene.rootNode.addChildNode(child_sphere1)
        //child_sphere1.position = SCNVector3(x: CGFloat(50000), y: CGFloat(0), z: CGFloat(50000))
        
        sphere1.addChildNode(child_sphere1)
        if i % 2 == 0
        {
            child_sphere1.position = SCNVector3(x: CGFloat(parentx + x), y: CGFloat(parenty + y), z: CGFloat(parentz + z))
        }
        else {child_sphere1.position = SCNVector3(x: CGFloat(parentx - x), y: CGFloat(parenty - y), z: CGFloat(parentz - z))}
        
    }
    
    /*
    for _ in 1...1
    {
        print("making nebula")
        let x = Int(Double(Float.random(in: Float(500)..<Float(600))))
        let y = Int(Double(Float.random(in: Float(0)..<Float(50))))
        let z = Int(Double(Float.random(in: Float(500)..<Float(600))))
        let cubeGeometry = SCNBox(width: 100, height: 1, length: 100, chamferRadius: 5)
        
        let sphereMaterial = SCNMaterial()
        sphereMaterial.locksAmbientWithDiffuse = true
        sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
        sphereMaterial.diffuse.contents = "nebula3"
        sphereMaterial.transparency = 0.002
        //sphereMaterial.selfIllumination = 1
        cubeGeometry.materials = [sphereMaterial]
        let sphere1 = SCNNode(geometry: cubeGeometry)
        
        scene.rootNode.addChildNode(sphere1)
        sphere1.position = SCNVector3(x: CGFloat(10000), y: CGFloat(0), z: CGFloat(5000))
    }*/
}

/*
 sphere1.light = SCNLight()
 sphere1.light!.type = SCNLight.LightType.omni
 sphere1.light!.color = NSColor(calibratedRed: CGFloat(1), green: CGFloat(1), blue: CGFloat(0.8), alpha: CGFloat(1))
 sphere1.light!.attenuationStartDistance = 10
 sphere1.light!.temperature = 5500
 sphere1.light!.intensity = 100000
 */



func createStars(scene: SCNScene)
{

    var x1: Int
    var y1: Int
    var z1: Int
    var x2: Int
    var y2: Int
    var z2: Int
    var x3: Int
    var y3: Int
    var z3: Int
    var x: Int
    var y: Int
    var z: Int
    var duration = 10.0
    
    // make stars below and above
    for i in 1...10000
    {
        
        x1 = Int(Double(Float.random(in: Float(-1000)..<Float(-50))))
        y1 = Int(Double(Float.random(in: Float(-1000)..<Float(-200))))
        z1 = Int(Double(Float.random(in: Float(-1000)..<Float(-5))))
        x2 = Int(Double(Float.random(in: Float(50)..<Float(1000))))
        y2 = Int(Double(Float.random(in: Float(20)..<Float(500))))
        z2 = Int(Double(Float.random(in: Float(5)..<Float(1000))))
        x3 = Int(Double(Float.random(in: Float(1000)..<Float(10000))))
        y3 = Int(Double(Float.random(in: Float(500)..<Float(5000))))
        z3 = Int(Double(Float.random(in: Float(1000)..<Float(10000))))
        
        let a = Int(Int.random(in: Int(0)..<Int(6)))
        if a == 0 {x = x1}else if a == 1{x = x2}else{x = x3}
        let b = Int(Int.random(in: Int(0)..<Int(6)))
        if b == 0 {y = y1}else if b == 1{y = y2}else{y = y3}
        let c = Int(Int.random(in: Int(0)..<Int(6)))
        if c == 0 {z = z1}else if c == 1{z = z2}else{z = z3}
        
        let sphereGeometry = SCNSphere(radius: CGFloat(0.05))
        
        let sphereMaterial = SCNMaterial()
        sphereMaterial.locksAmbientWithDiffuse = true
        sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
        sphereMaterial.diffuse.contents = "starcolor2.png"
        
        //if i % 12 == 0 { sphereMaterial.diffuse.contents = NSColor.purple }
        //if i % 16 == 0 { sphereMaterial.diffuse.contents = NSColor.blue }
        //if i % 10 == 0 { sphereMaterial.diffuse.contents = NSColor.red }
        
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

// sun has scene lighting
func makeSun(scene: SCNScene, path: String) -> SCNNode
{
    let sun_name = path + "//sun"
    let sun = makePlanet(is_moon: false, name: sun_name, texture_type: "image", texture: "sun.png", radius: Float(sun_radius))
    scene.rootNode.addChildNode(sun)
    sun.position = SCNVector3(x: 0, y: 0, z: 0)
    let sun_halo = makePlanet(is_moon: false, name: sun_name, texture_type: "solid", texture: "NSyellow", radius: Float(sun_radius - 0.1))
    scene.rootNode.addChildNode(sun_halo)
    sun_halo.position = SCNVector3(x: 0, y: 0, z: 0)
    let sun_halo2 = makePlanet(is_moon: false, name: sun_name, texture_type: "solid", texture: "NSorange", radius: Float(sun_radius - 0.2))
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
    sphere_material.isLitPerPixel = false
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
            sphere_material.shininess = 10
            sphere_material.diffuse.contents = "ss11.png"
            sphere_material.normal.contents = "ss7.png"
        }
        else
        {
            if !is_moon
            {
                sphere_material.shininess = 2
                sphere_material.diffuse.contents = texture
                sphere_material.emission.contents = texture
                sphere_material.emission.intensity = 0.2
            }
            else
            {
                sphere_material.diffuse.contents = texture
                sphere_material.emission.contents = texture
                sphere_material.emission.intensity = 0.2
                sphere_material.transparency = 0.5
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

func makeText(scene: SCNScene, text: String, size: Float, color: String) -> SCNNode
{
    
    //let text = scene.rootNode.childNode(withName: "text node", recursively: true)!
    let text_material = SCNMaterial()
    text_material.ambient.contents = NSColor.blue
    text_material.diffuse.contents = NSColor.white
    text_material.specular.contents = NSColor.red
    text_material.lightingModel = SCNMaterial.LightingModel.physicallyBased
    text_material.shininess = 0.5
    let text_geometry = SCNText(string: text, extrusionDepth: CGFloat(0))
    text_geometry.font = NSFont(name: "Courier New",size: CGFloat(size))
    text_geometry.materials = [text_material]
    let text = SCNNode(geometry: text_geometry)
    
    if color == "purple" {text.geometry?.materials.first?.diffuse.contents = NSImage(named: "starcolor2.png")}
    else if color == "green" {text.geometry?.materials.first?.diffuse.contents = NSImage(named: "gp_grad.png")}
    else if color == "red" {text.geometry?.materials.first?.diffuse.contents = NSImage(named: "op_grad.png")}
    
    //if color == "green" {text_geometry.firstMaterial?.diffuse.contents = NSColor.green}
    //else {text_geometry.firstMaterial?.diffuse.contents = NSColor.orange}
    
    //text.geometry?.materials.first?.diffuse.contents = NSImage(named: "starcolor2.png")
    return text
    
    /*
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
    return SCNNode(geometry: text_geometry)*/
}

func makeTorus(distance_from_sun: Double) -> SCNNode
{
    let torus_geometry = SCNTorus(ringRadius: CGFloat(distance_from_sun), pipeRadius: CGFloat(0.01))
    let torus_material = SCNMaterial()
    torus_material.transparency = 0.01 // brightness of sun illuminates
    torus_geometry.materials = [torus_material]
    return SCNNode(geometry: torus_geometry)
}

func positionNodeAtDistance(node: SCNNode, distance: Double, count: Int, hasY: Bool)
{
    let start_x: Double
    let start_z: Double
    var a = Double(0)
    
    if count == 1 {a = Double(Float.random(in: Float(0)..<Float(85)))}
    
    if count == 2 {a = Double(Float.random(in: Float(95)..<Float(175)))}
    
    if count == 3 {a = Double(Float.random(in: Float(185)..<Float(265)))}
    
    if count == 4 {a = Double(Float.random(in: Float(275)..<Float(355)))}
    
    start_x = 0 + distance * cos(a) // x = cx + r * cos(a)
    start_z = 0 + distance * sin(a) // y = cy + r * sin(a)
    
    if hasY // vary y position by -10 to + 10 random based on count
    {
        var y = Double(0)
        
        if count == 1 {y = Double(Float.random(in: Float(-5)..<Float(-2)))}
        
        if count == 2 {y = Double(Float.random(in: Float(-2)..<Float(0)))}
        
        if count == 3 {y = Double(Float.random(in: Float(0)..<Float(2)))}
        
        if count == 4 {y = Double(Float.random(in: Float(2)..<Float(5)))}
        
        node.position = SCNVector3(x: CGFloat(start_x), y: CGFloat(y), z: CGFloat(start_z))
    }
    else {node.position = SCNVector3(x: CGFloat(start_x), y: 0, z: CGFloat(start_z))}
}

// helper function to calculate the text offset based on font size and number of letters
func calculateTextOffset_X(length: Int, size: Float) -> Float
{
    let halfLetterWidth = Double(length)/2.0
    if size == 16 { return Float(-8.5 * halfLetterWidth) }
    else { return Float(-1.1 * halfLetterWidth) }
}

func calculateTextOffset_Y(radius: Double) -> Double
{
    if radius == 10 { return 9.2}
    if radius == 20 { return 19.2}
    return 1
}

// name is a path
func findNode(new_root_path: String, root: FSNode) -> FSNode
{
    var path_dir_arr = getArrFromPath(path: new_root_path)
    
    if path_dir_arr.count == 0 {return root}
    
    path_dir_arr.removeFirst(1) // first is ""
    
    var fs_node = root
    
    var root_paths = root.path.components(separatedBy: "/")
    
    root_paths.removeFirst(1)
    
    let size = root_paths.count
    
    if path_dir_arr.count >= root_paths.count {path_dir_arr.removeFirst(size)}
    var i = 0
    
    if path_dir_arr.count > 0
    {
        while fs_node.path != new_root_path
        {
            // get the children of fs_node
            let children = fs_node.children
            // go through them until you find the next thing in path_dir_arr
            for child in children
            {
                let child_name_arr = child.path.components(separatedBy: "/")
                let child_name = child_name_arr[child_name_arr.count - 1]
                if child_name == path_dir_arr[i]
                {
                    i += 1
                    fs_node = child
                    break
                }
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
        self.child_count = -1
        self.subdirectory_count = -1
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
        else
        {
            self.child_count = 0 // 0 means it is a leaf, -1 means it may be a leaf but could just not be filled out yet
        }
    }
    
    // non-recursing init used in adding 1 depth to a particular branch
    init(name: String, kind: String, path: String, depth: Int, parent: FSNode)
    {
        self.kind = kind
        self.name = name
        self.path = path
        self.children = []
        self.child_count = -1
        self.subdirectory_count = -1
        self.depth = depth
        self.parent = parent
    }
    
    // class properties
    var kind: String
    var name: String
    var path: String
    var children: [FSNode] = []
    var child_count: Int
    var subdirectory_count: Int
    var depth: Int
    weak var parent: FSNode?

    // take a parent and create its children
    func addChildren(parent: FSNode)
    {
        if parent.child_count == -1 // verify that this parent has no attempted children
        {
            let children = getCDContents(path: parent.path, full: false)
            
            // if there are children to add
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
                    
                    let newFSNode = FSNode(name: c, kind: fileType, path: parent.path + "/" + c, depth: parent.depth + 1, parent: parent)
                    newFSNode.parent = parent
                    parent.children.append(newFSNode)
                }
                parent.child_count = parent.children.count
            }
            else
            {
                parent.child_count = 0 // otherwise this parent is a leaf
            }
        }
        
        return
    }
}

