//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

class ReactiveCollectionViewController<Cell: EPSReactiveListCell>
    : UICollectionViewController, EPSReactiveList {

  typealias Element = Cell.Item

  public var didSelectItemSignal: Signal<(Element, NSIndexPath), Result.NoError>
  public var animateChanges: Bool

  private var changeObserver: ChangeObserver<Element>
  private var didSelectItemPipe: Observer<(Element, NSIndexPath), Result.NoError>

  override init(collectionViewLayout layout: UICollectionViewLayout) {
    animateChanges = true
    changeObserver = ChangeObserver()
    (didSelectItemSignal, didSelectItemPipe) = Signal.pipe()
    super.init(collectionViewLayout: layout)
  }

  func setBindingToSignal(signal: Signal<[Element], Result.NoError>) {
    changeObserver.setBindingToSignal(signal)
  }

  func indexPathForObject(object: Element) -> NSIndexPath {
    return NSIndexPath(forRow: changeObserver.objects.value.indexOf(object)!, inSection: 0)
  }

  func objectForIndexPath(indexPath: NSIndexPath) -> Element {
    return changeObserver.objects.value[indexPath.row]
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.changeObserver.changeSignal.observeNext { [unowned self](rowsToRemove, rowsToInsert) in
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

  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }

  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
      -> UICollectionViewCell {
    var object = objectForIndexPath(indexPath)
    var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
    guard var rxCell = cell as? Cell else {
      print("Error: cell type does not conform to EPSReactiveListCell")
      return cell
    }
    rxCell.object = object
    return rxCell as! UICollectionViewCell
  }

  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    didSelectItemPipe.sendNext((objectForIndexPath(indexPath), indexPath))
  }
}
