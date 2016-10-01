//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

typealias NoError = Result.NoError

public class ChangeObserver<T: Equatable> {
  public let changeSignal: SignalProducer<([Int], [Int]), Result.NoError>
  public let objects = MutableProperty([T]())

  private let objectsSignal: MutableProperty<SignalProducer<[T], NoError>> = MutableProperty(SignalProducer.empty)

  public func bindToProducer(producer: SignalProducer<[T], Result.NoError>) {
    objectsSignal.value = producer
  }

  public init() {
    objects <~ objectsSignal.producer.flatten(.Latest)
    changeSignal = objects.producer.combinePrevious([]).map(diffArrays)
  }
}

public func diffArrays<Elt: Equatable>(_ old: [Elt], _ new: [Elt]) -> (remove: [Int], insert: [Int]) {
  let rowsToRemove = old.filter {
    return !new.contains($0)
  }.map {
    return old.index(of: $0)!
  }
  let rowsToInsert = new.filter {
    return !old.contains($0)
  }.map {
    return new.index(of: $0)!
  }
  return (rowsToRemove, rowsToInsert)
}

func indexPathWithRow(_ row: Int) -> IndexPath {
  return IndexPath(index: 0).adding(row)
}
