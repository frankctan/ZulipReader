//: Playground - noun: a place where people can play

import UIKit
import SwiftyJSON
import Alamofire

var str = "Hello, playground"

let a: [String: String] = ["1": "hahaha", "2": "lugh"]

let b = a.values

b.count



let json = JSON(["name":"Jack", "age": 25])

String(json["age"].doubleValue)


Int.max
Int.min

53551303

let r = ["read","mentioned"]
  //.filter {if $0 == "mentioned" {return true}; return false}
r.contains("mentioned")

var arr: [[Int]] = [[]]

//arr.append([])
arr[0].append(1)
arr.append([])
arr[1].append(2)

arr
