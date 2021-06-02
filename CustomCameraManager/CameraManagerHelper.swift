//
//  CameraManagerHelper.swift
//  CustomCameraManager
//
//  Created by Nitin Bhatia on 12/31/20.
//

import Foundation
import UIKit
import Photos
import AVKit


class CameraManagerHelper : AVScreenshotProtocol {
    
    static let shared = CameraManagerHelper()
    
    private var cameraManager : CameraManager!
    
    private var albumName: String = ""
    var isFront : Bool = false
    var hasFlash : Bool = false

    private init() {
        
    }
    
    func setupCamera(view: UIView, albumName: String, completion: @escaping (Bool) -> Void) {
        
        if cameraManager == nil {
            cameraManager = CameraManager()
        }
        if isFront {
            cameraManager.cameraDevice = .front
        } else {
            cameraManager.cameraDevice = .back
        }
        
        if cameraManager.currentCameraStatus() == .ready {
            DispatchQueue.main.async {
                self.cameraManager.addPreviewLayerToView(view, newCameraOutputMode: .stillImage)
            }
        }
        self.albumName = albumName
        cameraManager.imageAlbumName = self.albumName
        cameraManager.videoAlbumName = self.albumName
        cameraManager.askUserForCameraPermission { (granted) in
           completion(granted)
        }
                updateFlash()

    }
    
    //MARK: updates flash
    func updateFlash(isVideoRecordingStarts:Bool = false){
        if isFront && isVideoRecordingStarts == false {
            hasFlash = cameraManager.hasFlash
        } else if isFront && isVideoRecordingStarts == true {
            hasFlash = false
        } else {
            //now again reseting it to old value
            self.toggleFlash(status: UserDefaults.standard.isCameraFlashOn!)
            hasFlash = AVCaptureDevice.default(for: .video)?.isTorchAvailable ?? false
        }
    }
    
    func orientationChanged(){
        cameraManager.resetOrientation()
    }
    
    func switchCameraView() {
        cameraManager.cameraDevice = toggleCamera()
    }
    
    func capturePicture(completion: @escaping (UIImage?)-> Void) {
       
        while true {
            debugPrint("inside capture")
            cameraManager.cameraOutputMode = CameraOutputMode.stillImage
            if cameraManager.cameraOutputMode == CameraOutputMode.stillImage {
                sleep(1)
                break
            }
        }
        cameraManager.capturePictureWithCompletion { (captureResult) in
            switch captureResult {
            case .success(let content):
                completion(content.asImage)
                
            case .failure(let error):
                debugPrint("Failed to capture Image: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    func startVideoRecording() {
//        while true {
//            cameraManager.cameraOutputMode = CameraOutputMode.videoWithMic
//            if cameraManager.cameraOutputMode == CameraOutputMode.videoWithMic {
//                sleep(1)
//                break
//            }
//        }
        cameraManager.cameraOutputMode = CameraOutputMode.videoWithMic
                updateFlash(isVideoRecordingStarts: true)
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3, execute: {
            self.cameraManager.startRecordingVideo()
        })
    }
    
    func stopVideoRecording(completion: @escaping (UIImage?) -> ()) {
        cameraManager.stopVideoRecording { (videoURL, error) in
            guard let videoURL = videoURL else {
                //Handle error of no recorded video URL
                debugPrint("Getting Error while retrieving video url")
                return
            }
            debugPrint("Video url: \(videoURL) and File size: \(self.cameraManager.recordedFileSize)")
            let urlAsset = AVURLAsset(url: videoURL)
            let image = Self.generateThumbnailFromAsset(asset: urlAsset, forTime: CMTimeMake(value: 0, timescale: 1))
            completion(image)
        }
        //video recording flash remains on even after video stops recording, if user turn it on during the video recording
        if isFront == false {
           // toggleTorch()
        }
        self.updateFlash()
    }
    
    func isPHPhotoLibraryStatusNotDetermined() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .notDetermined
    }
    
    func getCameraItemAsImage(completion: @escaping (UIImage?) -> Void) {
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                completion(self.getLastCameraItemAsImage())
            } else {
                completion(nil)
            }
        }
    }
    
    func getLastCameraItemAsImage() -> UIImage? {
        let asset = getLastGalleryCameraAsset(albumName: self.albumName)
        guard let lastCameraAsset = asset else {
            debugPrint("Found nil in AsImage")
            return nil
        }
        return lastCameraAsset.convert(toFull: false)
    }
    
    func loadCameraGalleryItems() -> [CameraGalleryItem] {
        var items: [CameraGalleryItem] = []
        guard let assets = getAllGalleryCameraAssets(albumName: albumName) else {
            debugPrint("Found Nil While Fetching All Assets from Album \(CAMERA_ALBUM_NAME)")
            return items
        }
      
        var assetType = ""
        assets.enumerateObjects({ (asset, index, bool) in
            if asset.mediaType == .video {
                assetType = FeedType.video.rawValue
            } else if asset.mediaType == .image {
                assetType = FeedType.image.rawValue
            }
            let cameraItem = CameraGalleryItem(asset: asset, contentURL: nil, thumbnailURL: nil, contentType: assetType, source: "device", originalFileName: asset.getFileName())
            items.append(cameraItem)
        })
        return items
    }
    
    private func toggleCamera() -> CameraDevice {
        if cameraManager.cameraDevice == .front {
                    updateFlash()
            return .back
        }
                updateFlash()
        return .front
    }
    
    
    private func getAllGalleryAssetCollection(albumName: String) -> PHAssetCollection? {
        let fetchoptions = PHFetchOptions()
        fetchoptions.predicate = NSPredicate(format: "title = %@", albumName)
        let resultCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchoptions)
        return resultCollections.firstObject
    }
    
    func getAllGalleryCameraAssets(albumName: String) -> PHFetchResult<PHAsset>? {
        let collection = getAllGalleryAssetCollection(albumName: albumName)
        let assetFetchOption = PHFetchOptions()
        assetFetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        guard let assetCollection = collection else { return nil }
        return  PHAsset.fetchAssets(in: assetCollection, options: assetFetchOption)
    }
    
    func getGalleryCameraAssets(albumName: String, mediaTypeValue: Int) -> PHFetchResult<PHAsset>? {
        let collection = getAllGalleryAssetCollection(albumName: albumName)
        let assetFetchOption = PHFetchOptions()
        assetFetchOption.predicate = NSPredicate(format: "mediaType == %d", mediaTypeValue)
        assetFetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        guard let assetCollection = collection else { return nil }
        return  PHAsset.fetchAssets(in: assetCollection, options: assetFetchOption)
    }
    
    func getCameraGalleryItems(albumName: String, mediaTypeValue: Int) -> [CameraGalleryItem] {
        var items: [CameraGalleryItem] = []
        guard let assets = getGalleryCameraAssets(albumName: albumName, mediaTypeValue: mediaTypeValue) else {
                  debugPrint("Found Nil While Fetching All Assets from Album \(CAMERA_ALBUM_NAME)")
                  return items
              }
       
        var assetType = ""
        assets.enumerateObjects({ (asset, index, bool) in
            if asset.mediaType == .video {
                assetType = FeedType.video.rawValue
            } else if asset.mediaType == .image {
                assetType = FeedType.image.rawValue
            }
            let cameraItem = CameraGalleryItem(asset: asset, contentURL: nil, thumbnailURL: nil, contentType: assetType, source: "device", originalFileName: asset.getFileName())
            items.append(cameraItem)
        })
        return items
    }
    
    private func getLastGalleryCameraAsset(albumName: String) -> PHAsset? {
        guard let allAsset = getAllGalleryCameraAssets(albumName: albumName) else {
            return nil
        }
        return allAsset.firstObject
    }
    
    func deleteAssets(assets: NSMutableArray, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }) { (success, error) in
            if(success){
                // Move to the main thread to execute
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    //MARK: toggle flash settings()
    func toggleFlash(status: Bool){
        cameraManager.flashMode = status == true ? .on : .off
    }
    
    //MARK: toggle torch
    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
            guard device.hasTorch else { return }

            do {
                try device.lockForConfiguration()

                if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                    device.torchMode = AVCaptureDevice.TorchMode.off
                } else {
//                    do {
//                        try device.setTorchModeOn(level: 1.0)
//                    } catch {
//                        print(error)
//                    }
                }

                device.unlockForConfiguration()
            } catch {
                print(error)
            }
    }
}
