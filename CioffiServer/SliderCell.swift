//
//  SliderCell.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 26/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa

class SliderCell: NSTableCellView {
    
    @IBOutlet weak var slider: NSSlider!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func sliderChanged(_ sender: AnyObject) {
        let value = slider.intValue
        textField?.stringValue = String(value)        
    }
    
    func configure(min: Int, max: Int, current: Int32) {
        slider.minValue = Double(min)
        slider.maxValue = Double(max)
        slider.intValue = current
        textField?.stringValue = String(current)
    }

}
