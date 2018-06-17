//
//  UpNextTableViewCell.swift
//  Topper
//
//  Created by Kim Rypstra on 20/10/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit

class UpNextTableViewCell: UITableViewCell {

    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var albumArt: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        albumArt.layer.cornerRadius = 5
        albumArt.clipsToBounds = true
        self.backgroundColor = UIColor.clear
    }

    func setBackgroundColor(color: UIColor) {
        self.backgroundColor = color 
    }
    
    func setTextColor(color: UIColor) {
        self.albumName.textColor = color
        self.songTitle.textColor = color
        self.artistName.textColor = color 
    }
    
    func setArtistMode(isArtist: Bool) {
        if isArtist {
            albumArt.layer.cornerRadius = albumArt.frame.width / 2
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
