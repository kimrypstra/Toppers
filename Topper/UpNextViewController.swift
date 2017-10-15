//
//  UpNextViewController.swift
//  Topper
//
//  Created by Kim Rypstra on 17/9/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit

class UpNextViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var songs: [Song] = []
    var currentSongIndex: Int?
    var delegate: UpNextDelegate! 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "upNextCell", for: indexPath)
        let song = songs[indexPath.row]
        cell.textLabel?.text = song.getTrackName()
        cell.detailTextLabel?.text = song.getArtistName()
        cell.imageView?.layer.cornerRadius = 5
        
        do {
            guard let url = URL(string: songs[indexPath.row].getSmallArtworkURL()) else {
                print("Error forming URL")
                return cell}
            cell.imageView?.image = UIImage(data: try Data(contentsOf: url))
        } catch let error {
            print(error)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate.upNextViewDidSelectSong(_at: indexPath.row)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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
