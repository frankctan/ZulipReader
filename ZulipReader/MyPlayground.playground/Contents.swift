import Foundation

struct Person: Equatable {
  let name: String
  let age: Int
  
  init(name: String, age: Int) {
    self.name = name
    self.age = age
  }
}

func ==(lhs: Person, rhs: Person) -> Bool {
  return lhs.name == rhs.name && rhs.age == lhs.age
}

let person1 = Person(name: "Bob", age: 52)
let person2 = Person(name: "Joe", age: 11)
let person3 = person1

person1 != person2

1 == 4

2 == 2

