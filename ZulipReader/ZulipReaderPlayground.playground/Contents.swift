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

var tup: (Int, String)? = (5, "five")

struct AStruct {
  var prop = 1
}

let variable = AStruct()

//variable.prop = 4
//
class AClass {
  var classProp = 1
}

let varClass = AClass()
varClass.classProp = 4

varClass.classProp

let aNum = 40

let bNum = 3

aNum/bNum




