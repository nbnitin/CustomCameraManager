//
//  Album.swift
//  CustomCameraManager
//
//  Created by Nitin Bhatia on 12/31/20.
//

import UIKit

class Album : UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    
    //outlets
    @IBOutlet var albumCollection: UICollectionView!
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var delItemBtn: UIBarButtonItem!
    @IBOutlet var closeEditingBtn: UIBarButtonItem!
    
    //variables
    var albumCollectionItem : [CameraGalleryItem] = [CameraGalleryItem]()
    var selectedIndex = [IndexPath]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupLongPressGestureRecognizer()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumCollectionItem.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AlbumCollectionCell
        cell.setCell(itemImage: albumCollectionItem[indexPath.row].image!, type: FeedType(rawValue: albumCollectionItem[indexPath.row].contentType)!)
        cell.backgroundColor = .red
        
        cell.setSelected = selectedIndex.contains(indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (albumCollection.frame.width - 50) / 2, height: (albumCollection.frame.width - 50) / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
//        selectedIndex.append(indexPath)
        
        if toolBar.isHidden {
            goToDetailView(indexPath:indexPath)
            return
        }
        if let index = selectedIndex.firstIndex(of: indexPath) {
            selectedIndex.remove(at: index)
        } else {
            selectedIndex.append(indexPath)
        }
        collectionView.reloadItems(at: [indexPath])
    }
    
    func setupLongPressGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        gestureRecognizer.minimumPressDuration = 0.5
        gestureRecognizer.delaysTouchesBegan = true
        albumCollection.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func longPressAction(gesture: UILongPressGestureRecognizer) {
        
        if toolBar.isHidden {
            toolBar.isHidden = false
            let p = gesture.location(in: albumCollection)
            
            if let indexPath = albumCollection.indexPathForItem(at: p) {
                // get the cell at indexPath (the one you long pressed)
                selectedIndex.append(indexPath)
                albumCollection.reloadItems(at: [indexPath])
            } else {
                print("couldn't find index path")
            }
        }
    }
    
    private func setupData() {
        albumCollectionItem.removeAll()
        albumCollectionItem = CameraManagerHelper.shared.loadCameraGalleryItems()
        
        for (index,item) in albumCollectionItem.enumerated() {
            albumCollectionItem[index].image = item.asset?.convert(toFull: false)
        }
        albumCollection.reloadData()
    }
    
    @IBAction func deleteSelectedAction(_ sender: Any) {
        let assetsToDelete = NSMutableArray()
        
        let _ = selectedIndex.map{
            assetsToDelete.add(albumCollectionItem[$0.row].asset)
        }
        CameraManagerHelper.shared.deleteAssets(assets: assetsToDelete, completion: {status in
            if status {
                self.selectedIndex.removeAll()
            }
            self.setupData()
        })
    }
    
    func goToDetailView(indexPath:IndexPath) {
        
        if albumCollectionItem[indexPath.row].contentType == FeedType.image.rawValue {
            performSegue(withIdentifier: "showImage", sender: nil)
        } else {
            performSegue(withIdentifier: "showVideo", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImage" {
            //image action
            let destination = segue.destination as? ImageViewVC
            destination?.data = albumCollectionItem[selectedIndex.first?.row ?? 0]
            selectedIndex.removeAll()
        } else {
            //video action
        }
    }
    
    @IBAction func closeEditingAction(_ sender: Any) {
        toolBar.isHidden = true
        selectedIndex.removeAll()
        albumCollection.reloadData()
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
