//
//  TopperTextField.swift
//  Topper
//
//  Created by Kim Rypstra on 29/8/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit

class TopperTextField: UITextField {

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        //return CGRectInset(bounds, 10, 10)
        return bounds.insetBy(dx: 10, dy: 10)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 10)
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
