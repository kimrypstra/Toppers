//
//  PlayerViewController.swift
//  Topper
//
//  Created by Kim Rypstra on 31/8/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit
import MediaPlayer

class PlayerViewController: UIViewController, UpNextDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, NowPlayingDelegate, UIScrollViewDelegate {

    // MARK: Playlist Variables
    var songList: [Song] = []
    var upcomingSongs: [String] = []
    var playedSongs: [String] = []
    var descriptor: MPMusicPlayerStoreQueueDescriptor!
    //var descriptor = MPMusicPlayerStoreQueueDescriptor()
    
    // MARK: Music Search and Player Variables
    var musicPlayer = MPMusicPlayerController.systemMusicPlayer()
    var userStoreID: String = ""
    var storeManager = StoreManager()
    
    // MARK: Controls and UI
    var commandCenter: MPRemoteCommandCenter!
    var didSkipToPreviousItem = false
    var smallUpNextHeight: CGFloat!
    var initialSearchScreenPresented = false
    var upNextExpanded = false
    let monochromeMode = false
    
    // MARK: IBOutlets
    @IBOutlet weak var mainUpNextLabel: UILabel!
    @IBOutlet weak var mainSearchButton: UIButton!
    @IBOutlet weak var mainNowPlayingLabel: UILabel!
    @IBOutlet var mainBackgroundView: UIView!
    @IBOutlet weak var mainBackgroundMask: UIImageView!
    @IBOutlet weak var nowPlayingStackView: UIStackView!
    @IBOutlet weak var upNextShadowView: UIView!
    @IBOutlet weak var scrollViewContentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var backgroundTapRecog: UITapGestureRecognizer!
    @IBOutlet var upNextTapRecog: UITapGestureRecognizer!
    @IBOutlet weak var upNextShadowViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var upNextToShadowViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var upNextTableView: UITableView!
    @IBOutlet weak var nextSongContainerView: UIView!
    @IBOutlet weak var nextSongContainerViewMask: UIView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var nextTrackName: UILabel!
    @IBOutlet weak var nextArtistName: UILabel!
    @IBOutlet weak var nextAlbumArtImage: UIImageView!


    
    // MARK:- View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        musicPlayer.stop()
        musicPlayer.beginGeneratingPlaybackNotifications()
        // prepare the list
        scrollView.delegate = self
        
        upNextTableView.register(UINib(nibName: "UpNextTableViewCell", bundle: nil), forCellReuseIdentifier: "upNextTableViewCell")

        upNextShadowView.layer.cornerRadius = 8
        upNextShadowView.layer.shadowColor = UIColor.black.cgColor
        upNextShadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
        upNextShadowView.layer.shadowRadius = 10
        upNextShadowView.layer.shadowOpacity = 0.4
        upNextShadowView.layer.cornerRadius = 8
        upNextShadowView.clipsToBounds = false
        
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
        
        // TODO: Put the volume view back into the UI
        let volumeView = MPVolumeView()
        volumeView.showsRouteButton = true
        volumeView.setRouteButtonImage(UIImage(named: "route"), for: .normal)
        volumeView.tintColor = UIColor.black
        volumeView.showsVolumeSlider = false
        
        if songList.count != 0 {
            songList.removeAll()
        }
        
        searchButton.isEnabled = false

        nextAlbumArtImage.clipsToBounds = true 
        nextAlbumArtImage.layer.cornerRadius = 4
        nextSongContainerView.layer.shadowColor = UIColor.black.cgColor
        nextSongContainerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        nextSongContainerView.layer.shadowRadius = 10
        nextSongContainerView.layer.shadowOpacity = 0.4
        
        self.backgroundTapRecog.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.contentOffset.x = scrollView.contentSize.width / 2 - scrollView.frame.width / 2
        scrollView.clipsToBounds = false
        nowPlayingStackView.clipsToBounds = false 
        print(scrollView.contentSize)
        for card in nowPlayingStackView.arrangedSubviews {
            if let card = card as? NowPlayingCard {
                card.delegate = self
                card.roundCorners()
            }
        }
        
        if smallUpNextHeight == nil {
            smallUpNextHeight = CGFloat(upNextTableView.frame.height)
        }
        print(smallUpNextHeight)
        
        let darkMode = false
        
        if darkMode == true {
            self.mainBackgroundView.backgroundColor = .black
            self.searchButton.tintColor = .white
            self.mainNowPlayingLabel.textColor = .white
            self.mainUpNextLabel.textColor = .white
            self.mainBackgroundMask.alpha = 0
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK:- IBActions
    @IBAction func playButton(_ sender: UIButton) {
        playPause(forcePlay: false)
    }

    @IBAction func nextButton(_ sender: UIButton) {
        musicPlayer.skipToNextItem()
    }
    
    @IBAction func previousButton(_ sender: UIButton) {
        previousTrack()
    }
    
    @IBAction func backToSearch(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapUpNext(_ sender: UITapGestureRecognizer) {
        print("tapped up next")
        toggleUpNextView()
    }
    
    @IBAction func didTapBackground(_ sender: UITapGestureRecognizer) {
        toggleUpNextView()
        print("tapped background")
    }
    
    // MARK:- TableView, ScrollView, and Gesture Delegate Methods
    // TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if upNextExpanded {
            return songList.count - 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if songList.count > 0 {
            let cell = upNextTableView.dequeueReusableCell(withIdentifier: "upNextTableViewCell", for: indexPath) as! UpNextTableViewCell
            let song = songList[musicPlayer.indexOfNowPlayingItem + 1 + indexPath.row]
            cell.artistName.text = song.getArtistName()
            cell.songTitle.text = song.getTrackName()
            cell.albumArt.image = song.getImage()
            cell.albumName.text = song.getAlbumName()
            return cell
        } else {
            let cell = upNextTableView.dequeueReusableCell(withIdentifier: "upNextTableViewCell", for: indexPath)
            cell.textLabel?.text = "test"
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return smallUpNextHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        upNextViewDidSelectSong(_at: indexPath.row)
    }
    
    // ScrollView
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // trigger the nowPlaying screen to update the cards
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        if page == 0 {
            // previous
            previousTrack()
        } else if page == 2 {
            // next
            nextTrack()
        }
        print("Scroll view finished scrolling")
        for card in nowPlayingStackView.arrangedSubviews {
            if let card = card as? NowPlayingCard {
                card.resetCard(fast: true)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("ScrollView didScroll: \(scrollView.contentOffset.x)")
        guard let current = nowPlayingStackView.arrangedSubviews[1] as? NowPlayingCard else {print("No Current");return}
        guard let next = nowPlayingStackView.arrangedSubviews[2] as? NowPlayingCard else {print("No Next");return}
        guard scrollView.contentSize.width > 0 else {print("scrollView zero");return}
        let offsetPercentage = scrollView.contentOffset.x / scrollView.contentSize.width
        current.cardScrollViewOffsetPercent = offsetPercentage
        next.cardScrollViewOffsetPercent = offsetPercentage
        
    }
    
    // GestureRecog
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK:- Playback Controls
    
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
    
    func didTriggerPreviousTrack() {
        print("Player received prev track trigger")
        let offset = CGPoint(x: 0, y: 0)
        guard let previousCard = nowPlayingStackView.arrangedSubviews[0] as? NowPlayingCard else {return}
        previousCard.scrollType = .Previous
        previousCard.trackInfoStackViewCenterConstraint.constant = -20
        
        guard let card = nowPlayingStackView.arrangedSubviews[1] as? NowPlayingCard else {return}
        // Check if it is GOING to skip to previous or just to the start
        if musicPlayer.currentPlaybackTime < 2 && musicPlayer.indexOfNowPlayingItem > 0 {
            // it will skip to previous item
            //previousTrack()
            DispatchQueue.main.async {
                self.scrollView.setContentOffset(offset, animated: true)
                //card.resetCard(fast: true)
            }
        } else {
            // it will skip to the start
            // do not animate the scrollView offset, just trigger prevTrack from here
            
            card.resetCard(fast: false)
            previousTrack()
        }
    }
    
    func didTriggerNextTrack() {
        print("Player received next track trigger")
        let offset = CGPoint(x: scrollView.contentSize.width - scrollView.frame.width, y: 0)
        guard let nextCard = nowPlayingStackView.arrangedSubviews[2] as? NowPlayingCard else {return}
        nextCard.scrollType = .Previous
        nextCard.trackInfoStackViewCenterConstraint.constant = -20
        DispatchQueue.main.async {
            self.scrollView.setContentOffset(offset, animated: true)
        }
    }
    
    func didTriggerPausePlay() {
        print("Player received pause/play trigger")
        
        if upNextExpanded {
            didTapUpNext(upNextTapRecog)
            
        } else {
            playPause(forcePlay: false)
            guard let card = nowPlayingStackView.arrangedSubviews[1] as? NowPlayingCard else {return}
            card.toggleShrink()
            
        }
        
    }
    
    func playPause(forcePlay: Bool) {
        let amountToShrink: CGFloat = 20
        
        if musicPlayer.playbackState == .paused || forcePlay == true {
            musicPlayer.play()
        } else if musicPlayer.playbackState == .playing {
            // If it's not paused
            musicPlayer.pause()
        }
    }
    
//    func play() {
//        print("Attempting to play...")
//        if musicPlayer.playbackState == .stopped {
//            descriptor = MPMusicPlayerStoreQueueDescriptor.init(storeIDs: upcomingSongs)
//            musicPlayer.setQueueWith(descriptor)
//            musicPlayer.play()
//        } else if musicPlayer.playbackState == .paused {
//            musicPlayer.play()
//        }
//    }
    
    func nextTrack() {
        musicPlayer.skipToNextItem()
        print("Now playing: \(musicPlayer.nowPlayingItem?.assetURL)")
    }
    
    func previousTrack() {
        if musicPlayer.currentPlaybackTime < 2 && musicPlayer.indexOfNowPlayingItem > 0 {
            musicPlayer.skipToPreviousItem()
            didSkipToPreviousItem = true
        } else {
            musicPlayer.skipToBeginning()
            didSkipToPreviousItem = false
        }
    }
    
    // MARK:- Playlist Manipulation/Song Info
    
    func setUpSongList(list: [Song]) {
        musicPlayer.stop()
        self.upcomingSongs.removeAll()
        
        self.songList = list
        for song in songList {
            upcomingSongs.append(song.getTrackID())
        }

        self.getAllAlbumImages()
        self.getAllSongColours()
        setPlayerColours()
        updateSongInfoForSong(song: list.first!)
        descriptor = MPMusicPlayerStoreQueueDescriptor.init(storeIDs: [])
        musicPlayer.setQueueWith(descriptor)
        print("upcomingSongs has \(upcomingSongs.count) entries")
        print(upcomingSongs)
        descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: upcomingSongs)
        musicPlayer.setQueueWith(descriptor)
        print("Descriptor has \(descriptor.storeIDs!.count) songs")

        playPause(forcePlay: true)
    }
    
    func updateSongInfoForSong(song: Song) {
        guard let card = nowPlayingStackView.arrangedSubviews[1] as? NowPlayingCard else {print("Error with prev playing card"); return}
            card.trackNameLabel.text = song.getTrackName()
            card.artistNameLabel.text = song.getArtistName()
            card.albumNameLabel.text = song.getAlbumName()
            card.albumArtImageView.image = song.getImage()
    }

    func getAllAlbumImages() {
        for (index, song) in songList.enumerated() {
            if song.checkImage() == false {
                if index == 0 || index == 1 {
                    DispatchQueue.main.async {
                        let sameArtwork = self.songList.filter{$0.getLargeArtworkURL() == song.getLargeArtworkURL()}.filter{$0.checkImage() == true}.first
                        if sameArtwork == nil {
                            do {
                                song.setImage(image: UIImage(data: try Data(contentsOf: URL(string: song.getLargeArtworkURL())!))!)
                            } catch let error {
                                print("Error settings image: \(error.localizedDescription)")
                            }
                            
                        } else {
                            print("Found a song with the same artwork!")
                            song.setImage(image: sameArtwork!.getImage()!)
                        }
                    }
                } else {
                    DispatchQueue.global(qos: .background).async {
                        let sameArtwork = self.songList.filter{$0.getLargeArtworkURL() == song.getLargeArtworkURL()}.filter{$0.checkImage() == true}.first
                        if sameArtwork == nil {
                            do {
                                song.setImage(image: UIImage(data: try Data(contentsOf: URL(string: song.getLargeArtworkURL())!))!)
                            } catch let error {
                                print("Error settings image: \(error.localizedDescription)")
                            }
                            
                        } else {
                            print("Found a song with the same artwork!")
                            song.setImage(image: sameArtwork!.getImage()!)
                        }
                    }
                }
            }
        }
    }
    
    func getAllSongColours() {
        // fill in the colours for the next 3 songs
        for (index, song) in songList.enumerated() {
            if song.coloursAreSet() == false {
                SearchManager(storeManager: storeManager).getInfoForSong(id: song.getTrackID(), completion: { (artwork) in
                    if index == 1 || index == 0 {
                        DispatchQueue.main.async {
                            if self.songList[index].coloursAreSet() == false {
                                guard
                                    let bg = artwork["bgColor"] as? String,
                                    let tc = artwork["textColor1"] as? String,
                                    let tc2 = artwork["textColor2"] as? String,
                                    let tc3 = artwork["textColor3"] as? String,
                                    let tc4 = artwork["textColor4"] as? String
                                    else {
                                        print("Colour error; setting white for everything")
                                        self.songList[index].setColours(bg: "#000000", tc: "#fce6c0", tc2: "#fce6c0", tc3: "#fce6c0", tc4: "#fce6c0")
                                        return
                                }
                                self.songList[index].setColours(bg: bg, tc: tc, tc2: tc2, tc3: tc3, tc4: tc4)
                            }
                        }
                    } else {
                        DispatchQueue.global(qos: .background).async {
                            if self.songList[index].coloursAreSet() == false {
                                guard
                                    let bg = artwork["bgColor"] as? String,
                                    let tc = artwork["textColor1"] as? String,
                                    let tc2 = artwork["textColor2"] as? String,
                                    let tc3 = artwork["textColor3"] as? String,
                                    let tc4 = artwork["textColor4"] as? String
                                    else {
                                        print("Colour error; setting black and white for everything")
                                        self.songList[index].setColours(bg: "#000000", tc: "#fce6c0", tc2: "#fce6c0", tc3: "#fce6c0", tc4: "#fce6c0")
                                        return
                                }
                                self.songList[index].setColours(bg: bg, tc: tc, tc2: tc2, tc3: tc3, tc4: tc4)
                            }
                        }
                    }
                })
            }
        }
    }


    
    func updateSongInfo() {
        
        guard descriptor != nil else {return}
        if descriptor.storeIDs?.count != 0 {
            if musicPlayer.playbackState != .stopped {
                print("Now playing item: \(musicPlayer.indexOfNowPlayingItem)")
                playedSongs.append(upcomingSongs[musicPlayer.indexOfNowPlayingItem])
                setPlayerColours()
                
                guard let currentCard = nowPlayingStackView.arrangedSubviews[1] as? NowPlayingCard else {print("Error with now playing card"); return}
                let currentItemID = upcomingSongs[musicPlayer.indexOfNowPlayingItem]
                let currentSong = songList.filter{$0.getTrackID() == currentItemID}.first
                currentCard.trackNameLabel.text = currentSong?.getTrackName()
                currentCard.artistNameLabel.text = currentSong?.getArtistName()
                currentCard.albumNameLabel.text = currentSong?.getAlbumName()
                currentCard.albumArtImageView.image = currentSong?.getImage()

                guard let nextCard = nowPlayingStackView.arrangedSubviews[2] as? NowPlayingCard else {print("Error with next playing card"); return}
                if musicPlayer.indexOfNowPlayingItem < upcomingSongs.count - 1 {
                    let nextItemID = upcomingSongs[musicPlayer.indexOfNowPlayingItem + 1]
                    let nextSong = songList.filter{$0.getTrackID() == nextItemID}.first
                    nextCard.trackNameLabel.text = nextSong?.getTrackName()
                    nextCard.artistNameLabel.text = nextSong?.getArtistName()
                    nextCard.albumNameLabel.text = nextSong?.getAlbumName()
                    nextCard.albumArtImageView.image = nextSong?.getImage()
                }

                guard let prevCard = nowPlayingStackView.arrangedSubviews[0] as? NowPlayingCard else {print("Error with prev playing card"); return}
                if musicPlayer.indexOfNowPlayingItem > 0 {
                    let prevItemID = upcomingSongs[musicPlayer.indexOfNowPlayingItem - 1]
                    let prevSong = songList.filter{$0.getTrackID() == prevItemID}.first
                    prevCard.trackNameLabel.text = prevSong?.getTrackName()
                    prevCard.artistNameLabel.text = prevSong?.getArtistName()
                    prevCard.albumNameLabel.text = prevSong?.getAlbumName()
                    prevCard.albumArtImageView.image = prevSong?.getImage()
                }
                
                scrollView.contentOffset.x = scrollView.contentSize.width / 2 - scrollView.frame.width / 2
                
            } else {
                if upcomingSongs.count != 0 {
                    let currentItemID = upcomingSongs[0]
                    let currentSong = songList.filter{$0.getTrackID() == currentItemID}.first
                }
                
            }
            
            // SET UP THE UP NEXT VIEW
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
    
    func upNextViewDidReorderSongs() {
        print("Reorder songs")
    }
    
    func upNextViewDidSelectSong(_at index: Int) {
        print("selected song at \(index)")
        let indexPlusOne = index + 1
        let secondHalf = upcomingSongs[indexPlusOne...]
        upcomingSongs.insert(contentsOf: secondHalf, at: 0)
        //upcomingSongs.removeSubrange(ClosedRange.init(uncheckedBounds: (lower: index + 1, upper: upcomingSongs.count - 1)))
        let songListSecondHalf = songList[indexPlusOne...]
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
        didTriggerPausePlay()
        playPause(forcePlay: true)
        // set the queue using descriptor and play
    }
    
    func upNextViewDidRemoveSong() {
        print("Did remove song")
    }
    
    // MARK:- UI
    

    
    func toggleUpNextView() {
        // Disable play/pause and pan recogs in now playing card
        // Maybe blur?
        
        if upNextExpanded {
            upNextShadowViewHeightConstraint.constant = 75
            upNextToShadowViewConstraint.constant = 6.5
            upNextExpanded = false
        } else {
            upNextExpanded = true
            upNextTableView.reloadData()
            upNextToShadowViewConstraint.constant -= 300
            upNextShadowViewHeightConstraint.constant += 300
        }
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            if self.upNextExpanded {
                self.upNextTableView.isUserInteractionEnabled = true
                self.upNextTapRecog.isEnabled = false
                self.upNextTableView.isUserInteractionEnabled = true
                self.upNextTableView.isScrollEnabled = true
            } else {
                self.upNextTableView.reloadData()
                self.upNextTableView.isUserInteractionEnabled = false
                self.upNextTapRecog.isEnabled = true
                self.upNextTableView.isUserInteractionEnabled = false
                self.upNextTableView.isScrollEnabled = false
            }
        }
    }
    
    func setPlayerColours() {
        let musicPlayerIndex = musicPlayer.indexOfNowPlayingItem
        
        // Make sure music player index is not int.max
        if musicPlayerIndex <= songList.count - 1 {
            // Do the current card
            let currentSong = self.songList[musicPlayerIndex]
            if let colors = currentSong.getColours() {
                guard let card = nowPlayingStackView.arrangedSubviews[1] as? NowPlayingCard else {
                    print("Error getting now playing card")
                    return
                }
                guard let upNextCell = upNextTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? UpNextTableViewCell else {
                    print("Error casting cell as UpNextTableViewCell")
                    return
                }
                print("BG: \(colors["bg"])")
                print("TC: \(colors["tc"])")
                var bgColor = UIColor(hexString: colors["bg"]!)
                var tColor = UIColor(hexString: colors["tc"]!)
                
                if monochromeMode {
                    mainBackgroundMask.alpha = 0
                    bgColor = .black
                    tColor = .white
                }

                card.setBackgroundColour(color: bgColor)
                card.setTextColour(color: tColor)
                    
                // Animate, because this card is visible
                UIView.animate(withDuration: 0.5) {
                    upNextCell.setTextColor(color: tColor)
                    self.mainBackgroundView.backgroundColor = bgColor
                    self.mainUpNextLabel.textColor = tColor
                    self.mainNowPlayingLabel.textColor = tColor
                    self.mainSearchButton.titleLabel?.textColor = tColor
                    self.mainSearchButton.tintColor = tColor
                    self.upNextShadowView.backgroundColor = bgColor
                    self.upNextShadowView.alpha = 1
                }
                


                // Do the next card
                if musicPlayerIndex + 1 <= songList.count - 1 {
                    let nextSong = songList[musicPlayerIndex + 1]
                    // TODO:- Set default colours if colours aren't found
                    guard let nextBGString = nextSong.getColours()?["bg"]!, let nextTCString = nextSong.getColours()?["tc"]!, let nextCard = nowPlayingStackView.arrangedSubviews[2] as? NowPlayingCard else {
                        print("Error setting next song colors")
                        return
                    }

                    var nextBGColor = UIColor(hexString: nextBGString)
                    var nextTCColor = UIColor(hexString: nextTCString)
                    
                    if monochromeMode {
                        nextBGColor = .black
                        nextTCColor = .white
                    }
                    nextCard.setBackgroundColour(color: nextBGColor)
                    nextCard.setTextColour(color: nextTCColor)
                }
                
                // Do the previous card
                if musicPlayerIndex - 1 >= 0 {
                    let prevSong = songList[musicPlayerIndex - 1]
                    guard let prevBGString = prevSong.getColours()?["bg"], let prevTCString = prevSong.getColours()?["tc"], let prevCard = nowPlayingStackView.arrangedSubviews[0] as? NowPlayingCard else {
                        print("Error setting next song colors")
                        return
                    }
                    var prevBGColor = UIColor(hexString: prevBGString)
                    var prevTCColor = UIColor(hexString: prevTCString)
                    if monochromeMode {
                        prevBGColor = .black
                        prevTCColor = .white
                    }
                    prevCard.setBackgroundColour(color: prevBGColor)
                    prevCard.setTextColour(color: prevTCColor)
                }
            } else {
                print("Error getting colours out of track")
            }

        }
    }
    
    // MARK:- Navigation

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
}
