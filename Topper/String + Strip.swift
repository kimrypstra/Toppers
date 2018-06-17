//
//  String + Strip.swift
//  Topper
//
//  Created by Kim Rypstra on 20/12/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

extension String {
    var rstrip: String {
        var string = self
        while string.last == " " {
            //string = string.dropLast()
        }
        return String(string)
    }
    
    var lstrip: String {
        var s = self.characters
        while s.first == " " {
            s.dropFirst()
        }
        return String(s)
    }
}
