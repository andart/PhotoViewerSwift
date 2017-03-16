//
//  PhotoViewerController.swift
//  PhotoViewer
//
//  Created by Andart on 16.03.17.
//  Copyright © 2017 WorkToFun. All rights reserved.
//

import UIKit

class PhotoViewerController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    let targetZoomForDoubleTap: CGFloat = 3.0
    
    var referenceView: UIView
    var startRect: CGRect?
    var snapshotView: UIView?
    var scrollViewIsAnimatingAZoom: Bool
    var panRecognizer: UIPanGestureRecognizer?
    var imageDragStartingPoint: CGPoint?
    
    init(targetView: UIView, image: UIImage) {
        self.referenceView = targetView
        self.scrollViewIsAnimatingAZoom = false
        
        super.init(nibName: nil, bundle: nil)
        
        self.imageView.image = image
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func showFromViewController(vc: UIViewController) {
        self.view.isUserInteractionEnabled = true
        
        let referenceFrameInWindow = self.referenceView.superview?.convert(self.referenceView.frame, to: nil)
        self.startRect = self.view.convert(referenceFrameInWindow!, to: nil)
        
        self.snapshotView = self.snapshotFromParentmostViewController(viewController: vc)
        self.view.insertSubview(self.snapshotView!, at: 0)
        
        self.view.addSubview(self.imageView)
        
        vc.present(self, animated: false) { 
            self.imageView.frame = self.startRect!
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                self.overlayView.alpha = 1.0
                
                let endFrameForImageView = self.resizedFrameForAutorotatingImageView(imageSize: (self.imageView.image?.size)!)
                self.imageView.frame = endFrameForImageView
                
                let endCenterForImageView = CGPoint(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0)
                self.imageView.center = endCenterForImageView;
            }, completion: { (finished) in
                self.scrollView.addSubview(self.imageView)
            })
        }
        
    }

    override func loadView() {
        super.loadView()
        
        self.view.addSubview(self.overlayView)
        self.view.addSubview(self.scrollView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doubleTapperPhoto = UITapGestureRecognizer(target: self, action: #selector(self.imageDoubleTapped))
        doubleTapperPhoto.numberOfTapsRequired = 2;
        doubleTapperPhoto.delegate = self;
        self.scrollView.addGestureRecognizer(doubleTapperPhoto)
        
        let singleTapPhoto = UITapGestureRecognizer(target: self, action: #selector(self.imageSingleTapped))
        singleTapPhoto.require(toFail: doubleTapperPhoto)
        singleTapPhoto.delegate = self
        self.scrollView.addGestureRecognizer(singleTapPhoto)
        
        self.panRecognizer =  UIPanGestureRecognizer(target: self, action: #selector(self.dismissingPanGestureRecognizerPanned(_:)))
        self.panRecognizer?.maximumNumberOfTouches = 1
        self.panRecognizer?.delegate = self
        self.scrollView.addGestureRecognizer(self.panRecognizer!)
    }
    
    private lazy var overlayView:UIView = {
        let overlayView = UIView(frame: self.view.bounds)
        overlayView.backgroundColor = UIColor.black
        overlayView.alpha = 0.0
        
        return overlayView
    }()
    
    private lazy var imageView:UIImageView = {
        
        let referenceFrameInWindow = self.referenceView.superview?.convert(self.referenceView.frame, to: nil)
        let referenceFrameInMyView = self.view.convert(referenceFrameInWindow!, from: nil)
        
        let imageView = UIImageView(frame: referenceFrameInMyView)
        imageView.backgroundColor = UIColor.clear
        imageView.contentMode = UIViewContentMode.scaleAspectFill;
        imageView.clipsToBounds = true;
        imageView.isUserInteractionEnabled = true;
        imageView.isAccessibilityElement = false;
        imageView.layer.allowsEdgeAntialiasing = true;
        
        return imageView;
    }()
    
    private lazy var scrollView:UIScrollView = {
        let scrollView = UIScrollView(frame: self.view.bounds)
        scrollView.delegate = self
        scrollView.zoomScale = 1.0
        scrollView.maximumZoomScale = 8.0
        scrollView.isScrollEnabled = false
        scrollView.isAccessibilityElement = true
        scrollView.accessibilityLabel = self.accessibilityLabel
        
        return scrollView
    }()
    
    func dismissVC() {
        let imageFrame = self.view.convert(self.imageView.frame, from:self.scrollView)
        self.imageView.transform = CGAffineTransform.identity
        self.imageView.layer.transform = CATransform3DIdentity
        self.imageView.removeFromSuperview()
        self.imageView.frame = imageFrame
        self.view.addSubview(self.imageView)
        self.scrollView.removeFromSuperview()
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.imageView.frame = self.startRect!;
            self.overlayView.alpha = 0;
        }, completion: { (finished) in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    func imageDoubleTapped(recognizer: UITapGestureRecognizer) {
        if (self.scrollViewIsAnimatingAZoom) {
            return
        }
        
        let rawLocation = recognizer.location(in: recognizer.view)
        let point = self.scrollView.convert(rawLocation, from:recognizer.view)
        var targetZoomRect: CGRect
        if (self.scrollView.zoomScale == 1.0) {
            let zoomWidth = self.view.bounds.size.width / self.targetZoomForDoubleTap
            let zoomHeight = self.view.bounds.size.height / self.targetZoomForDoubleTap
            targetZoomRect = CGRect(x: point.x - (zoomWidth * 0.5), y: point.y - (zoomHeight * 0.5), width: zoomWidth, height: zoomHeight)
        } else {
            let zoomWidth = self.view.bounds.size.width * self.scrollView.zoomScale
            let zoomHeight = self.view.bounds.size.height * self.scrollView.zoomScale
            targetZoomRect = CGRect(x: point.x - (zoomWidth/2.0), y: point.y - (zoomHeight/2.0), width: zoomWidth, height: zoomHeight)
        }
        self.view.isUserInteractionEnabled = false;
        self.scrollViewIsAnimatingAZoom = true;
        
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            self.centerZoomView()
            self.view.isUserInteractionEnabled = true
            self.scrollViewIsAnimatingAZoom = false
            })
        self.scrollView.zoom(to: targetZoomRect, animated: true)
        CATransaction.commit()
    }
    
    func imageSingleTapped() {
        if (self.scrollViewIsAnimatingAZoom) {
            return;
        }
        self.dismissVC()
    }
    
    func dismissingPanGestureRecognizerPanned(_ panner: UIPanGestureRecognizer) {
        let translation = panner.translation(in: panner.view)
        
        if (panner.state == UIGestureRecognizerState.began) {
            self.imageDragStartingPoint = self.imageView.center
        } else if (panner.state == UIGestureRecognizerState.changed) {
            var newAnchor = self.imageDragStartingPoint
            newAnchor?.y += translation.y
            self.imageView.center = newAnchor!
            
            let a = 1 - Swift.abs((self.imageDragStartingPoint?.y)! - (newAnchor?.y)!) * 0.01
            self.overlayView.alpha = Swift.max(0.5, a)
        } else {
            if (Swift.abs(self.imageView.center.y - self.overlayView.center.y) > 50.0) {
                self.dismissVC()
            } else {
                UIView.animate(withDuration: 0.3, animations: { 
                    self.imageView.center = self.imageDragStartingPoint!
                    self.overlayView.alpha = 1;
                })
            }
        }
    }
    
    func snapshotFromParentmostViewController(viewController: UIViewController) -> UIView {
        var presentingViewController = viewController.view.window?.rootViewController
        while ((presentingViewController?.presentedViewController) != nil) {
            presentingViewController = presentingViewController?.presentedViewController
        }
        
        let snapshot = presentingViewController?.view.snapshotView(afterScreenUpdates: true);
        snapshot?.clipsToBounds = false;
        
        return snapshot!
    }
    
    func resizedFrameForAutorotatingImageView(imageSize: CGSize) -> CGRect {
        var frame = self.view.bounds
        let screenWidth = frame.size.width * self.scrollView.zoomScale
        let screenHeight = frame.size.height * self.scrollView.zoomScale
        var targetWidth = screenWidth
        var targetHeight = screenHeight
        var nativeHeight = screenHeight
        var nativeWidth = screenWidth
        if (imageSize.width > 0 && imageSize.height > 0) {
            nativeHeight = (imageSize.height > 0) ? imageSize.height : screenHeight
            nativeWidth = (imageSize.width > 0) ? imageSize.width : screenWidth
        }
        if (nativeHeight > nativeWidth) {
            if (screenHeight/screenWidth < nativeHeight/nativeWidth) {
                targetWidth = screenHeight / (nativeHeight / nativeWidth)
            } else {
                targetHeight = screenWidth / (nativeWidth / nativeHeight)
            }
        } else {
            if (screenWidth/screenHeight < nativeWidth/nativeHeight) {
                targetHeight = screenWidth / (nativeWidth / nativeHeight)
            } else {
                targetWidth = screenHeight / (nativeHeight / nativeWidth)
            }
        }
        frame.size = CGSize(width: targetWidth, height: targetHeight)
        frame.origin = CGPoint(x: 0, y: 0)
        return frame
    }
    
    func centerZoomView() {
        var frame = self.imageView.frame;
        
        if (frame.height < self.scrollView.bounds.height) {
            frame.origin.y = (self.scrollView.bounds.height - frame.height) * 0.5;
        } else {
            frame.origin.y = 0;
        }
        
        if (frame.width < self.scrollView.bounds.width) {
            frame.origin.x = (self.scrollView.bounds.width - frame.width) * 0.5;
        } else {
            frame.origin.x = 0;
        }
        
        self.imageView.frame = frame;
    }
    
    // MARK: UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.scrollView.isScrollEnabled == false) {
            self.scrollView.isScrollEnabled = true;
        }
        
        self.centerZoomView()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.scrollView.isScrollEnabled = (scale > 1);
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var shouldReceiveTouch = true
        
        if (shouldReceiveTouch && gestureRecognizer == self.panRecognizer) {
            shouldReceiveTouch = (self.scrollView.zoomScale == 1 && self.scrollViewIsAnimatingAZoom == false)
        }
        
        return shouldReceiveTouch
    }
}
