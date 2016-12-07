//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

public class ReactiveCollectionViewController<Cell where Cell:UICollectionViewCell, Cell:ReactiveListCell>
    : UICollectionViewController {

  public typealias Element = Cell.Item

  public let didSelectItem: Signal<(Element, NSIndexPath), Result.NoError>
  public let didMoveItem: Signal<(NSIndexPath, NSIndexPath), Result.NoError>
  public let changeObserver = ChangeObserver<Element>()

  private let selectItem: Observer<(Element, NSIndexPath), Result.NoError>
  private let moveItem: Observer<(NSIndexPath, NSIndexPath), Result.NoError>

  public init(collectionViewLayout layout: UICollectionViewLayout, animateChanges: Bool) {
    (didSelectItem, selectItem) = Signal.pipe()
    (didMoveItem, moveItem) = Signal.pipe()
    super.init(collectionViewLayout: layout)
    changeObserver.subscribeCollectionView(collectionView!, cellClass: Cell.self, animate: animateChanges)
  }

  public func bindToProducer(producer: SignalProducer<[Element], Result.NoError>) {
    changeObserver.bindToProducer(producer)
  }

  public func bindToSignal(signal: Signal<[Element], Result.NoError>) {
    changeObserver.bindToProducer(SignalProducer(signal: signal))
  }

  public func indexPathForObject(object: Element) -> NSIndexPath {
    return NSIndexPath(forRow: changeObserver.objects.value.indexOf(object)!, inSection: 0)
  }

  public func objectForIndexPath(indexPath: NSIndexPath) -> Element {
    return changeObserver.objects.value[indexPath.row]
  }

  public override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }

  public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
      -> UICollectionViewCell {
    let object = objectForIndexPath(indexPath)
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
    guard var rxCell = cell as? Cell else {
      fatalError("Dequeued reusable cell that could not be cast to the Cell associated type")
      return cell
    }
    rxCell.object = object
    prepareCell(rxCell, indexPath: indexPath)
    return rxCell
  }

  public func prepareCell(cell: Cell, indexPath: NSIndexPath) {
    // can be overridden by subclasses
  }

  public override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    selectItem.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public override func collectionView(collectionView: UICollectionView, moveItemAtIndexPath src: NSIndexPath,
      toIndexPath dst: NSIndexPath) {
    moveItem.sendNext((src, dst))
  }
}
