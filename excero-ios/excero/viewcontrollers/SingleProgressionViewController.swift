//
//  SingleProgressionViewController.swift
//  excero
//
//  Created by Alessandro on 14.02.24.
//

import UIKit

class SingleProgressionViewController: UIViewController, InitialDataExpanded {

    
    private var containedViewController: GameViewController?
    private var dataToPass: Dictionary<String, NSObject>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gameViewController" {
           if let vc = segue.destination as? GameViewController {
               self.containedViewController = vc
               if let data = self.dataToPass {
                   let dataEnabledVC = self.containedViewController! as InitialDataExpanded
                   dataEnabledVC.setData(initialData: data)
                   self.dataToPass = nil
               }
           }
       }
    }
    
    func setData(initialData: Dictionary<String, NSObject>) {
        self.dataToPass = initialData
    }

}
