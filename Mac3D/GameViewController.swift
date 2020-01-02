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
let sun_radius = 34.0
let dir_radius = 10.0
let moon_radius = 1.5
var scenes = [String: SCNScene]() // stores illustrated scenes

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
        cameraNode.position = SCNVector3Make(0, 0, 100) // need to make last value dynamic
        scene.rootNode.addChildNode(cameraNode)

        sceneView.scene = scene // when the scene changes you change this on the sceneView
        sceneView.delegate = self as! SCNSceneRendererDelegate // sets the delegate of the Scene Kit view to self. So that the view can call the
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
    let sun = makeSun(scene: scene!, path: path)
    var x_min = Double(70)
    var directories: [FSNode] = []
    var files: [FSNode] = []
    
    for childnode in root_of_scene.children
    {
        if childnode.kind == "NSFileTypeDirectory"{directories.append(childnode)}
        else{files.append(childnode)}
    }

    directories.sort(by: { $0.child_count < $1.child_count })
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
    
    var first_directories = [FSNode]()
    for i in 0...dir_count/2 - 1 {first_directories.append(directories[i])}
    var second_directories = [FSNode]()
    for i in dir_count/2...dir_count-1{second_directories.append(directories[i])}
    var first_astroids = [FSNode]()
    var second_astroids = [FSNode]()
    
    if astroid_count > 10
    {
        for i in 0...astroid_count/2{first_astroids.append(files[i])}
        for i in astroid_count/2...astroid_count-1{second_astroids.append(files[i])}
    }
    else {first_astroids = files}
    
    x_min = makeDirectories(scene: scene!, sun: sun, x_min: x_min, directories: first_directories)
    x_min = makeAsteroids(scene: scene!, sun: sun, node: node!, node2: node2!, node3: node3!, node4: node4!, x_start: x_min, astroids: first_astroids)
    x_min = makeDirectories(scene: scene!, sun: sun, x_min: x_min, directories: second_directories)
    x_min = makeAsteroids(scene: scene!, sun: sun, node: node!, node2: node2!, node3: node3!, node4: node4!, x_start: x_min, astroids: second_astroids)
    createStars(scene: scene!)
    addNebulas(scene: scene!)
    
    return scene!
}

func makeDirectories(scene: SCNScene, sun: SCNNode, x_min: Double, directories: Array<FSNode>) -> Double
{
    var count = 0
    var x_s = x_min
    for directory in directories
    {
        count += 1
        if count == 4 { count = 1 }

        let helper = SCNNode()
        helper.position = SCNVector3(x:0,y:0,z:0)
        let helper2 = SCNNode()
        helper2.position = SCNVector3(x:0,y:0,z:0)

        let planet = makePlanet(is_moon: false, name: directory.path, texture_type: "image", texture: "Nothing", radius: Float(dir_radius))
        
        scene.rootNode.addChildNode(planet)
        scene.rootNode.addChildNode(helper)
        sun.addChildNode(planet)
        sun.addChildNode(helper)
        helper.addChildNode(planet)
        helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(300))))
        
        var subdirectories = 0
        for dc in directory.children { if dc.kind == "NSFileTypeDirectory"{subdirectories += 1}}
        let num_children = subdirectories
        let illustration_lenght = Double(4.0 * (Float(num_children) * 5)) + Double(10)
        let distance_from_sun = x_s + (illustration_lenght / Double(2)) // find center
        let torus = makeTorus(distance_from_sun: distance_from_sun)
        scene.rootNode.addChildNode(torus)
        x_s += illustration_lenght
        
        positionNodeAtDistance(node: planet, distance: distance_from_sun, count: count)
        
        let text_node = makeText(text: directory.name, size: 4, color: "green")
        planet.addChildNode(text_node)
        let x_offset = calculateTextOffset_X(length: directory.name.count, size: 4)
        let y_offset = calculateTextOffset_Y(radius: Double(dir_radius))
        text_node.position = SCNVector3(x: CGFloat(x_offset), y: CGFloat(y_offset), z: 0)
        
        if num_children > 0 {makeMoons(scene: scene, distance: distance_from_sun, planet: planet, directory: directory)}
    }
    
    return x_s
}

func makeMoons(scene: SCNScene, distance: Double, planet: SCNNode, directory: FSNode)
{
    var inner_count = 0
    var moon_count = 0
    var distance_from_planet = 15.0
    var duration = 10.0
    let m = ["m1.png","m2.png","m3.png","m4.png","m5.png","m6.png","m7.png","m8.png"]
    
    for element in directory.children
    {
        duration += 0.05
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

            let text_node = makeText(text: element.name, size: 0.2, color: "green")
            moon.addChildNode(text_node)
            let x_offset = calculateTextOffset_X(length: element.name.count, size: 0.05)
            let y_offset = calculateTextOffset_Y(radius: Double(moon_radius))
            text_node.position = SCNVector3(x: CGFloat(x_offset), y: CGFloat(y_offset), z: 0)
            
            planet.addChildNode(moon)
            planet.addChildNode(helper)
            helper.addChildNode(moon)

            positionNodeAtDistance(node: moon, distance: distance_from_planet, count: inner_count)
            distance_from_planet += 0.5
            
            helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 5, z: 0, duration: Double(duration * 5))))
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
        
        positionNodeAtDistance(node: new_node, distance: x_s, count: as_count)
        x_s += 2
        
        let text_node = makeText(text: astroid.name, size: 2, color: "orange")
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
        positionNodeAtDistance(node: qnode, distance: x_s, count: sa_count)
        x_s += 0.01
        helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(speed))))
    }
    
    return x_s
}

func addNebulas(scene: SCNScene)
{
    // make stars below and above
    for _ in 1...1
    {
        print("making nebula")
        let x = Int(Double(Float.random(in: Float(500)..<Float(600))))
        let y = Int(Double(Float.random(in: Float(0)..<Float(50))))
        let z = Int(Double(Float.random(in: Float(500)..<Float(600))))
        let cubeGeometry = SCNBox(width: 500, height: 1000, length: 1, chamferRadius: 5)
        
        let sphereMaterial = SCNMaterial()
        sphereMaterial.locksAmbientWithDiffuse = true
        sphereMaterial.lightingModel = SCNMaterial.LightingModel.blinn
        sphereMaterial.diffuse.contents = "nebulaimage.jpg"
        sphereMaterial.transparency = 0.003
        cubeGeometry.materials = [sphereMaterial]
        let sphere1 = SCNNode(geometry: cubeGeometry)
        
        scene.rootNode.addChildNode(sphere1)
        sphere1.position = SCNVector3(x: CGFloat(x), y: CGFloat(y), z: CGFloat(z))
    }
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
                
                let color = Int.random(in: Int(0)..<Int(10))
                
                switch color
                {
                case 0:
                    sphere_material.diffuse.contents = NSColor.yellow
                    sphere_material.emission.contents = NSColor.yellow
                    sphere_material.transparency = 0.5
                case 1:
                    sphere_material.diffuse.contents = NSColor.magenta
                    sphere_material.emission.contents = NSColor.magenta
                    //sphere_material.transparency = 0.1
                case 2:
                    sphere_material.diffuse.contents = NSColor.red
                    sphere_material.emission.contents = NSColor.red
                    sphere_material.displacement.contents = "rock_displacement.jpg"
                    sphere_material.displacement.intensity = 0.3
                    //sphere_material.transparency = 0.1
                case 3:
                    sphere_material.diffuse.contents = NSColor.blue
                    sphere_material.emission.contents = NSColor.blue
                    sphere_material.displacement.contents = "rock_displacement.jpg"
                    sphere_material.displacement.intensity = 0.3
                    //sphere_material.transparency = 0.1
                case 4:
                    sphere_material.diffuse.contents = NSColor.orange
                    sphere_material.emission.contents = NSColor.orange
                    sphere_material.displacement.contents = "rock_displacement.jpg"
                    sphere_material.displacement.intensity = 0.3
                    //sphere_material.transparency = 0.1
                case 5:
                    sphere_material.diffuse.contents = NSColor.cyan
                    sphere_material.emission.contents = NSColor.cyan
                    sphere_material.displacement.contents = "rock_displacement.jpg"
                    sphere_material.displacement.intensity = 0.3
                case 6:
                    sphere_material.diffuse.contents = "b1.png"
                    sphere_material.emission.contents = "b1.png"
                    sphere_material.displacement.contents = "rock_displacement.jpg"
                    sphere_material.displacement.intensity = 0.3
                case 7:
                    sphere_material.diffuse.contents = NSColor.purple
                    sphere_material.emission.contents = NSColor.purple
                case 8:
                    sphere_material.diffuse.contents = NSColor.brown
                    sphere_material.emission.contents = NSColor.brown
                case 9:
                    sphere_material.diffuse.contents = "b2.png"
                    sphere_material.emission.contents = "b2.png"
                    sphere_material.displacement.contents = "rock_displacement.jpg"
                    sphere_material.displacement.intensity = 0.3
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
    let torus_geometry = SCNTorus(ringRadius: CGFloat(distance_from_sun), pipeRadius: CGFloat(0.01))
    let torus_material = SCNMaterial()
    torus_material.transparency = 0.01 // brightness of sun illuminates
    torus_geometry.materials = [torus_material]
    return SCNNode(geometry: torus_geometry)
}

func positionNodeAtDistance(node: SCNNode, distance: Double, count: Int)
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
    
    node.position = SCNVector3(x: CGFloat(start_x), y: 0, z: CGFloat(start_z))
}

// helper function to calculate the text offset based on font size and number of letters
func calculateTextOffset_X(length: Int, size: Float) -> Float
{
    let halfLetterWidth = Double(length)/2.0
    if size == 4 { return Float(-2.5 * halfLetterWidth) }
    else { return Float(-0.1 * halfLetterWidth) }
}

func calculateTextOffset_Y(radius: Double) -> Double
{
    if radius == 10 { return 9.2}
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
/*
 
 // for each directory
 for directory in directories
 {
 planet_count += 1
 //1print("planet count")
 //print(planet_count)
 if planet_count == mid_astroid_belt_position
 {
 addAstroids(files: files, x_start: x_min)
 
 var astroid_count = 0
 // compute the zone the astroid needs (like a giant torus)
 var astroid_x_min = x_min
 let astroid_x_max = x_min + Double(files.count + 2)
 let astroid_z_min = x_min
 let astroid_z_max = x_min + Double(files.count/2)
 var x_values = [Int]()
 var z_values = [Int]()
 
 var astroid_x_distance_from_sun: Double
 var astroid_z_distance_from_sun: Double
 
 // set x min for future planets
 x_min += x_min + Double(files.count/2) // x max
 var a: Double
 
 let astroid_scene1 = SCNScene(named: "a5.dae")
 let node = astroid_scene1?.rootNode.childNode(withName: "Cube", recursively: true)
 let astroid_scene2 = SCNScene(named: "quarter_asteroid.dae")
 let node2 = astroid_scene2?.rootNode.childNode(withName: "Cube", recursively: true)
 
 
 for astroid in files
 {
 let new_node = node!.clone()
 
 // increase x min each time so that they never overlap
 astroid_x_min += 1
 astroid_count += 1
 if astroid_count == 4 {astroid_count = 1}
 
 // generate a z distrance between zmin and z max
 astroid_z_distance_from_sun = Double(Int.random(in: Int(astroid_z_min)..<Int(astroid_z_max)))
 // generate a x distanace that is between xmin and x max
 astroid_x_distance_from_sun = Double(Int.random(in: Int(astroid_x_min)..<Int(astroid_x_max)))
 var a = Double(0)
 // generate an angle in the first quadrant
 if astroid_count == 1 {a = Double(Float.random(in: Float(0)..<Float(85)))}
 if astroid_count == 2 {a = Double(Float.random(in: Float(90)..<Float(175)))}
 if astroid_count == 3 {a = Double(Float.random(in: Float(180)..<Float(265)))}
 if astroid_count == 4 {a = Double(Float.random(in: Float(270)..<Float(355)))}
 
 // get the astroid a position allong a torus that is a particular distance
 let start_x = 0 + astroid_x_distance_from_sun * cos(a) // x = cx + r * cos(a)
 let start_z = 0 + astroid_z_distance_from_sun * sin(a) // y = cy + r * sin(a)
 
 // take unique position and create an astroid
 let helper = SCNNode()
 
 helper.position = SCNVector3(x:0,y:0,z:0)
 
 //let astroid = makeAstroid()
 scene!.rootNode.addChildNode(new_node)
 scene!.rootNode.addChildNode(helper)
 sun.addChildNode(new_node)
 sun.addChildNode(helper)
 helper.addChildNode(new_node)
 var speed = Int(Int.random(in: Int(5)..<Int(20)))
 
 helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(speed))))
 new_node.position = SCNVector3(x: CGFloat(start_x), y: 0, z: CGFloat(start_z))
 let text_node = makeText(text: "Astroid", size: 2, color: "orange")
 new_node.addChildNode(text_node)
 new_node.addChildNode(text_node)
 
 addSubAsteroids(scene: scene!, sun: sun, node: node2!, x: Int(start_x), z: Int(start_z), count: 100)
 }
 }
 
 count += 1
 if count == 4 { count = 1 }
 //if planet_count == 1 { planet_count = 0 }
 // create a planet
 let helper = SCNNode()
 helper.position = SCNVector3(x:0,y:0,z:0)
 let helper2 = SCNNode()
 helper2.position = SCNVector3(x:0,y:0,z:0)
 //print(directory.path)
 let planet = makePlanet(is_moon: false, name: directory.path, texture_type: "image", texture: "Nothing", radius: Float(dir_radius))
 scene!.rootNode.addChildNode(planet)
 scene!.rootNode.addChildNode(helper)
 sun.addChildNode(planet)
 sun.addChildNode(helper)
 helper.addChildNode(planet)
 helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(300))))
 
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
 scene!.rootNode.addChildNode(torus)
 
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
 //print("text node: " + directory.name)
 
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
 moon = makePlanet(is_moon: true, name: moons.path, texture_type: "image", texture: m[moon_count], radius: Float(moon_radius))
 scene!.rootNode.addChildNode(moon)
 scene!.rootNode.addChildNode(helper)
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
 helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 5, z: 0, duration: Double(duration * 10))))
 }
 }
 }
 
 // if we just made the last planet
 if planet_count == dir_count
 {
 print("making outer astroids")
 if outer_files.count != 0
 {
 var astroid_count = 0
 // compute the zone the astroid needs (like a giant torus)
 var astroid_x_min = x_min
 let astroid_x_max = x_min + Double(files.count + 2)
 let astroid_z_min = x_min
 let astroid_z_max = x_min + Double(files.count/2)
 //var x_values = [Int]()
 //var z_values = [Int]()
 
 var astroid_x_distance_from_sun: Double
 var astroid_z_distance_from_sun: Double
 
 // set x min for future planets
 x_min += x_min + Double(files.count/2) // x max
 
 }
 }
 }
 // for each directory
 for directory in directories
 {
 planet_count += 1
 //1print("planet count")
 //print(planet_count)
 if planet_count == mid_astroid_belt_position
 {
 addAstroids(files: files, x_start: x_min)
 
 var astroid_count = 0
 // compute the zone the astroid needs (like a giant torus)
 var astroid_x_min = x_min
 let astroid_x_max = x_min + Double(files.count + 2)
 let astroid_z_min = x_min
 let astroid_z_max = x_min + Double(files.count/2)
 var x_values = [Int]()
 var z_values = [Int]()
 
 var astroid_x_distance_from_sun: Double
 var astroid_z_distance_from_sun: Double
 
 // set x min for future planets
 x_min += x_min + Double(files.count/2) // x max
 var a: Double
 
 let astroid_scene1 = SCNScene(named: "a5.dae")
 let node = astroid_scene1?.rootNode.childNode(withName: "Cube", recursively: true)
 let astroid_scene2 = SCNScene(named: "quarter_asteroid.dae")
 let node2 = astroid_scene2?.rootNode.childNode(withName: "Cube", recursively: true)
 
 
 for astroid in files
 {
 let new_node = node!.clone()
 
 // increase x min each time so that they never overlap
 astroid_x_min += 1
 astroid_count += 1
 if astroid_count == 4 {astroid_count = 1}
 
 // generate a z distrance between zmin and z max
 astroid_z_distance_from_sun = Double(Int.random(in: Int(astroid_z_min)..<Int(astroid_z_max)))
 // generate a x distanace that is between xmin and x max
 astroid_x_distance_from_sun = Double(Int.random(in: Int(astroid_x_min)..<Int(astroid_x_max)))
 var a = Double(0)
 // generate an angle in the first quadrant
 if astroid_count == 1 {a = Double(Float.random(in: Float(0)..<Float(85)))}
 if astroid_count == 2 {a = Double(Float.random(in: Float(90)..<Float(175)))}
 if astroid_count == 3 {a = Double(Float.random(in: Float(180)..<Float(265)))}
 if astroid_count == 4 {a = Double(Float.random(in: Float(270)..<Float(355)))}
 
 // get the astroid a position allong a torus that is a particular distance
 let start_x = 0 + astroid_x_distance_from_sun * cos(a) // x = cx + r * cos(a)
 let start_z = 0 + astroid_z_distance_from_sun * sin(a) // y = cy + r * sin(a)
 
 // take unique position and create an astroid
 let helper = SCNNode()
 
 helper.position = SCNVector3(x:0,y:0,z:0)
 
 //let astroid = makeAstroid()
 scene!.rootNode.addChildNode(new_node)
 scene!.rootNode.addChildNode(helper)
 sun.addChildNode(new_node)
 sun.addChildNode(helper)
 helper.addChildNode(new_node)
 var speed = Int(Int.random(in: Int(5)..<Int(20)))
 
 helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(speed))))
 new_node.position = SCNVector3(x: CGFloat(start_x), y: 0, z: CGFloat(start_z))
 let text_node = makeText(text: "Astroid", size: 2, color: "orange")
 new_node.addChildNode(text_node)
 new_node.addChildNode(text_node)
 
 addSubAsteroids(scene: scene!, sun: sun, node: node2!, x: Int(start_x), z: Int(start_z), count: 100)
 }
 }
 
 count += 1
 if count == 4 { count = 1 }
 //if planet_count == 1 { planet_count = 0 }
 // create a planet
 let helper = SCNNode()
 helper.position = SCNVector3(x:0,y:0,z:0)
 let helper2 = SCNNode()
 helper2.position = SCNVector3(x:0,y:0,z:0)
 //print(directory.path)
 let planet = makePlanet(is_moon: false, name: directory.path, texture_type: "image", texture: "Nothing", radius: Float(dir_radius))
 scene!.rootNode.addChildNode(planet)
 scene!.rootNode.addChildNode(helper)
 sun.addChildNode(planet)
 sun.addChildNode(helper)
 helper.addChildNode(planet)
 helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: Double(300))))
 
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
 scene!.rootNode.addChildNode(torus)
 
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
 //print("text node: " + directory.name)
 
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
 moon = makePlanet(is_moon: true, name: moons.path, texture_type: "image", texture: m[moon_count], radius: Float(moon_radius))
 scene!.rootNode.addChildNode(moon)
 scene!.rootNode.addChildNode(helper)
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
 helper.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 5, z: 0, duration: Double(duration * 10))))
 }
 }
 }
 
 // if we just made the last planet
 if planet_count == dir_count
 {
 print("making outer astroids")
 if outer_files.count != 0
 {
 var astroid_count = 0
 // compute the zone the astroid needs (like a giant torus)
 var astroid_x_min = x_min
 let astroid_x_max = x_min + Double(files.count + 2)
 let astroid_z_min = x_min
 let astroid_z_max = x_min + Double(files.count/2)
 //var x_values = [Int]()
 //var z_values = [Int]()
 
 var astroid_x_distance_from_sun: Double
 var astroid_z_distance_from_sun: Double
 
 // set x min for future planets
 x_min += x_min + Double(files.count/2) // x max
 
 }
 }
 }
 */
