import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var grids = [Grid]()
    var PCoordx: Float = 0.0
    var PCoordy: Float = 0.0
    var PCoordz: Float = 0.0
    var paintingNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.scaleObject))
        self.view.addGestureRecognizer(pinchRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.moveObject))
        self.view.addGestureRecognizer(panRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
        let grid = Grid(anchor: planeAnchor)
        self.grids.append(grid)
        node.addChildNode(grid)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
        let grid = self.grids.filter { grid in
            return grid.anchor.identifier == planeAnchor.identifier
            }.first
        
        guard let foundGrid = grid else {
            return
        }
        
        foundGrid.update(anchor: planeAnchor)
    }
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        // Get 2D position of touch event on screen
        let touchPosition = gesture.location(in: sceneView)
        
        // Translate those 2D points to 3D points using hitTest (existing plane)
        let hitTestResults = sceneView.hitTest(touchPosition, types: .existingPlaneUsingExtent)
        
        // Get hitTest results and ensure that the hitTest corresponds to a grid that has been placed on a wall
        guard let hitTest = hitTestResults.first, let anchor = hitTest.anchor as? ARPlaneAnchor, let gridIndex = grids.index(where: { $0.anchor == anchor }) else {
            return
        }
        addPainting(hitTest, grids[gridIndex])
    }
    
    func addPainting(_ hitResult: ARHitTestResult, _ grid: Grid) {
        // 1.
        let planeGeometry = SCNPlane(width: 0.5, height: 0.35)
        let material = SCNMaterial()
        let srkGif = UIImage.gifImageWithName("123")
        let imageView = UIImageView(image: srkGif)
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        material.diffuse.contents = imageView
        planeGeometry.materials = [material]
        
        // 2.
        /*let audioItem = AVPlayerItem(url: URL(fileURLWithPath: Bundle.main.path(forResource: "SRK_audio", ofType: "mp3")!))
        
        let player = AVPlayer(playerItem: audioItem)
        player.play()
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
            player.seek(to: CMTime.zero)
            player.play()
            print("Looping Video")
        }*/
        let audioSource = SCNAudioSource(url: URL(fileURLWithPath: Bundle.main.path(forResource: "SRK_audio", ofType: "aac")!))
        audioSource!.loops = true
        audioSource!.load()
        
        
        // 3.
        paintingNode = SCNNode(geometry: planeGeometry)
        paintingNode.transform = SCNMatrix4(hitResult.anchor!.transform)
        paintingNode.eulerAngles = SCNVector3(paintingNode.eulerAngles.x + (-Float.pi / 2), paintingNode.eulerAngles.y, paintingNode.eulerAngles.z)
        paintingNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        paintingNode.addAudioPlayer(SCNAudioPlayer(source: audioSource!))
        
        sceneView.scene.rootNode.addChildNode(paintingNode)
        grid.removeFromParentNode()
    }
    
    @objc func scaleObject(gesture: UIPinchGestureRecognizer) {
        
        let location = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location)
        guard let nodeToScale = hitTestResults.first?.node else {
            return
        }
        
        if gesture.state == .changed {
            
            let pinchScaleX: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.x))
            let pinchScaleY: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.y))
            let pinchScaleZ: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.z))
            nodeToScale.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            gesture.scale = 1
            
        }
        if gesture.state == .ended { }
        
    }
    
    @objc func moveObject(gesture: UIPanGestureRecognizer) {
        /*gesture.minimumNumberOfTouches = 1
         
         let results = self.sceneView.hitTest(gesture.location(in: gesture.view), types: ARHitTestResult.ResultType.featurePoint)
         guard let result: ARHitTestResult = results.first else {
         return
         }
         
         let position = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
         planeNode.position = position
         */
        /*let location = gesture.location(in: sceneView)
         let hitTestResults = sceneView.hitTest(location)
         guard let nodeToMove = hitTestResults.first?.node else {
         return
         }
         if gesture.state == .began {
         print("1")
         
         }
         
         if gesture.state == .changed {
         
         print("2")
         
         }
         if gesture.state == .ended { }*/
        switch gesture.state {
        case .began:
            let location = gesture.location(in: self.sceneView)
            guard let hitNodeResult = self.sceneView.hitTest(location,
                                                             options: nil).first else { return }
            self.PCoordx = hitNodeResult.worldCoordinates.x
            self.PCoordy = hitNodeResult.worldCoordinates.y
            self.PCoordz = hitNodeResult.worldCoordinates.z
            print("1")
        case .changed:
            // when you start to pan in screen with your finger
            // hittest gives new coordinates of touched location in sceneView
            // coord-pcoord gives distance to move or distance paned in sceneview
            print("2")
            let hitNode = sceneView.hitTest(gesture.location(in: sceneView), options: nil)
            if let coordx = hitNode.first?.worldCoordinates.x,
                let coordy = hitNode.first?.worldCoordinates.y,
                let coordz = hitNode.first?.worldCoordinates.z {
                let action = SCNAction.moveBy(x: CGFloat(coordx - self.PCoordx),
                                              y: CGFloat(coordy - self.PCoordy),
                                              z: CGFloat(coordz - self.PCoordz),
                                              duration: 0.0)
                self.paintingNode.runAction(action)
                
                self.PCoordx = coordx
                self.PCoordy = coordy
                self.PCoordz = coordz
            }
            
            gesture.setTranslation(CGPoint.zero, in: self.sceneView)
        default:
            break
        }
    }
}
