import Foundation


class Person: NSObject {
  let firstName: String
  let lastName: String
  let age: Int
  let hairColor: [String] = ["black", "blonde"]
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

let hairPredicate = NSPredicate(format: "ALL %@ IN %K", ["blonde"], "hairColor")

let result:NSArray = people.filteredArrayUsingPredicate(hairPredicate)
result.count


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

let a = true
var re: Bool
re = a ? true : false

var c:Int?

var b = 0 {
didSet {
  c = b
}
}




b = 11

c

struct Haha {
  var b  = 0
  var c = 5 {
    didSet {
      b = c
    }
  }
  init(q: Int) {
    c = q
  }
}

var qw = Haha(q: 1)

qw.c
qw.b

qw.c = 4
qw.b















