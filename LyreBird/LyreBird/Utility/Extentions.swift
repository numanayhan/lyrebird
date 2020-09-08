//
//  Extentions.swift
//  LyreBird
//
//  Created by Melike Büşra Ayhan on 5.09.2020.
//  Copyright © 2020 com.lyrebird. All rights reserved.
//

import Foundation
import UIKit
import ImageIO
import CoreGraphics
extension UIView{
    func anchor(top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?, paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            self.bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let right = right {
            self.rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
     func asImage() -> UIImage? {
         if #available(iOS 10.0, *) {
             let renderer = UIGraphicsImageRenderer(bounds: bounds)
             return renderer.image { rendererContext in
                 layer.render(in: rendererContext.cgContext)
             }
         } else {
             UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
             defer { UIGraphicsEndImageContext() }
             guard let currentContext = UIGraphicsGetCurrentContext() else {
                 return nil
             }
             self.layer.render(in: currentContext)
             return UIGraphicsGetImageFromCurrentImageContext()
         }
    }
    
   
}
//  Bitmap structure

public struct PixelData {
    var a, r, g, b: UInt8

    init(r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0) {
        self.a = 255
        self.r = r
        self.g = g
        self.b = b
    }
    
    init(_ white: UInt8) {
        self.init(r: white, g: white, b: white)
    }
    
    init(_ v: IntData, div: Int) {
        self.a = 255
        self.r = UInt8(v.r * 255 / div)
        self.g = UInt8(v.g * 255 / div)
        self.b = UInt8(v.b * 255 / div)
    }
}
//  Histogram structure

public struct IntData {
    var r, g, b: Int
    
    init() {
        self.r = 0
        self.g = 0
        self.b = 0
    }
    
    var maxRGB : Int {
        return max( max(r, g), b)
    }
}
