//
//  UITableViewCellExtension.swift
//  ZulipReader
//
//  Created by Frank Tan on 2/22/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//

import Foundation

protocol Configurable {
  func configure(message: TableCell)
}

extension UITableViewCell: Configurable {
  func configure(message: TableCell) {}
}