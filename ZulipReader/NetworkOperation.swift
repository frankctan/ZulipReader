//
//  NetworkOperation.swift
//  ZulipReader
//
//  Created by Frank Tan on 3/23/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation

class NetworkOperation: NSOperation {
  //override executing and finished to be KVO compliant because of networking call
  private var _executing: Bool = false
  override var executing: Bool {
    get {
      return _executing
    }
    set {
      if (_executing != newValue) {
        self.willChangeValueForKey("isExecuting")
        _executing = newValue
        self.didChangeValueForKey("isExecuting")
      }
    }
  }
  
  private var _finished: Bool = false;
  override var finished: Bool {
    get {
      return _finished
    }
    set {
      if (_finished != newValue) {
        self.willChangeValueForKey("isFinished")
        _finished = newValue
        self.didChangeValueForKey("isFinished")
      }
    }
  }

  func complete() {
    self.finished = true
    self.executing = false
  }

  
}