//
//  Filter.swift
//  LyreBird
//
//  Created by Melike Büşra Ayhan on 5.09.2020.
//  Copyright © 2020 com.lyrebird. All rights reserved.
//

import Foundation
import RealmSwift
struct  FilterProtocol:Decodable  {
    
  let overlayId: Int?
  let overlayName: String?
  let overlayPreviewIconUrl: String?
  let overlayUrl: String?
    init(result:[String:Any]){
      overlayId = result["overlayId"] as? Int
      overlayName = result["overlayName"] as? String
      overlayPreviewIconUrl = result["overlayPreviewIconUrl"] as? String
      overlayUrl = result["overlayUrl"] as? String
    }
}
class KeyFilter : Object {
       @objc dynamic var name:String? = ""
       @objc dynamic var id:String? = nil
       @objc dynamic var previewIcon:String? = ""
       @objc dynamic var icon:String? = ""
}
extension UIImage {

    func withInset(_ insets: UIEdgeInsets) -> UIImage? {
        
        let cgSize = CGSize(width: self.size.width + insets.left * self.scale + insets.right * self.scale,
                            height: self.size.height + insets.top * self.scale + insets.bottom * self.scale)

        UIGraphicsBeginImageContextWithOptions(cgSize, false, self.scale)
        defer { UIGraphicsEndImageContext() }

        let origin = CGPoint(x: insets.left * self.scale, y: insets.top * self.scale)
        self.draw(at: origin)

        return UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(self.renderingMode)
    }
}
