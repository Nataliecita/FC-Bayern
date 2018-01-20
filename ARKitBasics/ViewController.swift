/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit

import Vision

//FOR ADDING A FOCUS SQUARE: https://github.com/gao0122/ARKit-Example-by-Apple

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
	// MARK: - IBOutlets

    @IBOutlet weak var sessionInfoView: UIView!
	@IBOutlet weak var sessionInfoLabel: UILabel!
	@IBOutlet weak var sceneView: ARSCNView!
    
//------------------------- CONSTANTS -------------------------
    let mWidthOf2DScreen = CGFloat(0.8)
    let mHeightOf2DScreen = CGFloat(0.45)
    
//------------------------- SOME BASIC CONFIG STUFF ------------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }

        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

        sceneView.session.delegate = self
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
        */
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
        
        
        sceneView.debugOptions.insert(ARSCNDebugOptions.showFeaturePoints)
        sceneView.debugOptions.insert(ARSCNDebugOptions.showWorldOrigin)
        
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Pause the view's AR session.
		sceneView.session.pause()
	}
	
    
// -------------------------------- HERE THE NEW STUFF IS RENDERED AND OTHER STUFF - DON'T CARE ABOUT THIS -------------------------
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("Renderer did add \(self.getTimeString())")
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            print("Renderer return")
            return }
        

        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        
        
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, so
         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        */
        planeNode.eulerAngles.x = -.pi / 2
        
        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 0.25
        
        /*
         Add the plane visualization to the ARKit-managed node so that it tracks
         changes in the plane anchor as plane estimation continues.
        */
        node.addChildNode(planeNode)
	}

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("Renderer did update \(self.getTimeString())")
        
        
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else {
                print("Renderer return")
                return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
        */
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
  

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        //print("Session did add anchor \(self.getTimeString())")
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        //print("Session did remove anchor \(self.getTimeString())")
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //print("Session did change tracking state anchor \(self.getTimeString())")
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver
	
	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay.
		sessionInfoLabel.text = "Session was interrupted"
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required.
		sessionInfoLabel.text = "Session interruption ended"
		resetTracking()
	}
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }

    // MARK: - Private methods

    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal surfaces."
            
        case .normal:
            // No feedback needed when tracking is normal and planes are visible.
            message = ""
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        }

        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }

    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func getTimeString() -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanosecond = calendar.component(.nanosecond, from: date)
        
        return "\(hour) \(minutes) \(seconds) \(nanosecond)"
    }
    
    
    
    
//------------------------------------ HERE THE REAL STUFF IS DONE ------------------------------------------------------
    
    
// ------------------------------------ THIS IS ALL ABOUT DETECTION RECTANGLES ON A EXISTING PLANE ------------------------------------------------------
    
    
    func initRectangleDetectionRequestOnExistingPlane(frame: ARFrame) -> VNDetectRectanglesRequest{
        
        
        let rectangleDetectionRequest = VNDetectRectanglesRequest(completionHandler: {(request: VNRequest, error: Error?) in
            
            //------------------ HANDLE TEXT RECTANGLE REQUEST -----------------------
            print("InitRectangleDetectionRequest HANDLER")
            guard let observations = request.results else {
                print("no result")
                return
            }
            
            let result = observations.map({$0 as? VNRectangleObservation})
            
            for observation in result {
                if let observation = observation {
                    let hitResultTopLeftArray = frame.hitTest(observation.topLeft.invert(), types: [.existingPlane, .estimatedHorizontalPlane])
                    let hitResultTopRightArray = frame.hitTest(observation.topRight.invert(), types: [.existingPlane, .estimatedHorizontalPlane])
                    let hitResultBottomLeftArray = frame.hitTest(observation.bottomLeft.invert(), types: [.existingPlane, .estimatedHorizontalPlane])
                    let hitResultBottomRightArray = frame.hitTest(observation.bottomRight.invert(), types: [.existingPlane, .estimatedHorizontalPlane])
                    guard let hitResultTopLeft = hitResultTopLeftArray.first else {
                        continue
                    }
                    guard let hitResultTopRight = hitResultTopRightArray.first else {
                        continue
                    }
                    guard let hitResultBottomLeft = hitResultBottomLeftArray.first else {
                        continue
                    }
                    guard let hitResultBottomRight = hitResultBottomRightArray.first else {
                        continue
                    }
                    
                    let topLeftVector = SCNVector3Make(hitResultTopLeft.worldTransform.columns.3.x, hitResultTopLeft.worldTransform.columns.3.y, hitResultTopLeft.worldTransform.columns.3.z)
                    let topRightVector = SCNVector3Make(hitResultTopRight.worldTransform.columns.3.x, hitResultTopRight.worldTransform.columns.3.y, hitResultTopRight.worldTransform.columns.3.z)
                    let bottomLeftVector = SCNVector3Make(hitResultBottomLeft.worldTransform.columns.3.x, hitResultBottomLeft.worldTransform.columns.3.y, hitResultBottomLeft.worldTransform.columns.3.z)
                    let bottomRightVector = SCNVector3Make(hitResultBottomRight.worldTransform.columns.3.x, hitResultBottomRight.worldTransform.columns.3.y, hitResultBottomRight.worldTransform.columns.3.z)
                    
                    print("Create new Letter - \(topLeftVector)  \(topRightVector) \(bottomLeftVector) \(bottomRightVector)")
                    
                    
                    //Place object
                    let plane = SCNPlane(width: CGFloat((bottomRightVector-bottomLeftVector).length()), height: CGFloat((bottomLeftVector-topLeftVector).length()))
                    
                    let vectorToPlaneCenter = bottomRightVector+(topLeftVector-bottomRightVector)*0.5
                    let vectorToCenterOfRightSide = bottomRightVector+(topRightVector-bottomRightVector)*0.5
                    let rotationAxis = (bottomLeftVector-bottomRightVector).cross(vector: bottomLeftVector-topLeftVector)
                    
                    let rotationAxisCROSSRightSideVector = rotationAxis.cross(vector: topRightVector-bottomRightVector)
                    let rotationAxisCROSSToCenterOfRightSide = rotationAxis.cross(vector: vectorToCenterOfRightSide)
                    
                    let angle = acos((rotationAxisCROSSRightSideVector.dot(vector: rotationAxisCROSSToCenterOfRightSide))/(rotationAxisCROSSToCenterOfRightSide.length()*rotationAxisCROSSRightSideVector.length()))
                    
                    plane.firstMaterial?.diffuse.contents = UIColor.white
                    
                    let planeNode = SCNNode()
                    
                    planeNode.geometry = plane
                    planeNode.position = vectorToPlaneCenter
                    planeNode.rotation = SCNVector4Make(rotationAxis.x, rotationAxis.y, rotationAxis.z, angle) // ROTATION AXIS VECTOR SHOULD BE THE NORMAL VECTOR TO PLANE
                    
                    self.sceneView.scene.rootNode.addChildNode(planeNode)
                    
                    
                    
                    let lineLeft = SCNNode(geometry: SCNGeometry.lineForm(vector1: topLeftVector, vector2: bottomLeftVector))
                    lineLeft.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    let lineRight = SCNNode(geometry: SCNGeometry.lineForm(vector1: topRightVector, vector2: bottomRightVector))
                    lineRight.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                    let lineTop = SCNNode(geometry: SCNGeometry.lineForm(vector1: topLeftVector, vector2: topRightVector))
                    lineTop.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
                    let lineBottom = SCNNode(geometry: SCNGeometry.lineForm(vector1: bottomLeftVector, vector2: bottomRightVector))
                    self.sceneView.scene.rootNode.addChildNode(lineLeft)
                    self.sceneView.scene.rootNode.addChildNode(lineRight)
                    self.sceneView.scene.rootNode.addChildNode(lineTop)
                    self.sceneView.scene.rootNode.addChildNode(lineBottom)
                }
            }
            
            //------------------ HANDLE TEXT RECTANGLE REQUEST -----------------------
            
        })
        
        
        return rectangleDetectionRequest
    }
    
    
// ------------------------------------ THIS IS ALL ABOUT DETECTION RECTANGLES IN THE AIR ------------------------------------------------------
    
    
    func initRectangleDetectionRequest(frame: ARFrame) -> VNDetectRectanglesRequest{
        
        
        let rectangleDetectionRequest = VNDetectRectanglesRequest(completionHandler: {(request: VNRequest, error: Error?) in
            
            //------------------ HANDLE TEXT RECTANGLE REQUEST -----------------------
            print("InitRectangleDetectionRequest HANDLER")
            guard let observations = request.results else {
                print("no result")
                return
            }
            
            let result = observations.map({$0 as? VNRectangleObservation})
            
            for observation in result {
                if let observation = observation {
                    let hitResultTopLeftArray = frame.hitTest(observation.topLeft.invert(), types: [.featurePoint])
                    let hitResultTopRightArray = frame.hitTest(observation.topRight.invert(), types: [.featurePoint])
                    let hitResultBottomLeftArray = frame.hitTest(observation.bottomLeft.invert(), types: [.featurePoint])
                    let hitResultBottomRightArray = frame.hitTest(observation.bottomRight.invert(), types: [.featurePoint])
                    guard let hitResultTopLeft = hitResultTopLeftArray.first else {
                        continue
                    }
                    guard let hitResultTopRight = hitResultTopRightArray.first else {
                        continue
                    }
                    guard let hitResultBottomLeft = hitResultBottomLeftArray.first else {
                        continue
                    }
                    guard let hitResultBottomRight = hitResultBottomRightArray.first else {
                        continue
                    }
                    
                    let topLeftVector = SCNVector3Make(hitResultTopLeft.worldTransform.columns.3.x, hitResultTopLeft.worldTransform.columns.3.y, hitResultTopLeft.worldTransform.columns.3.z)
                    let topRightVector = SCNVector3Make(hitResultTopRight.worldTransform.columns.3.x, hitResultTopRight.worldTransform.columns.3.y, hitResultTopRight.worldTransform.columns.3.z)
                    let bottomLeftVector = SCNVector3Make(hitResultBottomLeft.worldTransform.columns.3.x, hitResultBottomLeft.worldTransform.columns.3.y, hitResultBottomLeft.worldTransform.columns.3.z)
                    let bottomRightVector = SCNVector3Make(hitResultBottomRight.worldTransform.columns.3.x, hitResultBottomRight.worldTransform.columns.3.y, hitResultBottomRight.worldTransform.columns.3.z)
                    
                    let vectorHorizontal = topRightVector-topLeftVector
                    let vectorVertical = bottomLeftVector-topLeftVector
                    let vectorNormal = vectorHorizontal.cross(vector: vectorVertical)
                    let vectorToPlaneCenter = bottomRightVector+(topLeftVector-bottomRightVector)*0.5
                    
                    self.place2DObject(width: self.mWidthOf2DScreen, height: self.mHeightOf2DScreen, vecNormal: vectorNormal, vecToCenter: vectorToPlaneCenter)
                    
                    /*
                    
                    //Place object
                    let plane = SCNPlane(width: CGFloat((bottomRightVector-bottomLeftVector).length()), height: CGFloat((bottomLeftVector-topLeftVector).length()))
                    
                    
                    let vectorToCenterOfRightSide = bottomRightVector+(topRightVector-bottomRightVector)*0.5
                    let rotationAxis = (bottomLeftVector-bottomRightVector).cross(vector: bottomLeftVector-topLeftVector)
                    
                    let rotationAxisCROSSRightSideVector = rotationAxis.cross(vector: topRightVector-bottomRightVector)
                    let rotationAxisCROSSToCenterOfRightSide = rotationAxis.cross(vector: vectorToCenterOfRightSide)
                    
                    let angle = acos((rotationAxisCROSSRightSideVector.dot(vector: rotationAxisCROSSToCenterOfRightSide))/(rotationAxisCROSSToCenterOfRightSide.length()*rotationAxisCROSSRightSideVector.length()))
                    
                    plane.firstMaterial?.diffuse.contents = UIColor.white
                    
                    let planeNode = SCNNode()
                    
                    planeNode.geometry = plane
                    planeNode.position = vectorToPlaneCenter
                    planeNode.rotation = SCNVector4Make(rotationAxis.x, rotationAxis.y, rotationAxis.z, angle) // ROTATION AXIS VECTOR SHOULD BE THE NORMAL VECTOR TO PLANE
                    
                    self.sceneView.scene.rootNode.addChildNode(planeNode)
                    
                    */
                    
                    let lineLeft = SCNNode(geometry: SCNGeometry.lineForm(vector1: topLeftVector, vector2: bottomLeftVector))
                    lineLeft.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    let lineRight = SCNNode(geometry: SCNGeometry.lineForm(vector1: topRightVector, vector2: bottomRightVector))
                    lineRight.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                    let lineTop = SCNNode(geometry: SCNGeometry.lineForm(vector1: topLeftVector, vector2: topRightVector))
                    lineTop.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
                    let lineBottom = SCNNode(geometry: SCNGeometry.lineForm(vector1: bottomLeftVector, vector2: bottomRightVector))
                    self.sceneView.scene.rootNode.addChildNode(lineLeft)
                    self.sceneView.scene.rootNode.addChildNode(lineRight)
                    self.sceneView.scene.rootNode.addChildNode(lineTop)
                    self.sceneView.scene.rootNode.addChildNode(lineBottom)
                }
            }
            
            //------------------ HANDLE TEXT RECTANGLE REQUEST -----------------------
            
        })
        
        
        return rectangleDetectionRequest
    }
    
    
    
    
// ---------------------------------------------- STUFF THAT HAPPENS IF YOU TOUCH THE BUTTON ----------------------------------------------
    @IBAction func onButtonClicked(_ sender: Any) {
        
    }
    
    @IBAction func onRectangleDetectionButtonClicked(_ sender: Any) {
        if let arFrame = sceneView.session.currentFrame {
            let pixelBuffer = arFrame.capturedImage
            
            let requestOptions:[VNImageOption : Any] = [:]
            
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
            
            do {
                try imageRequestHandler.perform([self.initRectangleDetectionRequest(frame: arFrame)])
            } catch {
                print(error)
            }
            
        }
    }
   
    
//---------------------------------------------- STUFF TO PLACE A 2D OBJECT ----------------------------------------------
    
    func place2DObject(width: CGFloat, height: CGFloat, vecNormal: SCNVector3, vecToCenter: SCNVector3) {
        
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = UIColor.white
        // HOW TO PLACE AN VIDEO: https://stackoverflow.com/questions/42469024/how-do-i-create-a-looping-video-material-in-scenekit-on-ios-in-swift-3
         
        let planeNode = SCNNode()
         
        planeNode.geometry = plane
        planeNode.position = vecToCenter //CURRENT NORMAL VECTOR
        
        let vecRotation = vecToCenter.cross(vector: vecNormal).normalize()
        let angle = acos(vecToCenter.normalize().dot(vector: vecNormal.normalize()))
        
        planeNode.rotation = SCNVector4Make(vecRotation.x, vecRotation.y, vecRotation.z, angle)
        
        self.sceneView.scene.rootNode.addChildNode(planeNode)
    }
    
    
    
    
// ---------------------------------------------- STUFF THAT HAPPENS IF YOU TOUCH THE SCREEN ----------------------------------------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("TOUCHES BEGAN")
        let screenSize = self.sceneView.bounds.size
        if let touchPoint = touches.first {
            /*let x = touchPoint.location(in: self.sceneView).y / screenSize.height
            let y = 1.0 - touchPoint.location(in: self.sceneView).x / screenSize.width*/
            
            let x = touchPoint.location(in: self.sceneView).x // screenSize.width
            let y = touchPoint.location(in: self.sceneView).y // screenSize.height
            
           print("Point x \(x) y \(y)")
            
            let focusPoint = CGPoint(x: x, y: y) // THIS IS THE POINT IN 2D COORDINATES ON THE SCREEN e.g. (0,0) -> topleft --- (1,1) -> bottomright
            
            let hitTestResult = self.sceneView.hitTest(focusPoint, types: ARHitTestResult.ResultType.featurePoint)
            
            if let hitTestResult = hitTestResult.first as? ARHitTestResult {
                let vectorToPoint = SCNVector3Make(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
                
                
                
                
                
                let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
                let boxNode = SCNNode(geometry: boxGeometry)
                boxNode.position = vectorToPoint
                
                self.sceneView.scene.rootNode.addChildNode(boxNode)
                
            }
        }
    }
    
    
    
}
