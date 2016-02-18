//
//  Futures.swift
//  ZulipReader
//
//  Created by Frank Tan on 2/17/16.
//  Copyright © 2016 Frank Tan. All rights reserved.
//


public final class Box<T> {
  public let unbox: T
  
  init(_ value: T) {
    self.unbox = value
  }
}

public protocol ErrorType { }

public enum NoError: ErrorType { }

extension NSError: ErrorType { }

public enum Result<T, E: ErrorType> {
  case Success(Box<T>)
  case Error(Box<E>)
}

extension Result: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .Success(let valueBox):
      return "Success: \(String(valueBox.unbox))"
    case .Error(let errorBox):
      return "Error: \(String(errorBox.unbox))"
    }
  }
}

public struct Future<T, E: ErrorType> {
  public typealias ResultType = Result<T, E>
  public typealias Completion = ResultType -> ()
  public typealias AsyncOperation = Completion -> ()
  
  private let operation: AsyncOperation
  
  public init(result: ResultType) {
    self.init(operation: { completion in
      completion(result)
    })
  }
  
  public init(value: T) {
    self.init(result: .Success(Box(value)))
  }
  
  public init(error: E) {
    self.init(result: .Error(Box(error)))
  }
  
  public init(operation: AsyncOperation) {
    self.operation = operation
  }
  
  public func start(completion: Completion) {
    self.operation { result in
      completion(result)
    }
  }
}

extension Future {
  public func map<U>(f: T -> U) -> Future<U, E> {
    return Future<U, E>(operation: { completion in
      self.start { result in
        switch result {
        case .Success(let valueBox): completion(Result.Success(Box(f(valueBox.unbox))))
        case .Error(let errorBox): completion(Result.Error(errorBox))
        }
      }
    })
  }
  
  
  public func andThen<U>(f: T -> Future<U, E>) -> Future<U, E> {
    return Future<U, E>(operation: { completion in
      self.start { firstFutureResult in
        switch firstFutureResult {
        case .Success(let valueBox): f(valueBox.unbox).start(completion)
        case .Error(let errorBox): completion(Result.Error(errorBox))
        }
      }
    })
  }
}

extension Future {
  func mapError<F>(f: E -> F) -> Future<T, F> {
    return Future<T, F>(operation: { completion in
      self.start { result in
        switch result {
        case .Success(let valueBox): completion(Result.Success(valueBox))
        case .Error(let errorBox): completion(Result.Error(Box(f(errorBox.unbox))))
        }
      }
    })
  }
}

