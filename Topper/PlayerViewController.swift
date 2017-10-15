//
//  PlayerViewController.swift
//  Topper
//
//  Created by Kim Rypstra on 31/8/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit
import MediaPlayer

class PlayerViewController: UIViewController, UpNextDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {


    var songList: [Song] = []
    var upcomingSongs: [String] = []
    var playedSongs: [String] = []
    
    var userStoreID: String = ""
    var initialSearchScreenPresented = false
    var upNextExpanded = false
    
    @IBOutlet var backgroundTapRecog: UITapGestureRecognizer!
    @IBOutlet var upNextTapRecog: UITapGestureRecognizer!
    @IBOutlet weak var upNextTableViewVertConstraint: NSLayoutConstraint!
    @IBOutlet weak var upNextTableView: UITableView!
    @IBOutlet weak var albumArtRight: NSLayoutConstraint!
    @IBOutlet weak var albumArtLeft: NSLayoutConstraint!
    @IBOutlet weak var trackNameToArtSpacing: NSLayoutConstraint!
    @IBOutlet weak var albumArtTop: NSLayoutConstraint!
    @IBOutlet weak var albumArtWidth: NSLayoutConstraint!
    @IBOutlet weak var nextSongContainerView: UIView!
    @IBOutlet weak var nextSongContainerViewMask: UIView!
    @IBOutlet weak var albumArtShadow: UIView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var volumeView: MPVolumeView!
    @IBOutlet weak var albumArtImage: UIImageView!
    @IBOutlet weak var currentTrackName: UILabel!
    @IBOutlet weak var currentArtistName: UILabel!
    @IBOutlet weak var nextTrackName: UILabel!
    @IBOutlet weak var nextArtistName: UILabel!
    @IBOutlet weak var nextAlbumArtImage: UIImageView!
    @IBOutlet weak var albumArtDesaturated: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    
    //var musicPlayer = MPMusicPlayerController.applicationQueuePlayer()
    var musicPlayer = MPMusicPlayerController.systemMusicPlayer()
    var descriptor = MPMusicPlayerStoreQueueDescriptor()
    var storeManager = StoreManager()
    var commandCenter: MPRemoteCommandCenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        musicPlayer.stop()
        musicPlayer.beginGeneratingPlaybackNotifications()
        // prepare the list
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.playCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.playPause(forcePlay: false)
            return MPRemoteCommandHandlerStatus.success
        }
        commandCenter.pauseCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.playPause(forcePlay: false)
            return MPRemoteCommandHandlerStatus.success
        }
        commandCenter.togglePlayPauseCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.playPause(forcePlay: false)
            return MPRemoteCommandHandlerStatus.success
        }

        NotificationCenter.default.addObserver(self, selector: #selector(notificationResponder(notification:)), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationResponder(notification:)), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        
        volumeView.showsRouteButton = true
        volumeView.setRouteButtonImage(UIImage(named: "route"), for: .normal)
        volumeView.tintColor = UIColor.black
        volumeView.showsVolumeSlider = false
        
        if songList.count != 0 {
            songList.removeAll()
        }
        
        searchButton.isEnabled = false

        albumArtDesaturated.layer.cornerRadius = 8
        albumArtDesaturated.clipsToBounds = true
        albumArtShadow.layer.shadowColor = UIColor.black.cgColor
        albumArtShadow.layer.shadowOffset = CGSize(width: 0, height: 10)
        albumArtShadow.layer.shadowRadius = 10
        albumArtShadow.layer.shadowOpacity = 0.4
        albumArtShadow.layer.cornerRadius = 8
        albumArtImage.clipsToBounds = true
        albumArtImage.layer.cornerRadius = 8
        nextAlbumArtImage.clipsToBounds = true 
        nextAlbumArtImage.layer.cornerRadius = 4
        nextSongContainerView.layer.shadowColor = UIColor.black.cgColor
        nextSongContainerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        nextSongContainerView.layer.shadowRadius = 10
        nextSongContainerView.layer.shadowOpacity = 0.4
        
        self.backgroundTapRecog.isEnabled = false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func didTapBackground(_ sender: UITapGestureRecognizer) {
        didTapUpNext(upNextTapRecog)
        print("tapped background")
    }
    
    @IBAction func didTapUpNext(_ sender: UITapGestureRecognizer) {
        print("tapped up next")
        if upNextExpanded {
            upNextTableViewVertConstraint.constant = 5
            upNextExpanded = false
        } else {
            upNextExpanded = true
            upNextTableView.reloadData()
            upNextTableViewVertConstraint.constant = -200
        }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            if self.upNextExpanded {
                self.upNextTableView.isUserInteractionEnabled = true
                self.upNextTapRecog.isEnabled = false
                self.backgroundTapRecog.isEnabled = true
            } else {
                self.upNextTableView.reloadData()
                self.upNextTableView.isUserInteractionEnabled = false
                self.upNextTapRecog.isEnabled = true
                self.backgroundTapRecog.isEnabled = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if upNextExpanded {
            return songList.count - 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if songList.count > 0 {
            let cell = upNextTableView.dequeueReusableCell(withIdentifier: "upNextCell", for: indexPath)
            cell.textLabel?.text = songList[musicPlayer.indexOfNowPlayingItem + 1 + indexPath.row].getTrackName()
            return cell
        } else {
            let cell = upNextTableView.dequeueReusableCell(withIdentifier: "upNextCell", for: indexPath)
            cell.textLabel?.text = "test"
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didTapUpNext(upNextTapRecog)
    }
    
    func setUpSongList(list: [Song]) {
        musicPlayer.stop()
        self.upcomingSongs.removeAll()
        
        self.songList = list
        for song in songList {
            upcomingSongs.append(song.getTrackID())
        }
        
        getUpcomingSongColours()
        
        descriptor = MPMusicPlayerStoreQueueDescriptor.init(storeIDs: [])
        musicPlayer.setQueueWith(descriptor)
        print("upcomingSongs has \(upcomingSongs.count) entries")
        print(upcomingSongs)
        descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: upcomingSongs)
        musicPlayer.setQueueWith(descriptor)
        print("Descriptor has \(descriptor.storeIDs!.count) songs")
        setPlayerColours()
        playPause(forcePlay: true)
    }
    
    func setPlayerColours() {
        let musicPlayerIndex = musicPlayer.indexOfNowPlayingItem
        if musicPlayerIndex <= songList.count - 1 {
            guard let bgColorString = self.songList[musicPlayerIndex].getColours()["bg"] else {
                print("Error getting colours out of track")
                return
            }
            guard bgColorString != nil else {return}
            let c1 = UIColor(hexString: bgColorString!)
            UIView.animate(withDuration: 0.5) {
                self.view.backgroundColor = c1
                self.nextSongContainerView.backgroundColor = c1 
            }
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !initialSearchScreenPresented {
            storeManager.confirmPlaybackCapability { (success) in
                if success {
                    print("Playback possible")
                    self.searchButton.isEnabled = true
                    self.initialSearchScreenPresented = true
                    self.performSegue(withIdentifier: "toSearch", sender: nil)
                } else {
                    print("Playback not possible")
                    self.initialSearchScreenPresented = true
                }
            }
        }
    }
    
    func notificationResponder(notification: Notification) {
        //print("Responding to notification")
        switch notification.name {
        case NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange:
            //print("Now playing item changed")
            updateSongInfo()
        case NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange:
            //print("Playback state changed")
            updateSongInfo()
        case NSNotification.Name.MPMusicPlayerControllerQueueDidChange:
            //print("Queue changed")
            updateSongInfo()
        default:
            print("Unknown notification to respond to")
        }
    }
    
    func getUpcomingSongColours() {
        // fill in the colours for the next 3 songs
        for (index, songID) in upcomingSongs.enumerated() {
            SearchManager(storeManager: storeManager).getInfoForSong(id: songID, completion: { (artwork) in
                if self.songList[index].coloursAreSet() == false {
                    guard
                        let bg = artwork["bgColor"] as? String,
                        let tc = artwork["textColor1"] as? String,
                        let tc2 = artwork["textColor2"] as? String,
                        let tc3 = artwork["textColor3"] as? String,
                        let tc4 = artwork["textColor4"] as? String
                    else {
                        print("Colour error; setting black for everything")
                        self.songList[index].setColours(bg: "#000000", tc: "#FFFFFF", tc2: "#FFFFFF", tc3: "#FFFFFF", tc4: "#FFFFFF")
                        return
                    }
                    self.songList[index].setColours(bg: bg, tc: tc as! String, tc2: tc2, tc3: tc3, tc4: tc4)
                }
            })
        }
    }

    @IBAction func backToSearch(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateSongInfo() {
        if descriptor.storeIDs?.count != 0 {
            if musicPlayer.playbackState != .stopped {
                print("Now playing item: \(musicPlayer.indexOfNowPlayingItem)")
                playedSongs.append(upcomingSongs[musicPlayer.indexOfNowPlayingItem])
                setPlayerColours()
                let currentItemID = upcomingSongs[musicPlayer.indexOfNowPlayingItem]
                let currentSong = songList.filter{$0.getTrackID() == currentItemID}.first
                currentTrackName.text = currentSong?.getTrackName()
                currentArtistName.text = "\(currentSong!.getArtistName()) | \(currentSong!.getAlbumName())"
                guard let url = URL(string:(currentSong?.getLargeArtworkURL())!) else {
                    print("Artwork url not found")
                    return
                }
                do {
                    albumArtImage.image = UIImage(data: try Data(contentsOf: url))
                } catch let error {
                    print("Error: \(error)")
                }
                
            } else {
                if upcomingSongs.count != 0 {
                    let currentItemID = upcomingSongs[0]
                    let currentSong = songList.filter{$0.getTrackID() == currentItemID}.first
                    currentTrackName.text = currentSong?.getTrackName()
                    currentArtistName.text = currentSong?.getArtistName()
                    do {
                        albumArtImage.image = UIImage(data: try Data(contentsOf: URL(string: currentSong!.getLargeArtworkURL())!))
                    } catch let error {
                        print("Error: \(error)")
                    }
                }
                
            }
            
            if musicPlayer.playbackState != .stopped {
                upNextTableView.reloadData()
                if let nextItemID = upcomingSongs[musicPlayer.indexOfNowPlayingItem + 1] as? String {
                    let nextSong = songList.filter{$0.getTrackID() == nextItemID}.first
                    nextTrackName.text = nextSong?.getTrackName()
                    nextArtistName.text = nextSong?.getArtistName()
                    do {
                        nextAlbumArtImage.image = UIImage(data: try Data(contentsOf: URL(string: nextSong!.getSmallArtworkURL())!))
                    } catch let error {
                        print("Error: \(error)")
                    }
                }
            } else {
                if upcomingSongs.count != 0 {
                    let nextItemID = upcomingSongs[1]
                    let nextSong = songList.filter{$0.getTrackID() == nextItemID}.first
                    nextTrackName.text = nextSong?.getTrackName()
                    nextArtistName.text = nextSong?.getArtistName()
                    do {
                        nextAlbumArtImage.image = UIImage(data: try Data(contentsOf: URL(string: nextSong!.getSmallArtworkURL())!))
                    } catch let error {
                        print("Error: \(error)")
                    }
                }
                
            }
        }
    }
    
    func desaturatedImage(_from image: UIImage) -> UIImage? {
        let beginImage = CIImage(cgImage: image.cgImage!)
        guard let filter = CIFilter(name: "CIColorControls") else {
            print("E2")
            return nil
        }
        filter.setValue(beginImage, forKey: kCIInputImageKey)
        filter.setValue(0.5, forKey: kCIInputSaturationKey)
        guard let output = filter.outputImage else {
            print("E3")
            return nil
        }
        let context = CIContext(options: nil)
        let imageRef = context.createCGImage(output, from: beginImage.extent)
        return UIImage(cgImage: imageRef!)
    }
    
    
    @IBAction func playButton(_ sender: UIButton) {
        playPause(forcePlay: false)
    }
    
    func playPause(forcePlay: Bool) {
        let amountToShrink: CGFloat = 20
        
        if musicPlayer.playbackState == .paused || forcePlay == true {
            musicPlayer.play()
            playButton.setImage(UIImage(named: "bigPause"), for: .normal)
            albumArtLeft.constant = 16
            albumArtRight.constant = 16
            albumArtTop.constant = 12
            trackNameToArtSpacing.constant = 20
            if self.albumArtDesaturated.alpha != 0 {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 0.1, options: .curveLinear, animations: {
                    self.albumArtDesaturated.alpha = 0
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        } else if musicPlayer.playbackState == .playing {
            // If it's not paused
            musicPlayer.pause()
            playButton.setImage(UIImage(named: "bigPlay"), for: .normal)
            if let img = albumArtImage.image, let desat = desaturatedImage(_from: img) {
                albumArtDesaturated.image = desat
            }
            albumArtLeft.constant += amountToShrink / 2
            albumArtRight.constant += amountToShrink / 2
            albumArtTop.constant += amountToShrink / 2
            trackNameToArtSpacing.constant += amountToShrink / 2
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
                self.albumArtDesaturated.alpha = 1
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func nextTrack() {
        musicPlayer.skipToNextItem()
        print("Now playing: \(musicPlayer.nowPlayingItem?.assetURL)")
    }
    
    func previousTrack() {
        if musicPlayer.currentPlaybackTime < 2 && musicPlayer.indexOfNowPlayingItem > 0 {
            musicPlayer.skipToPreviousItem()
        } else {
            musicPlayer.skipToBeginning()
        }
    }
    
    @IBAction func nextButton(_ sender: UIButton) {
        musicPlayer.skipToNextItem()
        
    }
    
    @IBAction func previousButton(_ sender: UIButton) {
        previousTrack()
    }

    
    func play() {
        print("Attempting to play...")
        if musicPlayer.playbackState == .stopped {
            descriptor = MPMusicPlayerStoreQueueDescriptor.init(storeIDs: upcomingSongs)
            musicPlayer.setQueueWith(descriptor)
            musicPlayer.play()
        } else if musicPlayer.playbackState == .paused {
            musicPlayer.play()
        }
    }
    
    func upNextViewDidReorderSongs() {
        print("Reorder songs")
    }
    
    func upNextViewDidSelectSong(_at index: Int) {
        print("selected song at \(index)")

        let secondHalf = upcomingSongs[index...]
        upcomingSongs.insert(contentsOf: secondHalf, at: 0)
        //upcomingSongs.removeSubrange(ClosedRange.init(uncheckedBounds: (lower: index + 1, upper: upcomingSongs.count - 1)))
        let songListSecondHalf = songList[index...]
        songList.insert(contentsOf: songListSecondHalf, at: 0)
        //songList.removeSubrange(ClosedRange.init(uncheckedBounds: (lower: index + 1, upper: upcomingSongs.count - 1)))
        
        // generate a new descriptor, with that song at the start - but remove songs that are in 'played songs'
        musicPlayer.stop()
        descriptor = MPMusicPlayerStoreQueueDescriptor.init(storeIDs: [])
        musicPlayer.setQueueWith(descriptor)
        print("upcomingSongs has \(upcomingSongs.count) entries")
        print(upcomingSongs)
        descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: upcomingSongs)
        musicPlayer.setQueueWith(descriptor)
        print("Descriptor has \(descriptor.storeIDs!.count) songs")
        setPlayerColours()
        playPause(forcePlay: true)
        // set the queue using descriptor and play
    }
    
    func upNextViewDidRemoveSong() {
        print("Did remove song")
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "toSearch":
            guard let IVC: ViewController = segue.destination as? ViewController else {
                print("Error segueing")
                return
            }
            IVC.playerScreen = self
            IVC.storeManager = self.storeManager
        case "showUpNext":
            guard let IVC: UpNextViewController = segue.destination as? UpNextViewController else {
                print("Error segueing")
                return
            }
            // IVC should have a delegate, which will be this class
            // This class will implement the delegate protocol to handle songs being dragged around in the up next view 
            IVC.songs = songList
            IVC.currentSongIndex = musicPlayer.indexOfNowPlayingItem
            IVC.delegate = self
        default:
            print("Error segueing - default hit")
            return 
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
