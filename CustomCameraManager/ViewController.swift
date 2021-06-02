//
//  ViewController.swift
//  CustomCameraManager
//
//  Created by Nitin Bhatia on 12/31/20.
//

import UIKit
let CAMERA_ALBUM_NAME = "Custom Camera"

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func goToCamera(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(identifier: "cameraIntegrateVC") as? CameraIntergrateVC
        vc?.modalPresentationStyle = .fullScreen
        self.present(vc!, animated: true, completion: nil)
    }
}

