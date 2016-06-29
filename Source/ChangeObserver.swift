//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

typealias NoError = Result.NoError

class ChangeObserver<T: Equatable> {
  var objects = MutableProperty([T]())

  var changeSignal: Signal<([NSIndexPath], [NSIndexPath]), Result.NoError>

  var objectsSignal: MutableProperty<Signal<[T], NoError>> = MutableProperty(Signal.never)

  public func setBindingToSignal(signal: Signal<[T], Result.NoError>) {
    objectsSignal.value = signal
  }

  init() {
    objects <~ objectsSignal.signal.flatten(.Latest)
    changeSignal = objects.signal.combinePrevious([]).map { old, new in
      let rowsToRemove = old.filter {
        return !new.contains($0)
      }.map {
        return NSIndexPath(index: 0).indexPathByAddingIndex(old.indexOf($0)!)
      }
      let rowsToInsert = new.filter {
        return !old.contains($0)
      }.map {
        return NSIndexPath(index: 0).indexPathByAddingIndex(new.indexOf($0)!)
      }
      return (rowsToRemove, rowsToInsert)
    }
  }
}