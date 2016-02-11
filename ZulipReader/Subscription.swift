//
//  Subscription.swift
//  ZulipReader
//
//  Created by Frank Tan on 2/11/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import RealmSwift

class Subscription: Object {
  dynamic var stream_id = 0.0
  dynamic var name = ""
  dynamic var color = ""
}