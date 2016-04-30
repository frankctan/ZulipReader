//
//  AppDelegate.swift
//  ZulipReader
//
//  Created by Frank Tan on 11/16/15.
//  Copyright © 2015 Frank Tan. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    var realm: Realm {
      do {
        return try Realm()
      } catch let error as NSError {
        fatalError("AppDelegate Error: \(error)")
      }
    }
    
    //Delete persisted files everytime app is launched
    //For v2, we can do a better job persisting messages instead of reloading every session
    do {
      try NSFileManager.defaultManager().removeItemAtURL(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    catch {print("could not delete")}
    print("AppDelegate: deleted realm files")
    
    //delete NSUserDefaults
    for key in NSUserDefaults.standardUserDefaults().dictionaryRepresentation().keys {
      //we need email to process messages. Everything else should be deleted
      if key != "email" && key != "domain" {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
      }
    }

    
    let frame = UIScreen.mainScreen().bounds
    window = UIWindow(frame: frame)
    self.window?.backgroundColor = UIColor.whiteColor()
    
    let frontViewController = UINavigationController(rootViewController: StreamTableViewController())
    let revealViewController = SWRevealViewController()
    revealViewController.setFrontViewController(frontViewController, animated: true)

    self.window?.rootViewController = revealViewController
    self.window?.makeKeyAndVisible()
    
    return true
  }
  
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(application: UIApplication) {
  }
  
  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
}

//    let realmMessages = realm.objects(Message).sorted("id", ascending: true)
//    let realmCount = realmMessages.count
//    //TODO: CHANGE THIS TO BE LARGER LATER.
//    let realmThres = 10
//
//    if realmCount > realmThres {
//      print("realm Messages Stored: \(realmCount)")
//      let maxDelete = realmCount - realmThres
//      realm.beginWrite()
//      for index in 0 ..< maxDelete {
//        realm.delete(realmMessages[index])
//      }
//      do { try realm.commitWrite()}
//      catch let error as NSError {print("AppDelegate Error: could not delete - \(error)")
//    }
//      print("after Deletion: \(realmCount)")
//

