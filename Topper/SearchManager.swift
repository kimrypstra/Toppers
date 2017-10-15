//
//  SearchManager.swift
//  Topper
//
//  Created by Kim Rypstra on 17/9/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import Foundation

class SearchManager: NSObject, URLSessionDelegate {

    fileprivate let key = "Bearer eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlJKNlNXVTZMVDQifQ.eyJpc3MiOiJZQkNDVFdIMldXIiwiaWF0IjoxNTA2ODQxNDU5LCJleHAiOjE1MDgwNTEwNTl9.SOgTJxqX0eV_mWj675Ar4mi8-jFzXdez9vJ2VfajiXEHNuiplxOpgnqQrBAEps_fA-A5xegSEP-JQtC7rvFhdA"

    
    var storeManager: StoreManager!
    
    init(storeManager: StoreManager) {
        self.storeManager = storeManager
    }
    
    func getTracksForAlbum(id: String, completion: @escaping ([Song]) -> ()) {
        guard let storeID = storeManager.storefrontID() else {
            print("Error getting store ID")
            return 
        }
        let baseURL = "https://itunes.apple.com/lookup?id=\(id)&entity=song&s=\(storeID)"
        
        // Set up the URL String
        var urlString = baseURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "%20", with: "+")
        
        guard let url = URL(string: urlString!) else {
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
                    print("Error - server returned \(httpResponse.statusCode). Error: \(data!)")
                    let dataString = String.init(data: data!, encoding: String.Encoding.utf8)
                    print(dataString)
                    completion([])
                } else {
                    print("Received: \(data!)")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                        //print(json)
                        
                        guard let results = json["results"] as? [[String: AnyObject]] else {
                            print("Error")
                            return
                        }
                        
                        print(results)
                        var songs: [Song] = []
                        
                        for item in results {
                            //print(item)
                            if item["kind"] as? String == "song" {
                                let song = Song(artistID: String(describing: item["artistId"]!), artistName: item["artistName"] as! String, albumName: item["collectionName"] as! String, trackName: item["trackName"] as! String, trackID: String(describing: item["trackId"]!), artworkBaseURL: item["artworkUrl100"] as! String, trackLength: item["trackTimeMillis"] as! Int, genre: item["primaryGenreName"] as! String, bg: nil, tc: nil, tc2: nil, tc3: nil, tc4: nil)
                                songs.append(song)
                            }
                            
                        }
                        
                        completion(songs)
                        
                        
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        dataTask.resume()
    }
    
    func searchForAlbum(query: String, completion: @escaping ([Album]) -> ()) {
        guard let storeID = storeManager.storefrontID() else {
            print("Error getting store ID")
            return
        }
        
        let baseURL = "https://itunes.apple.com/search?term=\(query)&entity=album&s=\(storeID)"
        
        // Set up the URL String
        var urlString = baseURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "%20", with: "+")
        
        guard let url = URL(string: urlString!) else {
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
                    print("Error - server returned \(httpResponse.statusCode). Error: \(data!)")
                    let dataString = String.init(data: data!, encoding: String.Encoding.utf8)
                    print(dataString)
                    completion([])
                } else {
                    print("Received: \(data!)")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                        
                        
                        guard let results = json["results"] as? [[String: AnyObject]] else {
                            print("Error")
                            return
                        }
                        var albums: [Album] = []
                        for entry in results {
                            let album = Album(name: entry["collectionName"] as! String, id: entry["collectionId"] as! Int, artworkURL: entry["artworkUrl100"] as! String, artistName: entry["artistName"] as! String)
                            albums.append(album)
                        }
                        
                        completion(albums)
                        
                        
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        dataTask.resume()
    }
    
    func getInfoForSong(id: String, completion: @escaping ([String: AnyObject]) -> ()) {
        let baseURL = "https://api.music.apple.com/v1/catalog/au/songs/\(id)"
        //let baseURL = "https://api.music.apple.com/v1/catalog/us/charts?types=songs"
        
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
                    print("Error - server returned \(httpResponse.statusCode). Error: \(data!)")
                    let dataString = String.init(data: data!, encoding: String.Encoding.utf8)
                    print(dataString)
                    completion([:])
                } else {
                    print("Received: \(data!)")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                        //print(json)
                        guard let results = (json["data"] as? [[String: AnyObject]])?.first!["attributes"] as? [String: AnyObject] else {
                            print("Error")
                            return
                        }
                        
                        guard let artwork = results["artwork"] as? [String: AnyObject] else {
                            print("Error 2")
                            print(results)
                            return
                        }
                        print(artwork)
                        completion(artwork)
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        dataTask.resume()
    }
    
    
}
