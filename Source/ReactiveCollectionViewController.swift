//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

public enum CollectionInit {
  case Coder(coder: NSCoder)
  case Layout(layout: UICollectionViewLayout)
}

public class ReactiveCollectionViewController<Cell where Cell:UICollectionViewCell, Cell:ReactiveListCell>
    : UICollectionViewController, ReactiveList {

  public typealias ListCell = Cell
  public typealias Element = Cell.Item

  public var animateChanges = true

  public let didSelectItemSignal: Signal<(Element, NSIndexPath), Result.NoError>

  private let changeObserver = ChangeObserver<Element>()
  private let didSelectItemPipe: Observer<(Element, NSIndexPath), Result.NoError>

  public required convenience init?(coder aDecoder: NSCoder) {
    self.init(.Coder(coder: aDecoder))
  }

  public override convenience init(collectionViewLayout layout: UICollectionViewLayout) {
    self.init(.Layout(layout: layout))
  }

  // Don't use this, use one of the above convenience inits
  public required init(_ method: CollectionInit) {
    (didSelectItemSignal, didSelectItemPipe) = Signal.pipe()
    switch method {
      case .Coder(let coder):
        super.init(coder: coder)!
      case .Layout(let layout):
        super.init(collectionViewLayout: layout)
    }
    collectionView!.registerClass(Cell.self, forCellWithReuseIdentifier: "Cell")
  }

  public func bindToProducer(producer: SignalProducer<[Element], Result.NoError>) {
    changeObserver.bindToProducer(producer)
  }

  public func indexPathForObject(object: Element) -> NSIndexPath {
    return NSIndexPath(forRow: changeObserver.objects.value.indexOf(object)!, inSection: 0)
  }

  public func objectForIndexPath(indexPath: NSIndexPath) -> Element {
    return changeObserver.objects.value[indexPath.row]
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    changeObserver.changeSignal.observeNext{ [unowned self] (rowsToRemove, rowsToInsert) in
      var onlyOrderChanged = (rowsToRemove.count == 0) && (rowsToInsert.count == 0)
      if self.animateChanges == true && onlyOrderChanged == false {
        self.collectionView!.performBatchUpdates({
          self.collectionView!.deleteItemsAtIndexPaths(rowsToRemove)
          self.collectionView!.insertItemsAtIndexPaths(rowsToInsert)
        }, completion: nil)
      }
      else {
        self.collectionView!.reloadData()
      }
    }
  }

  override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }

  override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
      -> UICollectionViewCell {
    var object = objectForIndexPath(indexPath)
    var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
    guard var rxCell = cell as? Cell else {
      fatalError("Dequeued reusable cell that could not be cast to the Cell associated type")
      return cell
    }
    rxCell.object = object
    prepareCell(rxCell, indexPath: indexPath)
    return rxCell
  }

  override public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    didSelectItemPipe.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public func prepareCell(cell: Cell, indexPath: NSIndexPath) {
    // Default implementation is empty
  }
}
