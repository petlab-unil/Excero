//
//  SEPSelectionViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 28.11.22.
//

import UIKit

class SEPSelectionViewController: UIViewController {
    
    @IBOutlet weak var carouselCollectionView: UICollectionView!
    
    @IBOutlet weak var pageController: UIPageControl!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var backgroundEffectView: UIVisualEffectView!
    @IBOutlet weak var selectButton: UIButton!
    
    private let availableSEPs: Dictionary<String, String> = [
         "hamster_preview": "hamster_preview",
         "husky_preview": "husky_preview",
         "raccoon_preview": "raccoon_preview",
         "redpanda_preview": "redpanda_preview"
    ]
    
    private var selectedSEP: SEPSelectionViewCell?
    
    private var currentPage = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.carouselCollectionView.showsHorizontalScrollIndicator = false
        self.carouselCollectionView.dataSource = self
        self.carouselCollectionView.backgroundColor = .clear 
        self.carouselCollectionView.collectionViewLayout = SEPSelectionViewLayout()
        self.carouselCollectionView.isScrollEnabled = false
        
        self.pageController.currentPage = self.currentPage
        self.pageController.numberOfPages = self.availableSEPs.count
        self.pageController.pageIndicatorTintColor = .gray
        self.pageController.currentPageIndicatorTintColor = .white
        
        let rightGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(SEPSelectionViewController.swipeHandle(_:)))
        rightGestureRecognizer.direction = .right
        let leftGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(SEPSelectionViewController.swipeHandle(_:)))
        leftGestureRecognizer.direction = .left
        self.view.addGestureRecognizer(rightGestureRecognizer)
        self.view.addGestureRecognizer(leftGestureRecognizer)
        self.selectButton.addTarget(self, action: #selector(SEPSelectionViewController.selectButtonTapped(_:)), for: .touchUpInside)
    }
    
    func setCurrentSelection(_ sep: SEPSelectionViewCell) {
        self.selectedSEP = sep
        self.updateButtonStatus()
    }
    
    private func updateButtonStatus() {
        if let _ = self.selectedSEP {
            self.selectButton.isEnabled = true
        } else {
            self.selectButton.isEnabled = false
        }
    }
    
    @objc func swipeHandle(_ gestureRecognizer: UISwipeGestureRecognizer) {
        switch(gestureRecognizer.direction) {
        case .left:
            if(self.currentPage < self.availableSEPs.count-1) {
                self.currentPage += 1
                self.carouselCollectionView.scrollToItem(at: IndexPath(row: self.currentPage, section: 0), at: .centeredHorizontally, animated: true)
                if let cell = self.carouselCollectionView.cellForItem(at: IndexPath(row: self.currentPage, section: 0)) {
                    self.setCurrentSelection(cell as! SEPSelectionViewCell)
                }
                self.pageController.currentPage = self.currentPage
            }
            break
        case .right:
            if(self.currentPage > 0) {
                self.currentPage -= 1
                self.carouselCollectionView.scrollToItem(at: IndexPath(row: self.currentPage, section: 0), at: .centeredHorizontally, animated: true)
                if let cell = self.carouselCollectionView.cellForItem(at: IndexPath(row: self.currentPage, section: 0)) {
                    self.setCurrentSelection(cell as! SEPSelectionViewCell)
                }
                self.pageController.currentPage = self.currentPage
            }
            break
        default:
            break
        }
        
        if let color = UIImage(named: Array(self.availableSEPs.keys)[self.currentPage])?.averageColor {
            backgroundEffectView.backgroundColor = color.withAlphaComponent(0.2)
        } else {
            backgroundEffectView.backgroundColor = .white
        }
    }
    
    @objc func selectButtonTapped(_ sender: UIButton) {
        guard let rootWindow = self.view.window else {return}
        var mainView: UIStoryboard
        var startingVC: UIViewController
        mainView = UIStoryboard(name: "Main", bundle: nil)
        startingVC = mainView.instantiateViewController(withIdentifier: "Main") as UIViewController
        rootWindow.rootViewController?.dismiss(animated: false)
        rootWindow.rootViewController = startingVC
    }

}
extension SEPSelectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "testCell", for: indexPath)
                as? SEPSelectionViewCell else {return UICollectionViewCell()}
        let keys = Array(self.availableSEPs.keys)
        cell.setImage(named: keys[indexPath.item])
        self.setCurrentSelection(cell)
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.availableSEPs.count
    }
}

class SEPSelectionViewCell: UICollectionViewCell {
    private var spriteName: String = "hamster_head"
    private var selectionStatus: Bool = false
    private let borderWidth: CGFloat = 5
    private let borderColor: UIColor = UIColor.red
    private let borderRadius: CGFloat = 10
    
    private let headImage: UIImage
    private let holderView: UIImageView
    
    internal required init?(coder: NSCoder) {
        let image = UIImage(named: self.spriteName)!
        if image.size.width > image.size.height {
            self.headImage = image.resize(toWidth: 400)
        } else {
            self.headImage = image.resize(toHeight: 400)
        }
        self.holderView = UIImageView(image: self.headImage)
        self.holderView.contentMode = .scaleAspectFit
        super.init(coder: coder)
        self.contentView.addSubview(self.holderView)
    }
    
    override init(frame: CGRect) {
        let image = UIImage(named: self.spriteName)!
        if image.size.width > image.size.height {
            self.headImage = image.resize(toWidth: 400)
        } else {
            self.headImage = image.resize(toHeight: 400)
        }
        self.holderView = UIImageView(image: self.headImage)
        self.holderView.contentMode = .scaleAspectFit
        super.init(frame: frame)
        self.contentView.addSubview(self.holderView)
    }
    
    internal init(headSpriteName: String) {
        self.spriteName = headSpriteName
        let image = UIImage(named: self.spriteName)!
        if image.size.width > image.size.height {
            self.headImage = image.resize(toWidth: 400)
        } else {
            self.headImage = image.resize(toHeight: 400)
        }
        self.holderView = UIImageView(image: self.headImage)
        self.holderView.contentMode = .scaleAspectFit
        super.init(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        self.contentView.addSubview(self.holderView)
    }
    
    func setImage(named: String) {
        self.spriteName = named
        let image = UIImage(named: self.spriteName)!
        if image.size.width > image.size.height {
            self.holderView.image = image.resize(toWidth: 400)
        } else {
            self.holderView.image = image.resize(toHeight: 400)
        }
        self.holderView.contentMode = .scaleAspectFit
    }
    
    func getImage() -> String {
        return self.spriteName
    }
    
    func toggleSelection() {
        //self.setSelected(selectionStatus: !self.selectionStatus)
    }
    
    func setSelected(selectionStatus: Bool = true) {
        self.selectionStatus = selectionStatus
        if(selectionStatus) {
            self.contentView.layer.borderWidth = self.borderWidth
            self.contentView.layer.borderColor = self.borderColor.cgColor
            self.contentView.layer.cornerRadius = self.borderRadius
        } else {
            self.contentView.layer.borderColor = UIColor.clear.cgColor
        }
    }
}
class SEPSelectionViewLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else {return}
        let collectionSize = collectionView.bounds.inset(by: collectionView.layoutMargins)
        let columns = 1.0
        let cellWidth = (collectionSize.width / columns).rounded(.down)
        
        self.scrollDirection = .horizontal
        self.itemSize = CGSize(width: 400, height: 400)
        self.sectionInset = UIEdgeInsets(top: self.minimumInteritemSpacing, left: (collectionView.frame.width - self.itemSize.width) / 2, bottom: 0.0, right: (collectionView.frame.width - self.itemSize.width) / 2)
        self.sectionInsetReference = .fromSafeArea
        self.minimumLineSpacing = collectionView.frame.width - self.itemSize.width
    }
}


