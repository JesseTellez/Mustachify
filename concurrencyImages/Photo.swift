//
//  Photo.swift
//  concurrencyImages
//
//  Created by Jesse Tellez on 2/19/16.
//  Copyright © 2016 SunCat Developers. All rights reserved.
//

import Foundation
import Photos
import AssetsLibrary

typealias PhotoDownloadCompletionBlock = (image: UIImage?, error: NSError?) -> Void
typealias PhotoDownloadProgressBlock = (completed: Int, total: Int) -> Void

enum PhotoStatus {
    case Downloading
    case Working
    case Failed
}

protocol Photo
{
    var status: PhotoStatus{get}
    var image: UIImage? {get}
    var thumbnail: UIImage? {get}
}

class AssetPhoto: Photo{
    var status: PhotoStatus{
        return .Working
    }
    
    let asset: ALAsset
    
    
    var image: UIImage?{
        let representation = asset.defaultRepresentation()
        return UIImage(CGImage: representation.fullScreenImage().takeRetainedValue())
        
    }
    
    var thumbnail: UIImage? {
        return UIImage(CGImage: asset.thumbnail().takeUnretainedValue())
    }
    
    init(asset: ALAsset){
        self.asset = asset
    }
}

private let downloadSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())

class DownloadPhoto: Photo {
    var status: PhotoStatus = .Downloading
    var image: UIImage?
    var thumbnail: UIImage?
    
    let url: NSURL
    
    init(url: NSURL, completion: PhotoDownloadCompletionBlock!){
        self.url = url
        downloadImage(completion)
    }
    
    convenience init(url: NSURL) {
        self.init(url: url, completion: nil)
    }
    
    func downloadImage(completion: PhotoDownloadCompletionBlock?) {
        let task = downloadSession.dataTaskWithURL(url) { (data, resp, err) -> Void in
            self.image = UIImage(data: data!)
            if err == nil && self.image != nil {
                self.status = .Working
            }else{
                self.status = .Failed
            }
            
            self.thumbnail = self.image?.thumbnailImage(64,
                transparentBorder: 0,
                cornerRadius: 0,
                interpolationQuality: CGInterpolationQuality.Default)
            
            if let completion = completion {
                completion(image: self.image, error: err)
            }
            
            dispatch_async(dispatch_get_main_queue()){
                NSNotificationCenter.defaultCenter().postNotificationName(PhotoManagerContentUpdateNotification, object: nil)
            }
            
        }
        task.resume()
    }
}
