////: Playground - noun: a place where people can play
//
//import UIKit
//import SwiftyJSON
//import Alamofire
//import Spring
//
//var str = "Hello, playground"
//
//let msg:[[String:AnyObject]] = [[
//    "content" : "<p>Also you should just read this if you want to know what RESTful is!</p>",
//    "gravatar_hash" : "f74e13c0843195926fa597a574908f39",
//    "sender_full_name" : "Shad William Hopson (F1'15)",
//    "sender_email" : "hopson.shad@gmail.com",
//    "display_recipient" : "writing review",
//    "timestamp" : 1448998387,
//    "client" : "website",
//    "sender_short_name" : "hopson.shad",
//    "type" : "stream",
//    "subject" : "RESTful Article",
//    "sender_domain" : "students.hackerschool.com",
//    "sender_id" : 8473,
//    "id" : 50333824,
//    "content_type" : "text/html",
//    "flags" : [
//    "read"
//    ],
//    "avatar_url" : "https://secure.gravatar.com/avatar/f74e13c0843195926fa597a574908f39?d=identicon",
//    "recipient_id" : 25578,
//    "subject_links" : [
//    
//    ]
//    ], [
//        "content" : "<p>Oooh! Animations!</p>",
//        "gravatar_hash" : "f74e13c0843195926fa597a574908f39",
//        "sender_full_name" : "Shad William Hopson (F1'15)",
//        "sender_email" : "hopson.shad@gmail.com",
//        "display_recipient" : "programming",
//        "timestamp" : 1448998400,
//        "client" : "website",
//        "sender_short_name" : "hopson.shad",
//        "type" : "stream",
//        "subject" : "heap sort",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 8473,
//        "id" : 50333830,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://secure.gravatar.com/avatar/f74e13c0843195926fa597a574908f39?d=identicon",
//        "recipient_id" : 20203,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p>Me too.</p>",
//        "gravatar_hash" : "75d330ef9b091fc9939c9e5df62c4593",
//        "sender_full_name" : "Katerina Barone-Adesi (F'13)",
//        "sender_email" : "katerinab@gmail.com",
//        "display_recipient" : "programming",
//        "timestamp" : 1448999053,
//        "client" : "website",
//        "sender_short_name" : "katerinab",
//        "type" : "stream",
//        "subject" : "evicting things from to-read cache",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 2903,
//        "id" : 50334237,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://secure.gravatar.com/avatar/75d330ef9b091fc9939c9e5df62c4593?d=identicon",
//        "recipient_id" : 20203,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p><span class=\"user-mention\" data-user-email=\"kye@princeton.edu\">@Katherine Ye (S'13)</span> thanks for pledging! You are an excellent person :)</p>",
//        "gravatar_hash" : "59c9b0b8e2edca16e47612d7c2129be7",
//        "sender_full_name" : "David Albert",
//        "sender_email" : "dave@hackerschool.com",
//        "display_recipient" : "programming",
//        "timestamp" : 1448999216,
//        "client" : "website",
//        "sender_short_name" : "davidbalbert",
//        "type" : "stream",
//        "subject" : "help me crowdfund a DataHand keyboard for RC",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 810,
//        "id" : 50334341,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://secure.gravatar.com/avatar/59c9b0b8e2edca16e47612d7c2129be7?d=identicon",
//        "recipient_id" : 20203,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p><a href=\"https://github.com/CestDiego/cracking-the-coding-interview\" target=\"_blank\" title=\"https://github.com/CestDiego/cracking-the-coding-interview\">https://github.com/CestDiego/cracking-the-coding-interview</a></p>",
//        "gravatar_hash" : "f5348e1061215cf50eb1682b5da444ea",
//        "sender_full_name" : "Diego Berrocal (F2'15)",
//        "sender_email" : "cestdiego@gmail.com",
//        "display_recipient" : "programming",
//        "timestamp" : 1448999340,
//        "client" : "website",
//        "sender_short_name" : "cestdiego",
//        "type" : "stream",
//        "subject" : "heap sort",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 8685,
//        "id" : 50334411,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://secure.gravatar.com/avatar/f5348e1061215cf50eb1682b5da444ea?d=identicon",
//        "recipient_id" : 20203,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p>^ repo</p>",
//        "gravatar_hash" : "f5348e1061215cf50eb1682b5da444ea",
//        "sender_full_name" : "Diego Berrocal (F2'15)",
//        "sender_email" : "cestdiego@gmail.com",
//        "display_recipient" : "programming",
//        "timestamp" : 1448999343,
//        "client" : "website",
//        "sender_short_name" : "cestdiego",
//        "type" : "stream",
//        "subject" : "heap sort",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 8685,
//        "id" : 50334414,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://secure.gravatar.com/avatar/f5348e1061215cf50eb1682b5da444ea?d=identicon",
//        "recipient_id" : 20203,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p>I needed the Rose-wake-up-call myself this morning.  : p <span class=\"user-mention\" data-user-email=\"rose@happyspork.com\">@Rose Ames (W'14)</span> </p>",
//        "gravatar_hash" : "ee3eee2d4ac16bb01ad5bf6704029900",
//        "sender_full_name" : "Veronica Hanus (F2'15)",
//        "sender_email" : "vehanus@gmail.com",
//        "display_recipient" : "455 Broadway",
//        "timestamp" : 1448999486,
//        "client" : "desktop app Mac 0.5.0",
//        "sender_short_name" : "vehanus",
//        "type" : "stream",
//        "subject" : "check-ins",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 8689,
//        "id" : 50334500,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://humbug-user-avatars.s3.amazonaws.com/ba07a726ee1569de6373ec1f3b8a149354574286?x=x",
//        "recipient_id" : 20330,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p><img alt=\":thumbsup:\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/thumbsup.png\" title=\":thumbsup:\"> thanks, look forward to reading this <span class=\"user-mention\" data-user-email=\"laurenzlong@gmail.com\">@Lauren Long (F2'15)</span>!</p>",
//        "gravatar_hash" : "654527a5cff1756177ef0b1bb0af7aa3",
//        "sender_full_name" : "Anjana Sofia Vakil (F2'15)",
//        "sender_email" : "anjanavakil@gmail.com",
//        "display_recipient" : "writing review",
//        "timestamp" : 1448999712,
//        "client" : "desktop app Mac 0.5.0",
//        "sender_short_name" : "anjanavakil",
//        "type" : "stream",
//        "subject" : "RESTful Article",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 8686,
//        "id" : 50334651,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://humbug-user-avatars.s3.amazonaws.com/ac82c34dd31c761cd9dd847d9d93a00c41c03938?x=x",
//        "recipient_id" : 25578,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p><img alt=\":thumbsup:\" class=\"emoji\" src=\"static/third/gemoji/images/emoji/thumbsup.png\" title=\":thumbsup:\"> </p>",
//        "gravatar_hash" : "6b7d06ffe534feded92015b89a81f3d3",
//        "sender_full_name" : "Lauren Long (F2'15)",
//        "sender_email" : "laurenzlong@gmail.com",
//        "display_recipient" : "writing review",
//        "timestamp" : 1448999796,
//        "client" : "desktop app Linux 0.4.4",
//        "sender_short_name" : "laurenzlong",
//        "type" : "stream",
//        "subject" : "RESTful Article",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 8706,
//        "id" : 50334726,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://secure.gravatar.com/avatar/6b7d06ffe534feded92015b89a81f3d3?d=identicon",
//        "recipient_id" : 25578,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p>Hey everyone! The slides are up. Sorry I'm so late.</p>\n<p><a href=\"http://sisyphus.rocks/talks/protocols-multimethods-records\" target=\"_blank\" title=\"http://sisyphus.rocks/talks/protocols-multimethods-records\">http://sisyphus.rocks/talks/protocols-multimethods-records</a></p>\n<p>If you're looking to clone the repo to follow along on your own computer, you can grab the code here.</p>\n<p><a href=\"https://github.com/MysteryMachine/lispmon\" target=\"_blank\" title=\"https://github.com/MysteryMachine/lispmon\">https://github.com/MysteryMachine/lispmon</a></p>",
//        "gravatar_hash" : "4f388e8f2d7838cbdbdcdf315163103a",
//        "sender_full_name" : "Salomao Diovanni Montemezzo Becker (F2'15)",
//        "sender_email" : "physicsfu@gmail.com",
//        "display_recipient" : "programming",
//        "timestamp" : 1449000157,
//        "client" : "website",
//        "sender_short_name" : "physicsfu",
//        "type" : "stream",
//        "subject" : "LISPmons: Classless Polymorphism in Clojure",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 8695,
//        "id" : 50334973,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://secure.gravatar.com/avatar/4f388e8f2d7838cbdbdcdf315163103a?d=identicon",
//        "recipient_id" : 20203,
//        "subject_links" : [
//        
//        ]
//    ], [
//        "content" : "<p>Thank you for your pledge <span class=\"user-mention\" data-user-email=\"tehgeekmeister@gmail.com\">@Ezekiel Benjamin Smithburg (F2'15)</span>!</p>",
//        "gravatar_hash" : "59c9b0b8e2edca16e47612d7c2129be7",
//        "sender_full_name" : "David Albert",
//        "sender_email" : "dave@hackerschool.com",
//        "display_recipient" : "programming",
//        "timestamp" : 1449000303,
//        "client" : "website",
//        "sender_short_name" : "davidbalbert",
//        "type" : "stream",
//        "subject" : "help me crowdfund a DataHand keyboard for RC",
//        "sender_domain" : "students.hackerschool.com",
//        "sender_id" : 810,
//        "id" : 50335054,
//        "content_type" : "text/html",
//        "flags" : [
//        "read"
//        ],
//        "avatar_url" : "https://secure.gravatar.com/avatar/59c9b0b8e2edca16e47612d7c2129be7?d=identicon",
//        "recipient_id" : 20203,
//        "subject_links" : [
//        
//        ]
//    ]]
//
//
//class Cell {
//}
//
//class StreamHeaderCell: Cell {
//    var stream = String()
//    var subject = String()
//    
//    init(msgStream: String, msgSubject: String) {
//        stream = msgStream
//        subject = msgSubject
//    }
//}
//
//class UserHeaderCell: Cell {
//    var name = String()
//    var avatarURL = String()
//    
//    init(msgName: String, msgAvatarURL: String) {
//        name = msgName
//        avatarURL = msgAvatarURL
//    }
//
//}
//
//class MessageCell: Cell {
//    var content = NSAttributedString()
//    var timestamp = String()
//    
//    init(msgContent: NSAttributedString, msgTimestamp: String) {
//       content = msgContent
//        timestamp = msgTimestamp
//    }
//}
//
//
//var messagesWithHeaders = [Cell]()
//
//struct Previous {
//    var stream = ""
//    var subject = ""
//    var name = ""
//}
//var stored = Previous()
//
//for message in msg {
//    let name = message["sender_full_name"] as? String
//    let content = message["content"] as? String
//    let avatarURL = message["avatar_url"] as? String
//    let stream = message["display_recipient"] as? String
//    let subject = message["subject"] as? String
//    
//    let attributedContent = htmlToAttributedString(content! + "<style>*{font-family:\"Avenir Next\";font-size:15px;line-height:15px}img{max-width:300px}</style>")
//    let timestamp = NSDate(timeIntervalSince1970: (message["timestamp"] as? Double)!)
//    let formattedTimestamp = timeAgoSinceDate(date, numericDates: true)
//
//    
//    if stored.stream == stream && stored.subject == subject {
//        if stored.name != name {
//            messagesWithHeaders.append(UserHeaderCell(msgName: name!, msgAvatarURL: avatarURL!))
//        }
//        messagesWithHeaders.append(MessageCell(msgContent: attributedContent!, msgTimestamp: formattedTimestamp))
//    } else {
//        messagesWithHeaders.append(StreamHeaderCell(msgStream: stream!, msgSubject: subject!))
//        messagesWithHeaders.append(UserHeaderCell(msgName: name!, msgAvatarURL: avatarURL!))
//        messagesWithHeaders.append(MessageCell(msgContent: attributedContent!, msgTimestamp: formattedTimestamp))
//    }
//    
//    stored.stream = stream!
//    stored.subject = subject!
//    stored.name = name!
//}
//
//
//var count = 0
//for item in messagesWithHeaders {
//    switch item {
//    case is StreamHeaderCell:
//        count++
//    default:
//        continue
//    }
//}
//
//

//var a = (1,1)
//a.0
//
//
//var b = ["haha":"no", "ugh":"yes","a":"b"]
//
//var lol = b.sort {$0.0 < $1.0}
//
//print(lol)

var ugh = ["food": "#b0a5fd", "settlers": "#94c849", "code review": "#c2c2c2", "compilers": "#a6c7e5", "git": "#76ce90", "coffee": "#95a5fd", "iOS": "#bd86e5", "eventstorm": "#ee7e4a", "friday-jobs-prep": "#f5ce6e", "books": "#fae589", "announce": "#76ce90", "data": "#bfd56f", "programming": "#b0a5fd", "Swift": "#a6dcbf", "455 Broadway": "#c2726a", "The Loop": "#a6dcbf", "design": "#a6dcbf", "F2 2015": "#95a5fd", "advice": "#a6dcbf", "checkins": "#c6a8ad", "graphics": "#f4ae55", "writing review": "#f4ae55", "Java": "#94c849", "commits": "#9987e1", "OSS at HS": "#e7cc4d", "ruby": "#f5ce6e", "pairing": "#addfe5", "javascript": "#e79ab5", "talks": "#a47462", "network": "#94c849", "Victory": "#e79ab5", "zulip": "#a6c7e5", "social": "#bfd56f", "Small Answers": "#4f8de4", "Congratulations": "#c2726a", "projects": "#e4523d", "help": "#c8bebf", "hardware": "#53a063", "blogging": "#bd86e5", "tools": "#ee7e4a"]

var lol = [(String,String)]()

for (k,v) in Array(ugh).sort({$0.0 < $1.0}) {
    lol.append((k,v))
}

lol



