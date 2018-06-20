<img src="https://github.com/kimrypstra/Toppers/blob/master/Reversed_Curved.png" alt="Unitrans Logo" width="200px"/>

# Toppers
### An Apple Music client

Toppers is an Apple Music client designed primarily for listening to an artist's top songs. In the stock Apple Music app, when you listen to an artist's top songs you are likely to hear repeats of the same song if they appear in multiple albums. Toppers filters out repeated songs, leaving you to listen to an artist's most popular songs without mashing the skip button. 

### Availablity
Toppers is in early development and isn't suitable for release yet, although most of the features are working.

### UI
Toppers presents a minimal user interface, with only the artwork, song information, and next track showing - time remaining, media controls, and volume are not surfaced. Instead of buttons, gestures are used to play, pause, and skip tracks.

<img src="https://github.com/kimrypstra/Toppers/blob/master/IMG_0765.JPG" alt="Unitrans Logo" width="200px"/> <img src="https://github.com/kimrypstra/Toppers/blob/master/IMG_0767.JPG" alt="Unitrans Logo" width="200px"/> <img src="https://github.com/kimrypstra/Toppers/blob/master/IMG_0768.JPG" alt="Unitrans Logo" width="200px"/>


### Dependencies
Toppers uses the iTunes Search API to get an artist's top songs and some information for each track, then uses the Apple Music API to get more information and play the full version using MusicKit. Here are some of the tasks using each API:

Apple Music API: 
- Search suggestions
- Get genre list
- Get genre charts
- Get song metadata

iTunes Search API: 
- Get top songs for an artist
- Search for an artist name
- Search for an album

### Searching
The Apple Music API does not sort songs by popularity and the iTunes Search API does not give the required song metadata, so Toppers uses both. Here is how a top song search occurs: 
1. As the user starts typing, the Apple Music API provides search suggestions
2. If a user taps on a suggestion, the app uses the iTunes Search API to retrieve that artist's songs sorted by popularity
3. If a user keeps typing and taps the search button, the app uses the iTunes Search API to search for a matching artist name 
4. If a matching name is found, step 2 is carried out using that name. If there are multiple matches, a table view with the results is populated
5. When the user taps on a result, step 2 is carried out using that name.
6. Music stars playing, with the playlist sorted from most to least popular 
7. Song metadata (artwork, colours etc.) are retreived from the Apple Music API
