//
//  nowPlayingCard.swift
//  Topper
//
//  Created by Kim Rypstra on 15/10/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit

class nowPlayingCard: UIViewController {

    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    
    init(albumArt: UIImage, trackName: String, artistName: String, albumName: String) {
        super.init(nibName: "nowPlayingCard", bundle: nil)
        self.albumArtImageView.image = albumArt
        self.trackNameLabel.text = trackName
        self.artistNameLabel.text = artistName
        self.albumNameLabel.text = albumName
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
