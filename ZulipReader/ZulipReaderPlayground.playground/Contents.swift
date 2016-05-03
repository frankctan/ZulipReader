//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

import SwiftyJSON

var thisIsASet: Set<Int> = [1,2,3,4]

thisIsASet.isEmpty

let subSet = [1,3,2,4,5]

let intersection = thisIsASet.intersect(subSet)

for sub in intersection {
  thisIsASet.remove(sub)
}

thisIsASet

thisIsASet.isEmpty

