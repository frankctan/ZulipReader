//: Playground - noun: a place where people can play

import UIKit
import SwiftyJSON
import Alamofire

var str = "Hello, playground"

let a: [String: String] = ["1": "hahaha", "2": "lugh"]

let b = a.values

b.count



let json = JSON(["name":["Jack":"1","freda":"2"], "age": 25])

String(json["age"].doubleValue)
let jsonNames = json["name"].arrayValue
let names = jsonNames.map {$0.stringValue}
names


Int.max
Int.min

53551303

let r = ["read","mentioned"]
//.filter {if $0 == "mentioned" {return true}; return false}
r.contains("mentioned")

var arr: [[Int]] = [[]]
var arry = [[Int]()]

arry == arr

arr[0].append(1)
arr[0].append(2)
//arr.append([2])

arr

class Person: NSObject {
  let firstName: String
  let lastName: String
  let age: Int
  
  init(firstName: String, lastName: String, age: Int) {
    self.firstName = firstName
    self.lastName = lastName
    self.age = age
  }
  
  override var description: String {
    return "\(firstName) \(lastName)"
  }
}

let alice = Person(firstName: "Alice", lastName: "Smith", age: 24)
let bob = Person(firstName: "Bob", lastName: "Jones", age: 27)
let charlie = Person(firstName: "Charlie", lastName: "Smith", age: 33)
let quentin = Person(firstName: "Quentin", lastName: "Alberts", age: 31)
let people = [alice, bob, charlie, quentin]

let bobPredicate = NSPredicate(format: "firstName = %@", argumentArray: ["Bob", "Alice"])
let agePredicate = NSPredicate(format: "age >= %D", 28)

let filtered = (people as NSArray).filteredArrayUsingPredicate(bobPredicate)
let filtered1 = (people as NSArray).filteredArrayUsingPredicate(agePredicate)

filtered[0].lastName

var q = ["tan"]

if q is String {
  print("haha")
} else {
  print("nope")
}

struct TableCell {
  let display_recipients: [String]
  let subject: String
  let type: String
  let streamColor: String
  
  let sender_full_name: String
  let content: String
  let dateTime: NSDate
  let avatar_url: String
  let mentioned: Bool
  
}

let dict = ["username": ""]

let stri = "afdsf\n"
"haha"
let style = ["<style>",
  "body{font-family:\"SourceSansPro-Regular\";font-size:15px;line-height:15px;}",
  "</style>"].reduce("",combine: +)

let haha = [["a","b"]]

print(haha)

String(haha)

let haha1 = ["b", "a"]

haha == haha1

var haha2: Set<String> = ["a"]

Set(haha1) == haha2

Array(haha2)[0]

haha2.first


