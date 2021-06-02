//
//  CameraHelperExtension.swift
//  CustomCameraManager
//
//  Created by Nitin Bhatia on 12/31/20.
//

import Foundation
import UIKit
import Photos
import AVKit


enum FeedType : String {
    case video = "video"
    case image = "image"
}


struct CameraGalleryItem {
    let asset: PHAsset?
    let contentURL: String?
    let thumbnailURL: String?
    let contentType: String
    let source: String
    let originalFileName: String?
    var image : UIImage?
}

protocol AVScreenshotProtocol {
  static func generateThumbnailFromAsset(asset: AVAsset, forTime time: CMTime) -> UIImage?
}

extension AVScreenshotProtocol {
    static func generateThumbnailFromAsset(asset: AVAsset, forTime time: CMTime) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        var actualTime: CMTime = CMTime.zero
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            let image = UIImage(cgImage: imageRef)
            return image
        } catch let error as NSError {
            print("\(error.description). Time: \(actualTime)")
        }
        debugPrint("Found nil in get Thumbnail")
        return nil
    }
}

extension PHAsset: AVScreenshotProtocol {
    
    func convert(toFull: Bool) -> UIImage? {
        return convert(toFull: toFull, time: CMTimeMake(value: 0, timescale: 1))
    }
        
    func convert(toFull: Bool, time: CMTime) -> UIImage? {
        var fetchedImage: UIImage?
        if self.mediaType == .image {
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            if toFull {
                PHCachingImageManager.default().requestImageData(for: self, options: option) { (imageData, _, _, _) in
                    
                    guard let imageData = imageData else {
                        debugPrint("Found nil in convert Image")
                        return }
                    fetchedImage = UIImage(data: imageData)
                }
            } else {
                PHCachingImageManager.default().requestImage(for: self, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFit, options: option) { (image, _) in
                    fetchedImage = image
                }
            }
        } else if self.mediaType == .video {
            let group = DispatchGroup()
            let option = PHVideoRequestOptions()
            group.enter()
            PHCachingImageManager.default().requestAVAsset(forVideo: self, options: option) { (avAsset, _, _) in
                guard let avAsset = avAsset else {
                    debugPrint("Found nil in convert video")
                    group.leave()
                    return
                }
                
                let image  = Self.generateThumbnailFromAsset(asset: avAsset, forTime: time)
                fetchedImage = image
                group.leave()
            }
            group.wait()
        }
        return fetchedImage
    }
    
    func convert(completion: @escaping (AVPlayerItem?) -> Void) {
        if self.mediaType == .video {
            let option = PHVideoRequestOptions()
            PHCachingImageManager.default().requestPlayerItem(forVideo: self, options: option) { (playerItem, _) in
                if let playerItem = playerItem {
                    DispatchQueue.main.async {
                    completion(playerItem)
                    }
                } else {
                    debugPrint("Found nil in convert video")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func getAVAsset(completion: @escaping (AVAsset?) -> Void) {
        if self.mediaType == .video {
            let option = PHVideoRequestOptions()
            PHCachingImageManager.default().requestAVAsset(forVideo: self, options: option) { (avasset, _, _) in
                completion(avasset)
            }
        }
    }
    
    func getAVURLAsset(completion: @escaping (AVURLAsset?) -> Void) {
        if self.mediaType == .video {
                    let option = PHVideoRequestOptions()
                    PHCachingImageManager.default().requestAVAsset(forVideo: self, options: option) { (avasset, _, _) in
                        completion(avasset as? AVURLAsset)
                    }
                }
    }
    
    func getFileName() -> String {
        return PHAssetResource.assetResources(for: self).first?.originalFilename ?? ""
    }
}


