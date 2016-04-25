//
//  MessageMarker.swift
//  ZulipReader
//
//  Created by Frank Tan on 3/31/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation
import RealmSwift

class MessageMarker: Object {
  dynamic var narrowString = ""
  dynamic var minId = Int.max
  //maxId is only used when narrowString = "home"
  dynamic var maxId = Int.min
}