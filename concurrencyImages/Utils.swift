//
//  PhotoManager.swift
//  concurrencyImages
//
//  Created by Jesse Tellez on 3/25/16.
//  Copyright © 2016 SunCat Developers. All rights reserved.
//

import Foundation
import UIKit

let OverlyAttachedGirlfriendURLString = "http://i.imgur.com/UvqEgCv.png"
let SuccessKidURLString = "http://i.imgur.com/dZ5wRtb.png"
let LotsOfFacesURLString = "http://i.imgur.com/tPzTg7A.jpg"
let WomanFaceURLString = "http://dreamatico.com/data_images/face/face-6.jpg"
let SquareFaceString = "https://thecreatorsproject-images.vice.com/content-images/contentimage/no-slug/d4d24f28d34addbcb66fb9e86c8276b2.jpg"



var GlobalMainQueue: dispatch_queue_t {
    return dispatch_get_main_queue()
}

var GlobalUserInteractiveQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
}

var GlobalUserInitiatedQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
}

var GlobalUtilityQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.rawValue), 0)
}

var GlobalBackgroundQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)
}

class Utils: NSObject {
  class var defaultBackgroundColor: UIColor {
    return UIColor(red: 236.0/255.0, green: 254.0/255.0, blue: 255.0/255.0, alpha: 1.0)
  }

  class var userInterfaceIdiomIsPad: Bool {
    return UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
  }
    
}
