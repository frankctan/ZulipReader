import Foundation
import RealmSwift


class Person: Object {
  dynamic var name  = ""
  dynamic var age = 0
}

let realm = try! Realm()

let person1 = Person(value: ["name": "Job", "age": 2])
let person2 = Person(value: ["name": "Bill", "age": 10])

try! realm.write {
  realm.add(person1)
  realm.add(person2)
}

let realmObjects = realm.objects(Person).sorted("age", ascending: false)
realmObjects[1].name


1+1


let personPredicate = NSPredicate(format: "age == %d", 2)

let filteredObjects = realm.objects(Person).filter(personPredicate)

filteredObjects[0].name

let a:[[String]] = [[]]

a[0].isEmpty


for i in 0..<0 {
  print(i)
}

var q = 4
add(q)
func add(x: Int) -> Int {
  return x + 2
}

q = 7



