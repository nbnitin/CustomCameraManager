//
//  ImageViewVC.swift
//  CustomCameraManager
//
//  Created by Nitin Bhatia on 1/11/21.
//

import UIKit

class ImageViewVC: UIViewController {
    
    //outlets
    @IBOutlet var imgView: UIImageView!
    
    //variables
    var data : CameraGalleryItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imgView.image = data.image
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
