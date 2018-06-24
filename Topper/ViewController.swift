//
//  ViewController.swift
//  Topper
//
//  Created by Kim Rypstra on 15/8/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit
import StoreKit

class ViewController: UIViewController, URLSessionDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UITextFieldDelegate, UIScrollViewDelegate {

    enum SearchMode {
        case Toppers
        case Artists
        case Genres
        case Songs
        case Albums
    }
    
    enum tableViewMode {
        case Recent
        case PreliminaryResults
        case Albums
        case Genres
    }
    // TODO: get rid of this, it should just be in the search manager
    fileprivate let key = "Bearer eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlJKNlNXVTZMVDQifQ.eyJpc3MiOiJZQkNDVFdIMldXIiwiaWF0IjoxNTI5MjM4NjI0LCJleHAiOjE1MzY0OTYyMjR9.HZZ-Yy1ABHkxxZ6TQnTjOV_EiQnNTUss3-t8j8gvMmjthrw6Zk0fHgGCYvMRFSAZ4LGM9_NOrF_1pfXruEQ33Q"
    
    var shouldAnimateBackground = false
    var searchManager: SearchManager!
    var storeManager: StoreManager!
    var playerScreen: PlayerViewController!
    var suggestionTimer: Timer?
    var recentSearchTerms: [(name: String, id: String, epoch: Double)] = []
    var albums: [Album] = []
    var preliminarySearchTerms: [String] = []
    var preliminaryArtistIDs: [String: String] = [:]
    var filteredSongList: [Song] = []
    var genres: [String: String] = [:]
    var recentTableViewMode: tableViewMode = .Recent
    var searchMode: SearchMode = .Toppers
    @IBOutlet weak var recentLabel: UILabel!
    @IBOutlet weak var queryField: TopperTextField!
    @IBOutlet weak var recentTableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var searchStackView: UIStackView!
    @IBOutlet weak var searchScrollView: UIScrollView!
    @IBOutlet weak var recentTableViewToBottom: NSLayoutConstraint!
    
// =================================================================================================================================================== //
    // Change to player view first, with search presented modally *
    // Change artwork, make BG colour change
    // Add search mode selector to search
    // Add autocomplete/suggestions to search
    // Only add to previous searches if successful
    // Handle repeats in screenshots
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load defaults
        loadPreviousSearches()
        
        queryField.layer.borderColor = UIColor.clear.cgColor
        queryField.layer.cornerRadius = 8
        
        recentTableView.contentInset = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
        queryField.delegate = self
        
        spinner.hidesWhenStopped = true
        
        searchScrollView.delegate = self
        
        searchManager = SearchManager(storeManager: storeManager)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleKeyboardUp(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleKeyboardDown(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func handleKeyboardUp(notification: Notification) {
        print("Keyboard up")
        print(notification.userInfo)
        guard let keyboardBounds = notification.userInfo!["UIKeyboardFrameEndUserInfoKey"]! as? CGRect else {
            print("Error getting keyboard bounds")
            return
        }
        recentTableViewToBottom.constant += keyboardBounds.height
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func handleKeyboardDown(notification: Notification) {
        print("Keyboard down")
        recentTableViewToBottom.constant = 20
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let defaults = UserDefaults()
        if defaults.value(forKey: "searchViewDemoComplete") as? Bool != true {
            defaults.set(true, forKey: "searchViewDemoComplete")
            UIView.animate(withDuration: 0.5, animations: {
                self.searchScrollView.contentOffset = CGPoint(x: 0, y: 50)
            }) { (_) in
                UIView.animate(withDuration: 0.5, animations: {
                    self.searchScrollView.contentOffset = CGPoint.zero
                })
            }
        }
        queryField.becomeFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func loadPreviousSearches() {
        let defaults = UserDefaults()
        if let recents = defaults.value(forKey: "previousSearches") as? [[String: String]] {
            var mapped: [(name: String, id: String, epoch: Double)] = []
            for item in recents {
                mapped.append((name: item["name"]!, id: item["id"]!, epoch: Double(item["date"]!)!))
            }
            recentSearchTerms = mapped
            recentSearchTerms.sort{$0.epoch > $1.epoch}
        }
        
        if let genres = defaults.value(forKey: "genres") as? [String: String] {
            self.genres = genres
        }
        
    }
    
    @IBAction func didTapOnSearchArea(_ sender: UITapGestureRecognizer) {
        print("TAP!")
        self.queryField.becomeFirstResponder()
    }
    
    func backgroundTap() {
        queryField.resignFirstResponder()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == searchScrollView {
            let scrollViewIndex = Int(searchScrollView.contentOffset.y / 50)
            switch scrollViewIndex {
            case 0:
                searchMode = .Toppers
                UIView.animate(withDuration: 0.2, animations: {
                    self.recentLabel.alpha = 0
                    self.recentTableView.alpha = 0
                }, completion: { (_) in
                    self.recentLabel.text = "Recent"
                    self.recentTableViewMode = .Recent
                    self.recentTableView.reloadData()
                    UIView.animate(withDuration: 0.2, animations: {
                        self.recentLabel.alpha = 1
                        self.recentTableView.alpha = 1
                    })
                })
                
            case 1:
                searchMode = .Albums
                UIView.animate(withDuration: 0.2, animations: {
                    self.recentLabel.alpha = 0
                    self.recentTableView.alpha = 0
                }, completion: { (_) in
                    self.recentLabel.text = "Recent"
                    self.recentTableViewMode = .Recent
                    self.recentTableView.reloadData()
                    UIView.animate(withDuration: 0.2, animations: {
                        self.recentLabel.alpha = 1
                        self.recentTableView.alpha = 1
                    })
                })
                
            case 2:
                searchMode = .Genres
                UIView.animate(withDuration: 0.2, animations: {
                    self.recentLabel.alpha = 0
                    self.recentTableView.alpha = 0
                }, completion: { (_) in
                    self.recentLabel.text = "Genres"
                    self.recentTableViewMode = .Genres
                    self.recentTableView.reloadData()
                    UIView.animate(withDuration: 0.2, animations: {
                        self.recentLabel.alpha = 1
                        self.recentTableView.alpha = 1
                    })
                })
                
            default:
                searchMode = .Toppers
            }
            print("Search Mode set to \(searchMode)")
        }
        
    }
    
    @IBAction func searchButton(_ sender: UIButton) {
        // Get the search mode from the scrollView position
        let scrollViewIndex = Int(searchScrollView.contentOffset.y / 50)
        print("Search set to page: \(scrollViewIndex)")
        let queryText = queryField.text
        
        switch searchMode {
            case .Toppers:
                findArtistID(name: queryField.text!) { (artistID) in
                    print("ID: \(artistID)")
                }
            case .Albums:
                recentLabel.text = "Albums"
                recentTableViewMode = .Albums
                searchManager.searchForAlbum(query: queryField.text!, completion: { (albums) in
                    print("Rec'd \(albums.count) albums")
                    for album in albums {
                        if album.name().lowercased() == self.queryField.text?.lowercased() {
                            // we have an exact match
                            self.searchManager.getTracksForAlbum(id: album.id(), completion: { (songs) in
                                self.filteredSongList = songs
                                self.goBackToPlayerScreen()
                            })
                            break
                        }
                    }
                    self.albums = albums
                    self.recentTableView.reloadData()
                })
            case .Genres:
                recentLabel.text = "Genres"
                recentTableViewMode = .Genres
                recentTableView.reloadData()
            default:
                return
        }
        
        
        // start the search
        
        shouldAnimateBackground = true
        queryField.resignFirstResponder()

        // segue to results
    }
    
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch recentTableViewMode {
        case .Recent:
            return recentSearchTerms.count
        case .PreliminaryResults:
            switch searchMode {
            case .Toppers:
                return preliminarySearchTerms.count
            case .Albums:
                return preliminarySearchTerms.count 
            default:
                print("Default search mode")
                return 0
            }
        case .Albums:
            return albums.count
        case .Genres:
            return genres.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recentCell", for: indexPath)
        switch recentTableViewMode {
            
        case .Recent:
            if recentSearchTerms.count > 0 {
                cell.textLabel?.text = recentSearchTerms[indexPath.row].name
            }
            
        case .PreliminaryResults:
            if preliminarySearchTerms.count > 0 {
                cell.textLabel?.text = preliminarySearchTerms[indexPath.row]
            }
            
        case .Albums:
            if albums.count > 0 {
                cell.textLabel?.text = "\(albums[indexPath.row].name()) - \(albums[indexPath.row].artistsName())"
            }
            
        case .Genres:
            if genres.count > 0 {
                cell.textLabel?.text = "\(Array(genres.keys)[indexPath.row])"
            }
        }
        
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        spinner.startAnimating()
        tableView.deselectRow(at: indexPath, animated: true)
        // Initiate a search from that query string
        // If tableView mode is prelim search results, add that search term to the previous searches if it's not already theere
        
        switch recentTableViewMode {
        case .PreliminaryResults:
            switch searchMode {
            case .Toppers:
                findArtistID(name: preliminarySearchTerms[indexPath.row], completion: { (artistID) in
                    getTopSongsForArtist(artistID: artistID, offset: nil)
                    addArtistToPreviousSearches(artistName: preliminarySearchTerms[indexPath.row], artistID: artistID)
                })
            case .Albums:
                queryField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                searchButton(UIButton())
            default:
                return
            }
        case .Recent:
            getTopSongsForArtist(artistID: recentSearchTerms[indexPath.row].id, offset: nil)
            addArtistToPreviousSearches(artistName: recentSearchTerms[indexPath.row].name, artistID: recentSearchTerms[indexPath.row].id)
        case .Albums:
            searchManager.getTracksForAlbum(id: albums[indexPath.row].id(), completion: { (songs) in
                self.filteredSongList = songs
                self.goBackToPlayerScreen()
            })
        case .Genres:
            searchManager.getChartForGenre(genre: genres[recentTableView.cellForRow(at: indexPath)!.textLabel!.text!]!, completion: { (songs) in
                if songs != nil {
                    self.filteredSongList = songs!
                }
                
                self.goBackToPlayerScreen()
            })
        }
        
        
        
        // If mode is recents, skip the artistID search and just search based on the id in previous searches
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.characters.count != 0 {
            for label in searchStackView.arrangedSubviews {
                label.isHidden = true
            }
        } else {
            print("Backspace...")
            if textField.text!.characters.count - 1 <= 0 {
                print("Here...")
                for label in searchStackView.arrangedSubviews {
                    label.isHidden = false
                }
            }

        }
        
        suggestionTimer?.invalidate()
        suggestionTimer = nil
        suggestionTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.searchSuggestions), userInfo: nil, repeats: false)
        

        
        return true 
    }
    
    func searchSuggestions() {
        print("Search...")
        
        if recentTableViewMode != .PreliminaryResults {
            UIView.animate(withDuration: 0.5, animations: {
                self.recentLabel.alpha = 0
                self.recentTableView.alpha = 0
            }, completion: { (success) in
                self.recentLabel.text = "Suggestions"
                self.recentTableViewMode = .PreliminaryResults
                self.recentTableView.reloadData()
                UIView.animate(withDuration: 0.5, animations: {
                    self.recentLabel.alpha = 1
                    self.recentTableView.alpha = 1
                })
            })
        }

        guard queryField.text?.count != 0 else {return}
        
        let searchTerm = NSString(string: (queryField.text?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))!).replacingOccurrences(of: "%20", with: "+")
        let baseURL = "https://api.music.apple.com/v1/catalog/us/search/hints?term=\(searchTerm)&limit=10&types=artists"
        
        guard let url = URL(string: baseURL) else {
            print("URL Formatting Error: \(baseURL)")
            return
        }
        
        // Set up the request
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        var dataTask = URLSessionDataTask()
        var request = URLRequest(url: url)
        
        request.addValue(key, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        
        // Debug
        print(baseURL)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        // Send the request
        dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                print("An error may have occurred")
            } else {
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
                    print("Error - server returned \(httpResponse.statusCode). Error: \(data!)")
                    let dataString = String.init(data: data!, encoding: String.Encoding.utf8)
                    print("Error reorted: \(dataString)")
                    self.preliminarySearchTerms.removeAll()
                    self.recentTableView.reloadData()
                } else {
                    print("Received: \(data!)")
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: AnyObject] else {
                            print("Error deserializing json string")
                            return
                        }
                        
                        guard let results = json["results"] as? [String: AnyObject] else {print(json); return}
                        
                        guard let terms = results["terms"] as? [String] else {print(results); return}
                        self.preliminarySearchTerms = terms
                        print(self.preliminarySearchTerms)
                        self.recentTableViewMode = .PreliminaryResults
                        self.recentTableView.reloadData()
                        
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        dataTask.resume()
    }
    
    func addArtistToPreviousSearches(artistName: String, artistID: String) {
        let defaults = UserDefaults()
        if var prevSearches = defaults.value(forKey: "previousSearches") as? [[String: String]] {
            //let currentSong = songList.filter{$0.getTrackID() == currentItemID}.first
            if prevSearches.filter({$0["id"]?.lowercased() == artistID.lowercased()}).count == 0 {
                // If the artist ID is not in prevSearches
                // Create and add it
                prevSearches.append(["name" : artistName, "id" : artistID, "date" : String(Date().timeIntervalSince1970)])
                // If the list is more than 25, delete the last item
                if prevSearches.count > 25 {
                    prevSearches.removeFirst()
                }
                // Save it
                defaults.set(prevSearches, forKey: "previousSearches")
                
            } else {
                // If the artist IS in prevSearches
                // Remove it
                prevSearches.remove(at: prevSearches.index(where: {$0["id"] == artistID})!)
                // Create a new one
                prevSearches.append(["name" : artistName, "id" : artistID, "date" : String(Date().timeIntervalSince1970)])
                // If the list is more than 25, delete the last item
                if prevSearches.count > 25 {
                    prevSearches.remove(at: prevSearches.count - 1)
                }
                // Save it
                defaults.set(prevSearches, forKey: "previousSearches")
            }
            
        } else {
            // Nothing has been saved before (in this format)
            // Create a new record
            let prevSearchArray: [[String: String]] = [["name" : artistName, "id" : artistID, "date" : String(Date().timeIntervalSince1970)]]
            UserDefaults().set(prevSearchArray, forKey: "previousSearches")
        }
        loadPreviousSearches()
        recentTableView.reloadData()
    }
    
    func findArtistID(name: String, completion: (String) ->()) {
        spinner.startAnimating()
        let nameSpacesRemoved = name.replacingOccurrences(of: " ", with: "+")
        let encodedName = nameSpacesRemoved.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        guard let id = storeManager.storefrontID() as? String else {print("No storefont ID yet"); return}
        let baseURL = "https://itunes.apple.com/search?term=\(encodedName!)&media=music&entity=musicArtist&s=\(id)"
        // Set up the URL String
        var urlString = baseURL
        
        guard let url = URL(string: urlString) else {
            print("URL Formatting Error: \(urlString)")
            return
        }
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        
        var dataTask = URLSessionDataTask()
        var request = URLRequest(url: url)
        
        request.addValue(key, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        
        // Debug
        print(urlString)
        
        // Send the request
        dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                print("An error may have occurred")
            } else {
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
                    print("Error - server returned \(httpResponse.statusCode)")
                } else {
                    print("Received: \(data!)")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                        guard let results = json["results"] as? [[String: AnyObject]] else {print("Error 1"); return}
                        
                        if results.count == 1 {
                            print(json)
                            guard let name = results.first!["artistName"] as? String else {print(results); return}
                            guard let artistID = results.first!["artistId"] as? Int else {print(results); return}
                            print("Exact match found:\nName: \(name)\nartistID: \(String(artistID))")
                            // Add the exact match to previous searches if it's not already there
                            self.addArtistToPreviousSearches(artistName: name, artistID: String(artistID))
                            // If the name matches a lowercased string of the query, skip straight into the search
                            
                            self.getTopSongsForArtist(artistID: String(artistID), offset: nil)
                            
                        } else {
                            // Multiple results
                            print(json)
                            
                            self.preliminarySearchTerms.removeAll()
                            for result in results {
                                guard let artistName = result["artistName"] as? String else {print(results); return}
                                guard let artistID = result["artistId"] as? Int else {print(results); return}
                                let artistNameSansThe = artistName.lowercased().replacingOccurrences(of: "the ", with: "")
                                if artistName.lowercased() == name.lowercased() || artistNameSansThe.lowercased() == name.lowercased() {
                                    // We have an exact match now
                                    self.addArtistToPreviousSearches(artistName: artistName, artistID: String(artistID))
                                    self.getTopSongsForArtist(artistID: String(artistID), offset: nil)
                                    return
                                }
                                
                                self.preliminarySearchTerms.append(artistName)
                            }
                            self.spinner.stopAnimating()
                            self.recentLabel.text = "Suggestions"
                            self.recentTableViewMode = .PreliminaryResults
                            self.recentTableView.reloadData()
                        }
                        
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        dataTask.resume()
        
    }
    
    func getTopSongsForArtist(artistID: String, offset: String?) {
        guard let id = storeManager.storefrontID() as? String else {print("No storefont ID yet"); return}
        let baseURL = "https://itunes.apple.com/lookup?id=\(artistID)&entity=song&sort=popular&s=\(id)"
        // Set up the URL String
        var urlString = baseURL

        guard let url = URL(string: urlString) else {
            print("URL Formatting Error: \(urlString)")
            return
        }
        
        // Set up the request
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        
        var dataTask = URLSessionDataTask()
        var request = URLRequest(url: url)
        
        request.addValue(key, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        
        // Debug
        print(urlString)
        
        // Send the request
        dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                print("An error may have occurred")
            } else {
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
                    print("Error - server returned \(httpResponse.statusCode)")
                } else {
                    print("Received: \(data!)")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                        print(json)
                        guard let results = json["results"] as? [[String: AnyObject]] else {
                            print("Error")
                            return
                        }
                        
                        var songArray: [Song] = []
                        
                        for item in results {
                            guard item["isStreamable"] as? Int == 1 else {continue}
                            if let name = item["trackName"] {
                                print(name)
                                let song = Song(artistID: String(describing: item["artistId"]!), artistName: item["artistName"] as! String, albumName: item["collectionName"] as! String, trackName: item["trackName"] as! String, trackID: String(describing: item["trackId"]!), artworkBaseURL: item["artworkUrl100"] as! String, trackLength: item["trackTimeMillis"] as! Int, genre: item["primaryGenreName"] as! String, bg: nil, tc: nil, tc2: nil, tc3: nil, tc4: nil)
                                songArray.append(song)
                            }
                            //print(item)

                        }
                        
                        // NOW! We have a list of songs, we need to:
                        // - Remove repeats
                        // - Remove live songs
                        self.filteredSongList = self.filterSongs(songs: songArray)
                        print("Removed \(songArray.count - self.filteredSongList.count) songs")
                        // - Go back to player, passing in a list of Song objects (name, id, artworkURL etc)
                        
                        self.searchManager.getInfoForSong(id: self.filteredSongList.first!.getTrackID(), completion: { (artworkDict) in
                            print("Next...")
                            self.filteredSongList.first!.setColours(bg: artworkDict["bgColor"] as? String, tc: artworkDict["textColor1"] as? String, tc2: artworkDict["textColor2"] as? String, tc3: artworkDict["textColor3"] as? String, tc4: artworkDict["textColor4"] as? String)
                            self.goBackToPlayerScreen()
                        })
 
                        //self.goBackToPlayerScreen()
                        
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        dataTask.resume()
        
    }
    
    func filterSongs(songs: [Song]) -> [Song] {
        var titleList: [String] = []
        var acceptableList: [Song] = []
        
        for item in songs {
            let title = item.getTrackName()
            if !titleList.contains(title) && title.lowercased().range(of:"(live") == nil {
                titleList.append(item.getTrackName())
                acceptableList.append(item)
            }
        }
        
        return acceptableList
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        queryField.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    func goBackToPlayerScreen() {
        spinner.stopAnimating()
        queryField.resignFirstResponder()
        playerScreen.setUpSongList(list: filteredSongList)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "searchToPlayer":
            print("Segueing...")
            guard let destination = segue.destination as? PlayerViewController else {print("Error segueing");return}
            destination.songList = filteredSongList
        default:
            print("Segue default...")
        }
    }
    
}

