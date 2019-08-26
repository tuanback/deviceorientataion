//
//  DeviceOrientationProvider.swift
//  DeviceOrientationProvider
//
//  Created by Tuan on 26/08/2019.
//  Copyright © 2019 Next Aeon. All rights reserved.
//

import Foundation
import CoreMotion
import UIKit
import GLKit

class DeviceOrientationProvider {
  
  private lazy var motionManager = CMMotionManager()
  private var isStarted:      Bool  = false
  private var mYaw:           Float = Float.pi
  private var mPitch:         Float = Float.pi
  private var mRoll:          Float = 3 * Float.pi
  private var mIsUpSideDown:  Bool  = false
  
  static var shared = DeviceOrientationProvider()
  
  private init() { }
  
  func start() {
    guard !isStarted else { return }
    guard motionManager.isDeviceMotionAvailable else { return }
    let queue = OperationQueue()
    motionManager.deviceMotionUpdateInterval = 1 / 60
    motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (motion, error) in
      guard let strongSelf = self else { return }
      guard error == nil else { return }
      
      strongSelf.updateDeviceOrientation()

      let roll  = strongSelf.mRoll  * 180 / Float.pi
      let pitch = strongSelf.mPitch * 180 / Float.pi
      let yaw   = strongSelf.mYaw   * 180 / Float.pi
      
      print("Roll:  \(roll)")
      print("Pitch: \(pitch)")
      print("Yaw:   \(yaw)")
      print("IsUpsideDown: \(strongSelf.mIsUpSideDown)")
    }
    isStarted = true
  }
  
  func stop() {
    guard isStarted else {
      return
    }
    
    if motionManager.isDeviceMotionAvailable {
      motionManager.stopDeviceMotionUpdates()
    }
    
    isStarted = false
  }
  
  private func updateDeviceOrientation() {
    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self else { return }
      
      let attitudeMatrix  = strongSelf.getDeviceOrientationMatrix()
      let lookVector      = GLKVector3(v: (-attitudeMatrix.m02,
                                           -attitudeMatrix.m12,
                                           -attitudeMatrix.m22))
      strongSelf.mYaw  = atan2f(lookVector.x, -lookVector.z)
      strongSelf.mPitch = asinf(lookVector.y)
    }
  }
  
  private func getDeviceOrientationMatrix() -> GLKMatrix4 {
    guard motionManager.isDeviceMotionActive else { return GLKMatrix4Identity }
    
    if let gravity = motionManager.deviceMotion?.gravity {
      mIsUpSideDown = (gravity.y >= 0)
    }
    
    if let quaternion = motionManager.deviceMotion?.attitude.quaternion {
      let roll = asinf(Float(2 * (quaternion.x * quaternion.z - quaternion.w * quaternion.y)))
      if mRoll == 3 * Float.pi {
        mRoll = roll
      }
      
      mRoll = kalmanFilter(lastValue: mRoll, currentValue: roll)
      
      if let a = motionManager.deviceMotion?.attitude.rotationMatrix {
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        switch statusBarOrientation {
        case .landscapeRight:
          return GLKMatrix4(m: (Float(a.m21), Float(-a.m11), Float(a.m31), 0.0,
                                Float(a.m23), Float(-a.m13), Float(a.m33), 0.0,
                                      Float(-a.m22), Float(a.m12), Float(-a.m32), 0.0,
                                            0.0 ,0.0 , 0.0 , 1.0))
        case .landscapeLeft:
          return GLKMatrix4(m: (Float(-a.m21), Float(a.m11), Float(a.m31), 0.0,
                                Float(-a.m23), Float(a.m13), Float(a.m33), 0.0,
                                Float(a.m22), Float(-a.m12), Float(-a.m32), 0.0,
                                0.0 ,0.0 ,0.0 , 1.0))
        case .portraitUpsideDown:
          return GLKMatrix4(m: (Float(-a.m21), Float(a.m11), Float(a.m31), 0.0,
                                Float(-a.m23), Float(a.m13), Float(a.m33), 0.0,
                                      Float(a.m22), Float(-a.m12), Float(-a.m32), 0.0,
                                            0.0 ,0.0 ,0.0 , 1.0))
        default:
          return GLKMatrix4(m: (Float(a.m11), Float(a.m21), Float(a.m31), 0.0,
                                Float(a.m13), Float(a.m23), Float(a.m33), 0.0,
                                Float(-a.m12), Float(-a.m22), Float(-a.m32), 0.0,
                                0.0 ,0.0 ,0.0 ,1.0))
        }
      }
    }
    
    return GLKMatrix4Identity
  }
  
  private func kalmanFilter(lastValue: Float, currentValue: Float) -> Float {
    let q: Float = 0.1
    let r: Float = 0.1
    var p: Float = 0.1
    var k: Float = 0.5
    var x: Float = lastValue
    
    p = p + q
    k = p / (p + r)
    x = x + k * (currentValue - x)
    p = (1 - k) * p
    
    return x
  }
  
}
