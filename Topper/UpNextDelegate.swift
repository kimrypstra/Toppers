//
//  UpNextDelegate.swift
//  Topper
//
//  Created by Kim Rypstra on 17/9/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit

protocol UpNextDelegate: class {
    func upNextViewDidReorderSongs()
    func upNextViewDidSelectSong(_at index: Int)
    func upNextViewDidRemoveSong() 
}
