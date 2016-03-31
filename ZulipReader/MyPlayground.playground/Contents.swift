
import Foundation

//NSUserDefaults.standardUserDefaults().integerForKey("none")

NSUserDefaults.standardUserDefaults().setInteger(100, forKey: "100")

NSUserDefaults.standardUserDefaults().integerForKey("100")


let a: Int? = 4

if let b = a where b > 3 {
  print("HAHA!")
}

if let b = a where b > 6 {
  print("HAHA!")
} else {
  print("boohoo")
}