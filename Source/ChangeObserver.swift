//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

typealias NoError = Result.NoError

public class ChangeObserver<T: Equatable> {
  public let changeSignal: Signal<([Int], [Int]), Result.NoError>
  public let objects = MutableProperty([T]())

  private let objectsSignal: MutableProperty<SignalProducer<[T], NoError>> = MutableProperty(SignalProducer.empty)

  public func bindToProducer(producer: SignalProducer<[T], Result.NoError>) {
    objectsSignal.value = producer
  }

  init() {
    objects <~ objectsSignal.signal.flatten(.Latest)
    changeSignal = objects.signal.combinePrevious([]).map { old, new in
      let rowsToRemove = old.filter {
        return !new.contains($0)
      }.map {
        return old.indexOf($0)!
      }
      let rowsToInsert = new.filter {
        return !old.contains($0)
      }.map {
        return new.indexOf($0)!
      }
      return (rowsToRemove, rowsToInsert)
    }
  }
}

func indexPathWithRow(row: Int) -> NSIndexPath {
  return NSIndexPath(index: 0).indexPathByAddingIndex(row)
}
