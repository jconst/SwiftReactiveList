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

  public func subscribeCollectionView(collectionView: UICollectionView, cellClass: AnyClass, animate: Bool) {
    collectionView.registerClass(cellClass, forCellWithReuseIdentifier: "Cell")
    changeSignal.startWithNext{ [unowned self] (rowsToRemove, rowsToInsert) in
      let onlyOrderChanged = (rowsToRemove.count == 0) && (rowsToInsert.count == 0)
      if animate && !onlyOrderChanged {
        collectionView.performBatchUpdates({
          collectionView.deleteItemsAtIndexPaths(rowsToRemove.map(indexPathWithRow))
          collectionView.insertItemsAtIndexPaths(rowsToInsert.map(indexPathWithRow))
        }, completion: nil)
      }
      else {
        collectionView.reloadData()
      }
    }
  }

  public func subscribeTableView(tableView: UITableView, cellClass: AnyClass, animate: Bool) {
    tableView.registerClass(cellClass, forCellReuseIdentifier: "Cell")
    changeSignal.startWithNext{ [unowned self](rowsToRemove, rowsToInsert) in
      let onlyOrderChanged = (rowsToRemove.count == 0) && (rowsToInsert.count == 0)
      if animate && !onlyOrderChanged {
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths(rowsToRemove.map(indexPathWithRow), withRowAnimation: .Automatic)
        tableView.insertRowsAtIndexPaths(rowsToInsert.map(indexPathWithRow), withRowAnimation: .Automatic)
        tableView.endUpdates()
      }
      else {
        tableView.reloadData()
      }
    }
  }
}

public func diffArrays<Elt: Equatable>(old: [Elt], _ new: [Elt]) -> (remove: [Int], insert: [Int]) {
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

func indexPathWithRow(row: Int) -> NSIndexPath {
  return NSIndexPath(index: 0).indexPathByAddingIndex(row)
}
