//
//  SettingViewController.swift
//  CrossGuide
//
//  Created by XueliangZhu on 09/06/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {

    weak var delegate: SettingDelegate?
    
    var threshold: Float!
    var arrayCount: Int!
    var timeInterval: Double!
    
    @IBOutlet weak var thresholdTextField: UITextField!
    @IBOutlet weak var arrayCountTextField: UITextField!
    @IBOutlet weak var timeIntervalTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        thresholdTextField.text = String(threshold)
        arrayCountTextField.text = String(arrayCount)
        timeIntervalTextField.text = String(timeInterval)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        let thresholdStr = thresholdTextField.text!
        let arrayCountStr = arrayCountTextField.text!
        let timeIntervalStr = timeIntervalTextField.text!
        
        guard let threshold = Float(thresholdStr), let arrayCount = Int(arrayCountStr), let timeInterval = Double(timeIntervalStr) else {
            return
        }
        
        delegate?.didChangedSettings(threshold: threshold, arrayCount: arrayCount, timeInterval: timeInterval)
        navigationController?.popViewController(animated: true)
    }
}
