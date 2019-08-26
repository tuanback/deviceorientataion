//
//  ViewController.swift
//  DeviceOrientationProvider
//
//  Created by Tuan on 26/08/2019.
//  Copyright © 2019 Next Aeon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    DeviceOrientationProvider.shared.start()
  }


}

