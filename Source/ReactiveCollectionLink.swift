//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

public class ReactiveCollectionLink<Cell where Cell:UICollectionViewCell, Cell:ReactiveListCell>
    : NSObject, UICollectionViewDataSource, UICollectionViewDelegate {

  public typealias Element = Cell.Item
  public typealias PrepareCellBlock = ((Cell, NSIndexPath) -> Void)

  public var animateChanges = true
  public let didSelectItem: Signal<(Element, NSIndexPath), Result.NoError>
  public let didMoveItem: Signal<(NSIndexPath, NSIndexPath), Result.NoError>

  private var prepareCell: PrepareCellBlock?
  private let changeObserver = ChangeObserver<Element>()
  private let selectItem: Observer<(Element, NSIndexPath), Result.NoError>
  private let moveItem: Observer<(NSIndexPath, NSIndexPath), Result.NoError>

  public init(collectionView: UICollectionView) {
    (didSelectItem, selectItem) = Signal.pipe()
    (didMoveItem, moveItem) = Signal.pipe()
    super.init()
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.registerClass(Cell.self, forCellWithReuseIdentifier: "Cell")
    changeObserver.changeSignal.startWithNext{ [unowned self] (rowsToRemove, rowsToInsert) in
      var onlyOrderChanged = (rowsToRemove.count == 0) && (rowsToInsert.count == 0)
      if self.animateChanges == true && onlyOrderChanged == false {
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

  public func bindToProducer(producer: SignalProducer<[Element], Result.NoError>) {
    changeObserver.bindToProducer(producer)
  }

  public func bindToSignal(signal: Signal<[Element], Result.NoError>) {
    changeObserver.bindToProducer(SignalProducer(signal: signal))
  }

  public func onPrepareCell(block: PrepareCellBlock) {
    prepareCell = block
  }

  public func indexPathForObject(object: Element) -> NSIndexPath {
    return NSIndexPath(forRow: changeObserver.objects.value.indexOf(object)!, inSection: 0)
  }

  public func objectForIndexPath(indexPath: NSIndexPath) -> Element {
    return changeObserver.objects.value[indexPath.row]
  }

  public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }

  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
      -> UICollectionViewCell {
    var object = objectForIndexPath(indexPath)
    var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
    guard var rxCell = cell as? Cell else {
      fatalError("Dequeued reusable cell that could not be cast to the Cell associated type")
      return cell
    }
    rxCell.object = object
    prepareCell?(rxCell, indexPath)
    return rxCell
  }

  public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    selectItem.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  // MARK: Delegate pass-throughs
  public func collectionView(collectionView: UICollectionView, moveItemAtIndexPath src: NSIndexPath,
      toIndexPath dst: NSIndexPath) {
    moveItem.sendNext((src, dst))
  }
}
