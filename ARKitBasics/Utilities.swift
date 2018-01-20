//
//  Utilities.swift
//  ARKitBasics
//
//  Created by Maximilian Klinke on 29.10.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import ARKit

extension SCNGeometry {
    
    class func rectangleForm(topLeft: SCNVector3, topRight: SCNVector3, bottomLeft: SCNVector3, bottomRight: SCNVector3) -> SCNGeometry {
        
        let indices: [Int32] = [0, 1, 2]
        let indices2: [Int32] = [0, 1, 2]
        
        let source = SCNGeometrySource(vertices: [topLeft, topRight, bottomRight])
        let source2 = SCNGeometrySource(vertices: [topLeft, bottomLeft, bottomRight])
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let element2 = SCNGeometryElement(indices: indices2, primitiveType: .triangles)
        
        return SCNGeometry(sources: [source, source2], elements: [element, element2])
    }
    
    class func lineForm(vector1: SCNVector3, vector2: SCNVector3) -> SCNGeometry{
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}

extension SCNVector3 {

    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
    
    func distance(vector: SCNVector3) -> Float {
        return (self - vector).length()
    }
    
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    static func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
    
    static func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
    }
    
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    /**
     * Calculates the dot product between two SCNVector3.
     */
    func dot(vector: SCNVector3) -> Float {
        return x * vector.x + y * vector.y + z * vector.z
    }
    
    /**
     * Calculates the cross product between two SCNVector3.
     */
    func cross(vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }
    
    func normalize() -> SCNVector3 {
        return self/self.length()
    }

}

extension CGPoint {
    func invert() ->CGPoint {
        return CGPoint(x: (1.0-self.y), y: (1.0-self.x))
    }
}
