//  Created by Joseph Constantakis on 6/27/16.

import ReactiveSwift
import enum Result.NoError

typealias NoError = Result.NoError

public class ChangeObserver<T: Equatable> {
  public let changeSignal: SignalProducer<([Int], [Int]), Result.NoError>
  public let objects = MutableProperty([T]())

  private let objectsSignal: MutableProperty<SignalProducer<[T], NoError>> = MutableProperty(SignalProducer.empty)

  public func bind(to producer: SignalProducer<[T], Result.NoError>) {
    objectsSignal.value = producer
  }

  public init() {
    objects <~ objectsSignal.producer.flatten(.latest)
    changeSignal = objects.producer.combinePrevious([]).map(diffArrays)
  }

  public func subscribeCollectionView(_ collectionView: UICollectionView, cellClass: AnyClass, animate: Bool) {
    collectionView.register(cellClass, forCellWithReuseIdentifier: "Cell")
    changeSignal.startWithValues{ [unowned self] (_, _) in
      collectionView.reloadData()
    }
//    changeSignal.skip(2).startWithNext{ [unowned self] (rowsToRemove, rowsToInsert) in
//      let onlyOrderChanged = (rowsToRemove.count == 0) && (rowsToInsert.count == 0)
//      if animate && !onlyOrderChanged {
//        collectionView.performBatchUpdates({
//          collectionView.deleteItemsAtIndexPaths(rowsToRemove.map(indexPathWithRow))
//          collectionView.insertItemsAtIndexPaths(rowsToInsert.map(indexPathWithRow))
//        }, completion: nil)
//      } else {
//        collectionView.reloadData()
//      }
//    }
  }

  public func subscribeTableView(_ tableView: UITableView, cellClass: AnyClass, animate: Bool) {
    tableView.register(cellClass, forCellReuseIdentifier: "Cell")
    changeSignal.startWithValues{ [unowned self](rowsToRemove, rowsToInsert) in
      let onlyOrderChanged = (rowsToRemove.count == 0) && (rowsToInsert.count == 0)
      if animate && !onlyOrderChanged {
        tableView.beginUpdates()
        tableView.deleteRows(at: rowsToRemove.map(indexPath), with: .automatic)
        tableView.insertRows(at: rowsToInsert.map(indexPath), with: .automatic)
        tableView.endUpdates()
      }
      else {
        tableView.reloadData()
      }
    }
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

func indexPath(row: Int) -> IndexPath {
  return IndexPath(row: row, section: 0)
}
