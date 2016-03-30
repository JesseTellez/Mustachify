//
//  PhotoDetailVC.swift
//  concurrencyImages
//
//  Created by Jesse Tellez on 2/19/16.
//  Copyright © 2016 SunCat Developers. All rights reserved.
//

import UIKit

private let RetinaToEyeScaleFactor: CGFloat = 0.5
private let FaceBoundsToEyeScaleFactor: CGFloat = 4.0
private let FaceBoundsToMouthScaleFactor: CGFloat = 3.0
private let FaceToMouthScaleFactor: CGFloat = 5.7

class PhotoDetailVC: UIViewController
{
    
    @IBOutlet var photoScrollView: UIScrollView!
    @IBOutlet var photoImageView: UIImageView!
    
    var image: UIImage!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        assert(image != nil, "Image not set; required to use view controller")
        photoImageView.image = image
        
        //resize to ensure not pixelated
        if image.size.height <= photoImageView.bounds.size.height && image.size.width <= photoImageView.bounds.size.width
        {
            photoImageView.contentMode = .Center
        }
        
        dispatch_async(GlobalUserInitiatedQueue)
        {
            let startTime = NSDate()
            let overlayImage = self.faceOverlayImageFromImage(self.image)
            let endTime = NSDate()
            let totalTimeToExecute = endTime.timeIntervalSinceDate(startTime)
            print("Photo manipulation took \(totalTimeToExecute) seconds to complete")
            dispatch_async(GlobalMainQueue)
            {
                self.fadeInNewImage(overlayImage)
            }
        }
    }
}

//Private Methods

private extension PhotoDetailVC
{
    func faceOverlayImageFromImage(image: UIImage) -> UIImage
    {
        let detector = CIDetector(ofType: CIDetectorTypeFace,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let newImage = CIImage(CGImage: image.CGImage!)
        let features = detector.featuresInImage(newImage) as? [CIFaceFeature]
        UIGraphicsBeginImageContext(image.size)
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        image.drawInRect(imageRect, blendMode: CGBlendMode.Normal, alpha: 1.0)
        
        let context = UIGraphicsGetCurrentContext()
        for faceFeature in features!
        {
            let faceRect = faceFeature.bounds
            CGContextSaveGState(context)
            
            CGContextTranslateCTM(context, 0.0, imageRect.size.height)
            CGContextScaleCTM(context, 1.0, -1.0)
            
            if faceFeature.hasMouthPosition
            {
                let mouthPos = faceFeature.mouthPosition
                
                let mouthwidth = faceRect.size.width
                let mouthHeight = faceRect.size.height / FaceBoundsToMouthScaleFactor
                let mouthwidth2 = faceRect.size.width / FaceToMouthScaleFactor
                
                let mouthRect = CGRect(x: (mouthPos.x - mouthHeight) - 40, y: mouthPos.y - mouthwidth2, width: mouthwidth, height: mouthHeight)
                addImageToFrame(mouthRect)
            }
            
            CGContextRestoreGState(context);
        }
        
        let overlayImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return overlayImage

    }
    
    func alertUser(time: String){
        let timeAlert = UIAlertController(title: "Execution Time", message: time, preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil)
        timeAlert.addAction(dismissAction)
        self.presentViewController(timeAlert, animated: true, completion: nil)
    }
    
    func addImageToFrame(rect: CGRect)
    {
        let newImage = UIImage(named: "handlebar-mustache copy")
        newImage?.drawInRectAspectFill(rect)
    }
    
    func fadeInNewImage(newImage: UIImage)
    {
        let tmpImageView = UIImageView(image: newImage)
        tmpImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        tmpImageView.contentMode = photoImageView.contentMode
        tmpImageView.frame = photoImageView.bounds
        tmpImageView.alpha = 0.0
        photoImageView.addSubview(tmpImageView)
        
        UIView.animateWithDuration(0.75, animations: {
            tmpImageView.alpha = 1.0
            }, completion: {
                finished in
                self.photoImageView.image = newImage
                tmpImageView.removeFromSuperview()
        })
    }
}

extension PhotoDetailVC: UIScrollViewDelegate
{
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
    {
        return photoImageView
    }
}

extension UIImage
{
    
    func drawInRectAspectFill(rect: CGRect)
    {
        let targetSize = rect.size
        let scaledImage: UIImage
        if targetSize == CGSizeZero
        {
            scaledImage = self
        }else
        {
            let scalingFactor = targetSize.width / self.size.width > targetSize.height / self.size.height ? targetSize.width / self.size.width: targetSize.height / self.size.height
            
            let newSize = CGSize(width: self.size.width * scalingFactor, height: self.size.height * scalingFactor)
            UIGraphicsBeginImageContext(targetSize)
            
            self.drawInRect(CGRect(origin: CGPoint(x: (targetSize.width - newSize.width) / 2, y: (targetSize.height - newSize.height) / 2), size: newSize))
            scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
        }
        scaledImage.drawInRect(rect)
    }
}
