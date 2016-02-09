//heartbeat

//{
//    "result": "success",
//    "queue_id": "1449973412:316501",
//    "msg": "",
//    "events": [
//    {
//    "type": "heartbeat",
//    "id": 0
//    }
//    ]
//}

import SwiftyJSON


let stuff: [JSON] = [
    [
    "type": "heartbeat",
    "id": 0
    ]
    ]

stuff[0]["type"].stringValue


var a:Set<String> = ["abc","abe"]

a.remove("abc")

print(a)

a.remove("bed")

print(a)


let urlString = "https://www.google.com/"
urlString.stringByAdd

