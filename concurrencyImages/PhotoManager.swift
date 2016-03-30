//
//  PhotoManager.swift
//  concurrencyImages
//
//  Created by Jesse Tellez on 3/25/16.
//  Copyright © 2016 SunCat Developers. All rights reserved.
//

import Foundation

/// Notification when new photo instances are added
let PhotoManagerAddedContentNotification = "Content Added"
/// Notification when content updates (i.e. Download finishes)
let PhotoManagerContentUpdateNotification = "Content Updated"


typealias PhotoProcessingProgressClosure = (completionPercentage: CGFloat) -> Void
typealias BatchPhotoDownloadingCompletionClosure = (error: NSError?) -> Void

private let _sharedManager = PhotoManager()

class PhotoManager {
    class var sharedManager: PhotoManager {
        return _sharedManager
    }
    
    private var _photos: [Photo] = []
    var photos: [Photo] {
        var photosCopy: [Photo]!
        dispatch_sync(concurrentPhotoQueue) { () -> Void in
            photosCopy = self._photos
        }
        return photosCopy
    }
    
    private let concurrentPhotoQueue = dispatch_queue_create("photoQueue", DISPATCH_QUEUE_CONCURRENT)
    
    func addPhoto(photo: Photo) {
        dispatch_barrier_async(concurrentPhotoQueue) { () -> Void in
            self._photos.append(photo)
            dispatch_async(GlobalMainQueue, { () -> Void in
                self.postContentAddedNotification()
            })
        }
    }
    
    func downloadPhotosWithCompletion(completion: BatchPhotoDownloadingCompletionClosure?) {
        var storedError: NSError?
        for address in [OverlyAttachedGirlfriendURLString, SuccessKidURLString, LotsOfFacesURLString] {
            let url = NSURL(string: address)!
            let photo = DownloadPhoto(url: url, completion: { (image, error) -> Void in
                if error != nil {
                    storedError = error
                }
            })
            PhotoManager.sharedManager.addPhoto(photo)
        }
        
        if let completion = completion {
            completion(error: storedError)
        }
    }
    
    private func postContentAddedNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(PhotoManagerAddedContentNotification, object: nil)
    }
}
