//
//  PhotoCollectionVC.swift
//  concurrencyImages
//
//  Created by Jesse Tellez on 3/25/16.
//  Copyright © 2016 SunCat Developers. All rights reserved.
//

import UIKit

private let CellImageViewTag = 3
private let BackgroundImageOpacity: CGFloat = 0.1

class PhotoCollectionVC: UICollectionViewController {
    
    var library: ALAssetsLibrary!
    private var popController: UIPopoverController!
    private var contentUpdateObserver: NSObjectProtocol!
    private var addedContentObserver: NSObjectProtocol!
    
    //LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        library = ALAssetsLibrary()
        
        //background image Setup
        let backgroundImageView = UIImageView(image: UIImage(named: "background"))
        backgroundImageView.alpha = BackgroundImageOpacity
        backgroundImageView.contentMode = .Center
        collectionView?.backgroundView = backgroundImageView
        
        contentUpdateObserver = NSNotificationCenter.defaultCenter().addObserverForName(PhotoManagerContentUpdateNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: { (notification) -> Void in
            self.contentChangedNotification(notification)
        })
        
        addedContentObserver = NSNotificationCenter.defaultCenter().addObserverForName(PhotoManagerAddedContentNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue()) { notification in
                self.contentChangedNotification(notification)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showOrHideNavPrompt()
    }
    
    deinit {
        let nc = NSNotificationCenter.defaultCenter()
        if contentUpdateObserver != nil {
            nc.removeObserver(contentUpdateObserver)
        }
        if addedContentObserver != nil {
            nc.removeObserver(addedContentObserver)
        }
    }
}


//UICollectionViewDataSource

private let cellId = "imageCell"

extension PhotoCollectionVC {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PhotoManager.sharedManager.photos.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath)
        
        let imageView = cell.viewWithTag(CellImageViewTag) as! UIImageView
        let photoAsssts = PhotoManager.sharedManager.photos
        let photo = photoAsssts[indexPath.row]
        
        switch photo.status {
        case .Working:
            imageView.image = photo.thumbnail
        case .Downloading:
            imageView.image = UIImage(named: "photoDownloading")
        case .Failed:
            imageView.image = UIImage(named: "photoDownloadError")
        }
        return cell
    }
}

//UICollectionViewDelegate

extension PhotoCollectionVC {
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photos = PhotoManager.sharedManager.photos
        let photo = photos[indexPath.row]
        
        switch photo.status {
        case .Working:
            let detailController = storyboard?.instantiateViewControllerWithIdentifier("PhotoDetailViewController") as? PhotoDetailVC
            if let detailControllerz = detailController {
                detailControllerz.image = photo.image
                navigationController?.pushViewController(detailControllerz, animated: true)
            }
            
        case .Downloading:
            let alert = UIAlertController(title: "Downloading",
                message: "The image is currently downloading",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            
        case .Failed:
            let alert = UIAlertController(title: "Image Failed",
                message: "The image failed to be created",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
}


// ELCImagePickerControllerDelegate


//extension PhotoCollectionVC: ELCImagePickerControllerDelegate {
// 
//    func elcImagePickerController(picker: ELCImagePickerController!, didFinishPickingMediaWithInfo info: [AnyObject]!) {
//        for dictionary in info as! [NSDictionary] {
//            library.assetForURL(dictionary[UIImagePickerControllerReferenceURL] as! NSURL, resultBlock: {
//                asset in
//                let photo = AssetPhoto(asset: asset)
//                PhotoManager.sharedManager.addPhoto(photo)
//                },
//                failureBlock: {
//                    error in
//                    let alert = UIAlertController(title: "Permission Denied",
//                        message: "To access your photos, please change the permissions in Settings",
//                        preferredStyle: .Alert)
//                    alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
//                    self.presentViewController(alert, animated: true, completion: nil)
//            })
//        }
//        
//        if Utils.userInterfaceIdiomIsPad {
//            popController?.dismissPopoverAnimated(true)
//        } else {
//            dismissViewControllerAnimated(true, completion: nil)
//        }
//    }
//    
//    func elcImagePickerControllerDidCancel(picker: ELCImagePickerController!) {
//        if Utils.userInterfaceIdiomIsPad {
//            popController?.dismissPopoverAnimated(true)
//        } else {
//            dismissViewControllerAnimated(true, completion: nil)
//        }
//    }
//}

extension PhotoCollectionVC: ELCImagePickerControllerDelegate {
    func elcImagePickerController(picker: ELCImagePickerController!, didFinishPickingMediaWithInfo info: [AnyObject]!) {
        for dictionary in info as! [NSDictionary] {
            library.assetForURL(dictionary[UIImagePickerControllerReferenceURL] as! NSURL, resultBlock: {
                asset in
                let photo = AssetPhoto(asset: asset)
                PhotoManager.sharedManager.addPhoto(photo)
                },
                failureBlock: {
                    error in
                    let alert = UIAlertController(title: "Permission Denied",
                        message: "To access your photos, please change the permissions in Settings",
                        preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
            })
        }
        
        if Utils.userInterfaceIdiomIsPad {
            popController?.dismissPopoverAnimated(true)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func elcImagePickerControllerDidCancel(picker: ELCImagePickerController!) {
        if Utils.userInterfaceIdiomIsPad {
            popController?.dismissPopoverAnimated(true)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

//IBActionMethods

extension PhotoCollectionVC {
    
    @IBAction func addPhotoButtonPressed(sender: AnyObject) {
        
//        //close popover if visable
//        if popController?.popoverVisible == true {
//            popController.dismissPopoverAnimated(true)
//            popController = nil
//            return
//        }
//        
//        let alert = UIAlertController(title: "Get Photos From", message: nil, preferredStyle: .ActionSheet)
//        
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//        alert.addAction(cancelAction)
//        
//        // Photo library button
//        let libraryAction = UIAlertAction(title: "Photo Library", style: .Default) {
//            action in
//            let imagePickerController = ELCImagePickerController()
//            imagePickerController.imagePickerDelegate = self
//            
//            if Utils.userInterfaceIdiomIsPad {
//                self.popController.dismissPopoverAnimated(true)
//                self.popController = UIPopoverController(contentViewController: imagePickerController)
//                self.popController.presentPopoverFromBarButtonItem(self.navigationItem.rightBarButtonItem!, permittedArrowDirections: .Any, animated: true)
//            } else {
//                self.presentViewController(imagePickerController, animated: true, completion: nil)
//            }
//        }
//        alert.addAction(libraryAction)
//        
//        let internetAction2 = UIAlertAction(title: "From Internet", style: .Default) { (action) -> Void in
//            self.downloadImageAssests()
//        }
//        alert.addAction(internetAction2)
//        
//        // Internet button
//        
//        if Utils.userInterfaceIdiomIsPad {
//            popController = UIPopoverController(contentViewController: alert)
//            popController.presentPopoverFromBarButtonItem(navigationItem.rightBarButtonItem!, permittedArrowDirections: .Any, animated: true)
//        } else {
//            presentViewController(alert, animated: true, completion: nil)
//        }
        
        if popController?.popoverVisible == true {
            popController.dismissPopoverAnimated(true)
            popController = nil
            return
        }
        
        let alert = UIAlertController(title: "Get Photos From:", message: nil, preferredStyle: .ActionSheet)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // Photo library button
        let libraryAction = UIAlertAction(title: "Photo Library", style: .Default) {
            action in
            let imagePickerController = ELCImagePickerController()
            imagePickerController.imagePickerDelegate = self
            
            if Utils.userInterfaceIdiomIsPad {
                self.popController.dismissPopoverAnimated(true)
                self.popController = UIPopoverController(contentViewController: imagePickerController)
                self.popController.presentPopoverFromBarButtonItem(self.navigationItem.rightBarButtonItem!, permittedArrowDirections: .Any, animated: true)
            } else {
                self.presentViewController(imagePickerController, animated: true, completion: nil)
            }
        }
        alert.addAction(libraryAction)
        
        // Internet button
        
        let InternetAction = UIAlertAction(title: "Internet", style: .Default) { (action) -> Void in
            self.downloadImageAssests()
        }
        alert.addAction(InternetAction)
        
        if Utils.userInterfaceIdiomIsPad {
            popController = UIPopoverController(contentViewController: alert)
            popController.presentPopoverFromBarButtonItem(navigationItem.rightBarButtonItem!, permittedArrowDirections: .Any, animated: true)
        } else {
            presentViewController(alert, animated: true, completion: nil)
        }

    }
}

//private methods

private extension PhotoCollectionVC {
    
    func contentChangedNotification(notification: NSNotification!) {
        collectionView?.reloadData()
        showOrHideNavPrompt();
    }
    
    func showOrHideNavPrompt() {
        let delayInSeconds = 1.0
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, GlobalMainQueue) {
            let count = PhotoManager.sharedManager.photos.count
            if count > 0 {
                self.navigationItem.prompt = nil
            }else {
                self.navigationItem.prompt = "Add photos with faces to mustaschify them!"
            }
        }
    }
    
    func downloadImageAssests() {
        PhotoManager.sharedManager.downloadPhotosWithCompletion { (error) -> Void in
            //completion block executes at the wrong time
            let message = error?.localizedDescription ?? "The images finished downloading"
            let alert = UIAlertController(title: "Download Complete", message: message, preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}
