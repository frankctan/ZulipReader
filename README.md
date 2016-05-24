# ZulipReader

[ZulipReader on the iTunes App Store!](https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=1106052828&mt=8)

Feedback on the code and the app are very appreciated!

![scrolling](http://i.imgur.com/cbue5KZ.gif) ![sidemenu](http://i.imgur.com/DL4amDB.gif) ![loading](http://i.imgur.com/PVqI152.gif)

## Overview

[Zulip](https://github.com/zulip/zulip) is a [powerful open source group chat platform](https://www.zulip.org). I learned Swift and iOS development at the Recurse Center in late 2015 and decided that I could create a better Zulip experience for iOS. This was my first major iOS programming project. Here are some thoughts about development.

### High Level Description

![BasicDiagram](https://raw.githubusercontent.com/frankctan/ZulipReader/master/BasicDiagram.png)

#### Views

The main view of ZulipReader is the StreamTableViewController. Each of the highlighted UITableViewCells allow the user to narrow to a specific stream, topic, or private message. Communication to the UITableViewController is achieved via protocols and delegation. The navigation bar title animates whenever a new message within the narrowed view appears. Tapping the navigation bar title scrolls to the most recent message.

#### Networking and Persistence

I use JaviSoto's [Futures Framework](https://realm.io/news/swift-summit-javier-soto-futures/) in conjunction with [Alamofire](https://github.com/Alamofire/Alamofire) to make API calls to the Zulip server. I use [Realm](https://realm.io) as a persistent layer to store and access messages. I used NSOperationQueues to offload work from the main thread:

* **prepQueue** - checks database for messages and prepares database objects for the table view controller
* **userNetworkQueue** - handles user initiated network requests and saves result to database
* **refreshNetworkQueue** - periodically checks for new messages saves new messages to database

Below is an image that describes the app flow from a typical user action.

![flow](https://raw.githubusercontent.com/frankctan/ZulipReader/master/Flow.png)

### Thoughts On Development
#### Beta

ZulipReader was in beta for 2 weeks. Around 10 people from the Recurse Center participated and their feedback was invaluable. I assumed that everybody used Zulip the way I did; this turned out to be a very poor assumption. Useful advice ranged from including a period for the keyboard in the login view to performance profiling suggestions to identify and resolve bottlenecks.

#### Look and Feel

I wanted the native Zulip experience to feel like an iOS app while keeping true to the original desktop app interface. I took Apple's [human interface guidelines](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/) to heart and adapted suggestions and animations from [MengTo's](https://github.com/mengto/spring) [iOS design tutorials](https://designcode.io). Though there is room for improvement, I'm very pleased with the amount and quality of animations I implemented. In particular, I'm happy with how the login view and new message notifications turned out.

![Login](http://i.imgur.com/hFn7c0y.gif) ![NewMessage](http://i.imgur.com/JYLeU1G.gif)

#### UIKit

UIKit customizability leaves a lot to be desired. Fine grained controls continue to be a source of frustration. All messages in Zulip are displayed as UITableViewCells. Since messages' content lengths are variable (1 word - 500+ words), UITableView content size determination becomes a non-trivial matter. A fixed rowHeight estimate is not accurate while a more detailed accounting could cause a choppy UI. For example, automated scrolling (tapping the navigation bar) or adding a single new refreshed message to the view could cause the scrollView offset to behave sporadically. Simple profiling using NSTimer shows the UITableViewController takes ~3 seconds to load new messages; half that time is used to calculate the size of the content view and scroll to the bottom.

A reasonable solution would be to collapse UITableViewCells if the messages are greater than a preset length. Perhaps a better solution would be to calculate UITableView content sizes separate from the main thread.

#### Networking

I needed a way to efficiently deal with a string of successive network calls and I was not a fan of nested completion handlers. I found that my code quickly became unwieldy and difficult to change. Futures are a great way to display asynchronous code in a seemingly synchronous manner.

#### HTML String manipulation and display

String manipulation in iOS is a surprisingly difficult task. The [original Zulip-iOS project](https://github.com/zulip/zulip-ios) contains the relevant CSS to style Zulip messages. I used regex to search and replace emoji tags with their unicode equivalent and used NSAttributedStrings to convert HTML to a formatted message.

### Next Steps

Most requested features included messages read synchronization between app and desktop and a topic navigation view within each stream. Push notifications should also be enabled when The Zulip API is updated to comply with App Transport Security.