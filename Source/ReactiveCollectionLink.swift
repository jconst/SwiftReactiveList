//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

public class ReactiveCollectionLink<Cell>
    : NSObject, UICollectionViewDataSource, UICollectionViewDelegate where Cell:UICollectionViewCell, Cell:ReactiveListCell {

  public typealias Element = Cell.Item
  public typealias PrepareCellBlock = ((Cell, IndexPath) -> Void)

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
    collectionView.register(Cell.self, forCellWithReuseIdentifier: "Cell")
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

  public func bindToProducer(_ producer: SignalProducer<[Element], Result.NoError>) {
    changeObserver.bindToProducer(producer)
  }

  public func bindToSignal(_ signal: Signal<[Element], Result.NoError>) {
    changeObserver.bindToProducer(SignalProducer(signal: signal))
  }

  public func onPrepareCell(_ block: @escaping PrepareCellBlock) {
    prepareCell = block
  }

  public func indexPathForObject(_ object: Element) -> IndexPath {
    return IndexPath(forRow: changeObserver.objects.value.indexOf(object)!, inSection: 0)
  }

  public func objectForIndexPath(_ indexPath: IndexPath) -> Element {
    return changeObserver.objects.value[indexPath.row]
  }

  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
      -> UICollectionViewCell {
    let object = objectForIndexPath(indexPath)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    guard var rxCell = cell as? Cell else {
      fatalError("Dequeued reusable cell that could not be cast to the Cell associated type")
      return cell
    }
    rxCell.object = object
    prepareCell?(rxCell, indexPath)
    return rxCell
  }

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    selectItem.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  // MARK: Delegate pass-throughs
  public func collectionView(_ collectionView: UICollectionView, moveItemAt src: IndexPath,
      to dst: IndexPath) {
    moveItem.sendNext((src, dst))
  }
}
