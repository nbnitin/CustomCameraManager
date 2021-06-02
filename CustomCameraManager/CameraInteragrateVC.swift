//
//  CameraInteragrateVC.swift
//  CustomCameraManager
//
//  Created by Nitin Bhatia on 12/31/20.
//



import UIKit

class CameraIntergrateVC : UIViewController {
    
    deinit {
        CameraManagerHelper.shared.toggleTorch()
    }
    
    @IBOutlet var btnFlash: UIButton!
    @IBOutlet var cameraView: UIView!
    @IBOutlet var lblTime: UILabel!
    @IBOutlet var btnStartRecording: UIButton!
    @IBOutlet var btnCaptureImage: UIButton!
    @IBOutlet var btnSwitchCamera: UIButton!
    @IBOutlet var imgCapturedView: UIImageView!
    
    var recordedVideoSeconds = 0
    var timer: Timer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnCaptureImage.layer.cornerRadius = btnCaptureImage.frame.width / 2
        btnStartRecording.layer.cornerRadius = btnStartRecording.frame.width / 2
        
        btnStartRecording.setImage(UIImage(named: "Camera_Video_Stop-1"), for: .selected)
        
        setupCamera()
        updateOrientation()
        NotificationCenter.default.addObserver(self,selector:  #selector(updateOrientation),name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        imgCapturedView.addGestureRecognizer(tap)
        imgCapturedView.isUserInteractionEnabled = true
        
        if #available(iOS 13.0, *) {
            btnFlash.setImage(UIImage(systemName: "moon"), for: .normal)
            btnFlash.setImage(UIImage(systemName: "moon.fill"), for: .selected)
        } else {
            //
        }
        btnFlash.isSelected = UserDefaults.standard.isCameraFlashOn!
        toggleFlash()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        imgCapturedView.image = CameraManagerHelper.shared.getLastCameraItemAsImage()
    }
    
    @objc func handleTap(){
        CameraManagerHelper.shared.toggleTorch()
        let vc = storyboard?.instantiateViewController(identifier: "albumVC") as! Album
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    func setupCamera() {
        CameraManagerHelper.shared.setupCamera(view: cameraView, albumName: CAMERA_ALBUM_NAME, completion: {_ in})
        lblTime.text = ""
    }
    
    //MARK: flash functionality action
    @IBAction func flashButtonAction(_ sender: Any) {
        btnFlash.isSelected = !btnFlash.isSelected
        toggleFlash()
    }
    
    //MARK: toggle flash function
    private func toggleFlash(){
        CameraManagerHelper.shared.toggleFlash(status: btnFlash.isSelected)
        UserDefaults.standard.isCameraFlashOn = btnFlash.isSelected
    }
    
    @IBAction func cameraSwitch(_ sender: Any) {
        CameraManagerHelper.shared.switchCameraView()
    }
    
    @IBAction func startRecording(_ sender: Any) {
        if btnStartRecording.isSelected {
            CameraManagerHelper.shared.stopVideoRecording(completion: { img in
                DispatchQueue.main.async {
                    self.imgCapturedView.image = img
                }
            })
            btnStartRecording.backgroundColor = UIColor(red: 235/255, green: 100/255, blue: 8/255, alpha: 1)
            btnCaptureImage.isHidden = false
            btnSwitchCamera.isHidden = false
            imgCapturedView.isHidden = false
            lblTime.text = ""
            timer?.invalidate()
        } else {
            CameraManagerHelper.shared.startVideoRecording()
            recordedVideoSeconds = -1
            self.fireTimer()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
            }
            btnStartRecording.backgroundColor = .red
            btnCaptureImage.isHidden = true
            btnSwitchCamera.isHidden = true
            imgCapturedView.isHidden = true
        }
        btnStartRecording.isSelected = !btnStartRecording.isSelected
    }
    
    @IBAction func captureCamera(_ sender: Any) {
        CameraManagerHelper.shared.capturePicture(completion: { img in
            self.imgCapturedView.image = img
        })
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        CameraManagerHelper.shared.toggleTorch()
        self.dismiss(animated: true, completion: nil)
    }
    @objc func updateOrientation(){
        CameraManagerHelper.shared.orientationChanged()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    @objc func fireTimer(shouldIncrement:Bool = true) {
        recordedVideoSeconds += 1
        let secondsString = String(format: "%02d", recordedVideoSeconds % 60)
        let minutesString = String(format: "%02d", recordedVideoSeconds / 60)
        lblTime.text = "\(minutesString):\(secondsString)"
        print("RecordedVideoSeconds: \(recordedVideoSeconds)")
    }
}

struct K {
    static let CAMERA_FLASH_SETTING = "camerFlashSetting"
}
extension UserDefaults {
    var isCameraFlashOn: Bool? {
        get {
            if UserDefaults.standard.value(forKey: K.CAMERA_FLASH_SETTING) == nil {
                return nil
            }
            return UserDefaults.standard.bool(forKey: K.CAMERA_FLASH_SETTING)
        }
        set(newValue) {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: K.CAMERA_FLASH_SETTING)
            } else {
                UserDefaults.standard.setValue(newValue, forKey: K.CAMERA_FLASH_SETTING)
            }
        }
    }
}
