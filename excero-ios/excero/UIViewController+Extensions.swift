//
//  UIViewController+Extensions.swift
//  excero
//
//  Created by Alessandro Silacci on 15.09.22.
//

import UIKit

fileprivate var backgroundLoadingView: UIView?
fileprivate var loadingView: UIView?

extension UIViewController {
    func updateTitleView(title: String, subtitle: String?) {
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.sizeToFit()

        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = .center
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.sizeToFit()

        let titleView =
          UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 30))
        titleView.addSubview(titleLabel)
        if subtitle != nil {
          titleView.addSubview(subtitleLabel)
        } else {
          titleLabel.frame = titleView.frame
        }
        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
        if widthDiff < 0 {
          let newX = widthDiff / 2
          subtitleLabel.frame.origin.x = abs(newX)
        } else {
          let newX = widthDiff / 2
          titleLabel.frame.origin.x = newX
        }

        navigationItem.titleView = titleView
    }
    
    func showActivityIndicator(text: String = "Chargement...", subtext: String?, screenBorderSpacing: CGFloat = 100.0, cornerRadius: CGFloat = 10.0, lockWhenDisplayed: Bool = true, display: Bool) {
        if display {
            loadingView = UIView(frame: CGRect(x: self.view.bounds.width/2 - 100, y: self.view.bounds.height/2 - 50, width: 200, height: 200))
            loadingView?.backgroundColor = UIColor.black
            loadingView?.layer.cornerRadius = cornerRadius
            let indicator = UIActivityIndicatorView(style: .large)
            let upperTextView = UITextView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width/2, height: 0))
            upperTextView.text = text
            upperTextView.sizeToFit()
            upperTextView.backgroundColor = .clear
            upperTextView.font = UIFont.boldSystemFont(ofSize: 16)
            upperTextView.textAlignment = .center
            upperTextView.textColor = .white
            let downTextView = UITextView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width/2, height: 0))
            downTextView.text = subtext
            downTextView.sizeToFit()
            downTextView.backgroundColor = .clear
            downTextView.font = UIFont.systemFont(ofSize: 14)
            downTextView.textAlignment = .center
            downTextView.textColor = .white
            indicator.tintColor = .white
            indicator.color = .white
            indicator.center = loadingView!.center
            indicator.startAnimating()
            loadingView?.addSubview(upperTextView)
            loadingView?.addSubview(indicator)
            loadingView?.addSubview(downTextView)
            
            backgroundLoadingView = UIView(frame: self.view.frame)
            backgroundLoadingView?.backgroundColor = UIColor.lightGray
            backgroundLoadingView?.isOpaque = false
            backgroundLoadingView?.alpha = 0.2
            
            self.view.addSubview(backgroundLoadingView!)
            self.view.addSubview(loadingView!)
            
            indicator.translatesAutoresizingMaskIntoConstraints = false
            upperTextView.translatesAutoresizingMaskIntoConstraints = false
            downTextView.translatesAutoresizingMaskIntoConstraints = false
            loadingView?.translatesAutoresizingMaskIntoConstraints = false
            upperTextView.isScrollEnabled = false
            downTextView.isScrollEnabled = false
            NSLayoutConstraint.activate([
                upperTextView.topAnchor.constraint(equalTo: loadingView!.safeAreaLayoutGuide.topAnchor),
                upperTextView.leadingAnchor.constraint(equalTo: loadingView!.safeAreaLayoutGuide.leadingAnchor),
                upperTextView.trailingAnchor.constraint(equalTo: loadingView!.safeAreaLayoutGuide.trailingAnchor),
                indicator.topAnchor.constraint(equalTo: upperTextView.bottomAnchor),
                downTextView.topAnchor.constraint(equalTo: indicator.bottomAnchor),
                downTextView.widthAnchor.constraint(equalTo: loadingView!.safeAreaLayoutGuide.widthAnchor),
                loadingView!.leftAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: screenBorderSpacing),
                //loadingView!.rightAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: screenBorderSpacing),
                loadingView!.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
                loadingView!.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
                loadingView!.bottomAnchor.constraint(equalTo: downTextView.safeAreaLayoutGuide.bottomAnchor),
                indicator.centerXAnchor.constraint(equalTo: loadingView!.safeAreaLayoutGuide.centerXAnchor),
                backgroundLoadingView!.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
                backgroundLoadingView!.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor)
            ])
            
            loadingView?.sizeToFit()
        } else {
            backgroundLoadingView?.removeFromSuperview()
            backgroundLoadingView = nil
            loadingView?.removeFromSuperview()
            loadingView = nil
        }
        if self.view.isUserInteractionEnabled {
            if lockWhenDisplayed {
                self.view.isUserInteractionEnabled = !display
            }
        } else {
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func displayViewControllerAsSheet(storyBoardName: String = "Main", viewControllerName: String, data: Dictionary<String, Any>? = nil,  completionHandler: @escaping (Any?) -> Void) {
        let sheetVC = UIStoryboard(name: storyBoardName, bundle: nil).instantiateViewController(withIdentifier: viewControllerName)
        if let data = data {
            let dbCompatibleVC = sheetVC as! DataBundledViewController
            dbCompatibleVC.dataBundle = data
        }
        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        self.present(sheetVC, animated: true, completion: nil)
    }
    
    func displayViewControllerAsSheet(storyBoardName: String = "Main", viewControllerName: String, detents: [UISheetPresentationController.Detent], data: Dictionary<String, Any>? = nil,  showGrabber: Bool = true, completionHandler: @escaping (Any?) -> Void) {
        let sheetVC = UIStoryboard(name: storyBoardName, bundle: nil).instantiateViewController(withIdentifier: viewControllerName)
        if let data = data {
            let dbCompatibleVC = sheetVC as! DataBundledViewController
            dbCompatibleVC.dataBundle = data
            dbCompatibleVC.complete = completionHandler
        }
        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = detents
            sheet.prefersGrabberVisible = showGrabber
            sheet.preferredCornerRadius = 20
        }
        
        self.present(sheetVC, animated: true, completion: nil)
    }
    
    
    func getViewControllerName() -> String {
        return String(describing: type(of: self))
    }
}
