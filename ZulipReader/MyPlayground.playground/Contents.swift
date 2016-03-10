import Foundation


class Person: NSObject {
  let firstName: String
  let lastName: String
  let age: Int
  let hairColor: [String] = ["black","blonde"]
  let ugly = true
  
  init(firstName: String, lastName: String, age: Int) {
    self.firstName = firstName
    self.lastName = lastName
    self.age = age
  }
  

}

let alice = Person(firstName: "Alice", lastName: "Smith", age: 24)
let bob = Person(firstName: "Bob", lastName: "Jones", age: 27)
let charlie = Person(firstName: "Charlie", lastName: "Smith", age: 33)
let quentin = Person(firstName: "Quentin", lastName: "Alberts", age: 31)
let people: NSArray = [alice, bob, charlie, quentin]

people.count

let bobPredicate1 = NSPredicate(format: "firstName = 'Bob'")
let bobPredicate = NSPredicate(format: "firstName = %@", "Bob")
let smithPredicate = NSPredicate(format: "lastName = %@", "Smith")
let thirtiesPredicate = NSPredicate(format: "age >= 30")

//let hairPredicate = NSPredicate(format: "ANY hairColor IN %@ AND firstName = %@", ["black, blonde"], "Alice")

let hairPredicate = NSPredicate(format: "(ALL %@ IN %K) AND (ALL %K IN %@)", ["black", "blonde"], "hairColor", "hairColor", ["blonde","black"])

let result:NSArray = people.filteredArrayUsingPredicate(hairPredicate)
result.count

result[0].firstName

let hairPredicate1 = NSPredicate(format: "%K[SIZE] = %d", "hairColor", 2)
result.filteredArrayUsingPredicate(hairPredicate1)

let peeps = people as! [Person]

let predicate: [NSPredicate?] = [hairPredicate, hairPredicate1, nil]
let filteredPredicate: [NSPredicate] = predicate.filter {
  if $0 != nil {
    return true
  }
  return false
  }.map {$0!}

let compound = NSCompoundPredicate(andPredicateWithSubpredicates: filteredPredicate)

let uglyPredicate = NSPredicate(format: "ugly = %@", false)

result.filteredArrayUsingPredicate(uglyPredicate)

let dict: [String: Int] = ["c": 1, "b": 2, "a": 3]

Int.max
2147483647
2147483647

let sortedDict = dict.sort {$0.0 < $1.0}



var b: [String:String] = [:]

b["a"] = nil

b["one"] = "yes"

b

var qw: Set<String> = ["a","b"]

qw.insert("c")

let t = qw.remove("a")
t
qw
qw.remove("q")


qw





