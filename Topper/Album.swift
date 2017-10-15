//
//  Album.swift
//  Topper
//
//  Created by Kim Rypstra on 30/9/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit

class Album: NSObject {
    private let albumName: String!
    private let albumID: String!
    private let albumArtworkURL: String!
    private let artistName: String
    
    init(name: String, id: Int, artworkURL: String, artistName: String) {
        self.albumName = name
        self.albumID = "\(id)"
        self.albumArtworkURL = artworkURL
        self.artistName = artistName
    }
    
    func id() -> String {
        return albumID
    }
    
    func name() -> String {
        return albumName
    }
    
    func artworkURL() -> String {
        return albumArtworkURL
    }
    
    func artistsName() -> String {
        return artistName 
    }
}
