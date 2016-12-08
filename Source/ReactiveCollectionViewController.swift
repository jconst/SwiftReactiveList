//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

open class ReactiveCollectionViewController<Cell>
    : UICollectionViewController where Cell:UICollectionViewCell, Cell:ReactiveListCell {

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

  required public init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

  public func bindToProducer(_ producer: SignalProducer<[Element], Result.NoError>) {
    changeObserver.bindToProducer(producer)
  }

  public func bindToSignal(_ signal: Signal<[Element], Result.NoError>) {
    changeObserver.bindToProducer(SignalProducer(signal: signal))
  }

  public func indexPathForObject(_ object: Element) -> IndexPath {
    return IndexPath(forRow: changeObserver.objects.value.indexOf(object)!, inSection: 0)
  }

  public func objectForIndexPath(_ indexPath: IndexPath) -> Element {
    return changeObserver.objects.value[indexPath.row]
  }

  open override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
      -> UICollectionViewCell {
    let object = objectForIndexPath(indexPath)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    guard var rxCell = cell as? Cell else {
      fatalError("Dequeued reusable cell that could not be cast to the Cell associated type")
      return cell
    }
    rxCell.object = object
    prepareCell(rxCell, indexPath: indexPath)
    return rxCell
  }

  open func prepareCell(_ cell: Cell, indexPath: IndexPath) {
    // can be overridden by subclasses
  }

  open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    selectItem.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  open override func collectionView(_ collectionView: UICollectionView, moveItemAt src: IndexPath,
      to dst: IndexPath) {
    moveItem.sendNext((src, dst))
  }
}
