//
//  AlbumCollectionCell.swift
//  CustomCameraManager
//
//  Created by Nitin Bhatia on 12/31/20.
//

import UIKit

class AlbumCollectionCell: UICollectionViewCell {
    
    //outlets
    @IBOutlet var itemImage: UIImageView!
    @IBOutlet var itemTypeImage: UIImageView!
    @IBOutlet var selectedView: UIView!
    @IBOutlet var imgCheckMark: UIImageView!
    
    func setCell(itemImage:UIImage,type:FeedType) {
        self.itemImage.image = itemImage
        
        if type == .image {
            self.itemTypeImage.image = UIImage(named: "img")
        } else {
            self.itemTypeImage.image = UIImage(named: "video")
        }
    }
    
    var setSelected : Bool = false {
        didSet {
            selectedView.isHidden = !setSelected
            imgCheckMark.isHidden = !setSelected
        }
    }
    
}
