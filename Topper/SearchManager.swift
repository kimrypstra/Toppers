//
//  SearchManager.swift
//  Topper
//
//  Created by Kim Rypstra on 17/9/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import Foundation

class SearchManager: NSObject, URLSessionDelegate {

    fileprivate let key = "Bearer eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlJKNlNXVTZMVDQifQ.eyJpc3MiOiJZQkNDVFdIMldXIiwiaWF0IjoxNTA4NDIyMzYxLCJleHAiOjE1MDk2MzE5NjF9.Zh9aN9EN0aBj9yCW087NN_v2JIj3socyNEmSun9VsTd4z369JooVm8ywZ0vIEby_FOmH6azvj4m-LglDAIlzAg"

    
    var storeManager: StoreManager!
    
    init(storeManager: StoreManager) {
        self.storeManager = storeManager
    }
    
    func getKey() -> String {
        return key
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
        // - HERE! Change the 'au' to some storeManager.storefrontCode() thing
        guard let storeCode = Locale.current.regionCode?.lowercased() else {
            print("Problem getting locale")
            return
        }
        let baseURL = "https://api.music.apple.com/v1/catalog/\(storeCode)/songs/\(id)"
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
    
    func getGenreIDs(completion: @escaping ([String: String]?) -> ()) {
        // Get the store code
        guard let storeCode = Locale.current.regionCode?.lowercased() else {
            print("Problem getting locale")
            completion(nil)
            return
        }
        
        // Set up the URL
        let baseURL = "https://api.music.apple.com/v1/catalog/\(storeCode)/genres"
        var urlString = baseURL
        
        guard let url = URL(string: urlString) else {
            print("URL Formatting Error: \(urlString)")
            completion(nil)
            return
        }
        
        // Set up the request
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        var dataTask = URLSessionDataTask()
        var request = URLRequest(url: url)
        
        // Add auth field
        request.addValue(key, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        
        // Debug
        print(urlString)
        
        // Do the thing
        dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                // Handle any errors
                print("An error may have occurred: \(error?.localizedDescription)")
            } else {
                // Check the HTTP response
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
                    print("Error - server returned \(httpResponse.statusCode). Error: \(data!)")
                    let dataString = String.init(data: data!, encoding: String.Encoding.utf8)
                    print(dataString)
                    completion(nil)
                } else {
                    // Handle the data
                    print("Received: \(data!)")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                        //print(json)
                        let data = json["data"] as! [[String: AnyObject]]
                        //print(data)
                        var genres: [String: String] = [:]
                        for item in data {
                            guard let attr = item["attributes"] as? [String: String] else {return}
                            //print("Name: \(attr["name"]!)")
                            guard let id = item["id"] as? String else {return}
                            //print("ID: \(id)")
                            genres[attr["name"]!] = id
                        }
                        
                        completion(genres)
                        
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        // Actually make it happen
        dataTask.resume()
    }
    
    func getChartForGenre(genre: String, completion: @escaping ([Song]?) -> ()) {
        //getAllChartTypes()
        print("Rec'd req for genre: \(genre)")
        // Get the store code
        guard let storeCode = Locale.current.regionCode?.lowercased() else {
            print("Problem getting locale")
            completion(nil)
            return
        }
        
        // Set up the URL
        let baseURL = "https://api.music.apple.com/v1/catalog/\(storeCode)/charts?types=songs&genre=\(genre)"
        var urlString = baseURL
        
        guard let url = URL(string: urlString) else {
            print("URL Formatting Error: \(urlString)")
            completion(nil)
            return
        }
        
        // Set up the request
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        var dataTask = URLSessionDataTask()
        var request = URLRequest(url: url)
        
        // Add auth field
        request.addValue(key, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        
        // Debug
        print(urlString)
        
        // Do the thing
        dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                // Handle any errors
                print("An error may have occurred: \(error?.localizedDescription)")
            } else {
                // Check the HTTP response
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
                    print("Error - server returned \(httpResponse.statusCode). Error: \(data!)")
                    let dataString = String.init(data: data!, encoding: String.Encoding.utf8)
                    print(dataString)
                    completion(nil)
                } else {
                    // Handle the data
                    print("Received: \(data!)")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                        //print(json)
                        guard let results = json["results"] as? [String: AnyObject] else {print("Problem stage 2");return}
                        //print(results)
                        guard let songArr = results["songs"] as? NSArray else {print("Problem stage 3");return} //This is a single object array
                        //print(songArr)
                        guard let data = songArr[0] as? [String: AnyObject] else {print("Problem stage 4");return}
                        //print(data)
                        guard let songs = data["data"] as? [[String: AnyObject]] else {print("Problem stage 5");return}
                        //print(songs)
                        
                        var songArray: [Song] = []
                        for item in songs {
                            let songObject = item["attributes"] as! [String: AnyObject]
                            guard let artwork = songObject["artwork"] as? [String: AnyObject] else {print("Error getting artwork"); return}
                            guard let playParams = songObject["playParams"] as? [String: AnyObject] else {print("Error getting play params?");return}
                            
                            let song = Song(artistID: "",
                                            artistName: songObject["artistName"] as! String,
                                            albumName: songObject["albumName"] as! String,
                                            trackName: songObject["name"] as! String,
                                            trackID: playParams["id"] as! String,
                                            artworkBaseURL: artwork["url"] as! String,
                                            trackLength: songObject["durationInMillis"] as! Int,
                                            genre: songObject["genreNames"].debugDescription,
                                            bg: artwork["bgColor"] as! String,
                                            tc: artwork["textColor1"] as! String,
                                            tc2: artwork["textColor2"] as! String,
                                            tc3: artwork["textColor3"] as! String,
                                            tc4: artwork["textColor4"] as! String)
                            songArray.append(song)
                        }
                        completion(songArray)
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        // Actually make it happen
        dataTask.resume()
    }
    
    func getAllChartTypes() {
        guard let storeCode = Locale.current.regionCode?.lowercased() else {
            print("Problem getting locale")
            return
        }
        
        // Set up the URL
        let baseURL = "https://api.music.apple.com/v1/catalog/\(storeCode)/charts?types=songs&limit=1"
        var urlString = baseURL
        
        guard let url = URL(string: urlString) else {
            print("URL Formatting Error: \(urlString)")
            //completion(nil)
            return
        }
        
        // Set up the request
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        var dataTask = URLSessionDataTask()
        var request = URLRequest(url: url)
        
        // Add auth field
        request.addValue(key, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        
        // Debug
        print(urlString)
        
        // Do the thing
        dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                // Handle any errors
                print("An error may have occurred: \(error?.localizedDescription)")
            } else {
                // Check the HTTP response
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
                    print("Error - server returned \(httpResponse.statusCode). Error: \(data!)")
                    let dataString = String.init(data: data!, encoding: String.Encoding.utf8)
                    print(dataString)
                    //completion(nil)
                } else {
                    // Handle the data
                    print("Received: \(data!)")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                        print("** CHARTS ** \n \(json)")
                    } catch let error {
                        print("Error decoding data to JSON: \(error)")
                    }
                }
            }
        })
        
        // Actually make it happen
        dataTask.resume()
    }
    
    
}
