//
//  Song.swift
//  Topper
//
//  Created by Kim Rypstra on 31/8/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import Foundation

class Song {
    private let artistID: String
    private let artistName: String
    private let albumName: String
    private let trackName: String
    private let trackID: String
    private let artworkBaseURL: String
    private let trackLength: Int
    private let genre: String
    private var bgColor: String?
    private var textColor: String?
    private var textColor2: String?
    private var textColor3: String?
    private var textColor4: String?
    
    init(artistID: String, artistName: String, albumName: String, trackName: String, trackID: String, artworkBaseURL: String, trackLength: Int, genre: String, bg: String?, tc: String?, tc2: String?, tc3: String?, tc4: String?) {
        self.artistID = artistID
        self.artistName = artistName
        self.albumName = albumName
        self.trackName = trackName
        self.trackID = trackID
        self.artworkBaseURL = artworkBaseURL
        self.trackLength = trackLength
        self.genre = genre
        self.bgColor = bg
        self.textColor = tc
        self.textColor2 = tc2
        self.textColor3 = tc3
        self.textColor4 = tc4
    }
    
    func setColours(bg: String?, tc: String?, tc2: String?, tc3: String?, tc4: String?) {
        self.bgColor = bg
        self.textColor = tc
        self.textColor2 = tc2
        self.textColor3 = tc3
        self.textColor4 = tc4
    }
    
    func coloursAreSet() -> Bool {
        if self.bgColor != nil {
            return true
        } else {
            return false 
        }
    }
    
    func getColours() -> [String: String?] {
        let artwork = [
            "bg" : self.bgColor,
            "tc" : self.textColor,
            "tc2" : self.textColor2,
            "tc3" : self.textColor3,
            "tc4" : self.textColor4
        ]
        return artwork
    }
    
    func getTrackName() -> String {
        return trackName
    }
    
    func getTrackID() -> String {
        return trackID
    }
    
    func getArtistName() -> String {
        return artistName
    }
    
    func getLargeArtworkURL() -> String {
        let largeURL: NSString = NSString(string: artworkBaseURL)
        return largeURL.replacingOccurrences(of: "100x100", with: "900x900")
    }
    
    func getSmallArtworkURL() -> String {
        return artworkBaseURL
    }
    
    func getAlbumName() -> String {
        return albumName
    }
}
