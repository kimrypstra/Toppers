//
//  NowPlayingDelegate.swift
//  Topper
//
//  Created by Kim Rypstra on 17/10/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import Foundation

protocol NowPlayingDelegate: class {
    func didTriggerNextTrack()
    func didTriggerPreviousTrack()
    func didTriggerPausePlay()
}
