//
//  ViewController.swift
//  PhotoViewer
//
//  Created by Andart on 16.03.17.
//  Copyright © 2017 WorkToFun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func loadView() {
        super.loadView()
        
        self.view.addSubview(self.imageView)
    }

    private lazy var imageView:UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 60, y: 100, width: 200, height: 200))
        imageView.image = UIImage(named: "1452736497_yumor12")
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
        
        return imageView
    }()
    
    func tapAction() {
        let pvc = PhotoViewerController(targetView: self.imageView, image: self.imageView.image!)
        
        pvc.showFromViewController(vc: self)
    }
}

