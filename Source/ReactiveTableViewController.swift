//  Created by Joseph Constantakis on 6/28/16.

import ReactiveCocoa
import enum Result.NoError

class ReactiveTableViewController<Cell: EPSReactiveListCell>
    : UITableViewController, EPSReactiveList {

  typealias Element = Cell.Item

  public var didSelectItemSignal: Signal<(Element, NSIndexPath), Result.NoError>
  public var didTapAccessorySignal: Signal<(Element, NSIndexPath), Result.NoError>
  public var didDeleteItemSignal: Signal<(Element, NSIndexPath), Result.NoError>
  public var animateChanges: Bool

  public var insertAnimation: UITableViewRowAnimation = .Automatic
  public var deleteAnimation: UITableViewRowAnimation = .Automatic

  private var changeObserver: ChangeObserver<Element>
  private var didSelectItemPipe: Observer<(Element, NSIndexPath), Result.NoError>
  private var didTapAccessoryPipe: Observer<(Element, NSIndexPath), Result.NoError>
  private var didDeleteItemPipe: Observer<(Element, NSIndexPath), Result.NoError>

  required init?(coder aDecoder: NSCoder) {
    animateChanges = true
    changeObserver = ChangeObserver()
    (didSelectItemSignal, didSelectItemPipe) = Signal.pipe()
    (didTapAccessorySignal, didTapAccessoryPipe) = Signal.pipe()
    (didDeleteItemSignal, didDeleteItemPipe) = Signal.pipe()
    super.init(coder: aDecoder)
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
        self.tableView!.beginUpdates()
        self.tableView!.deleteRowsAtIndexPaths(rowsToRemove, withRowAnimation: self.deleteAnimation)
        self.tableView!.insertRowsAtIndexPaths(rowsToInsert, withRowAnimation: self.insertAnimation)
        self.tableView!.endUpdates()
      }
      else {
        self.tableView!.reloadData()
      }
    }
  }

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var object = objectForIndexPath(indexPath)
    var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    guard var rxCell = cell as? Cell else {
      print("Error: cell type does not conform to EPSReactiveListCell")
      return cell
    }
    rxCell.object = object
    return rxCell as! UITableViewCell
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    didSelectItemPipe.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
    didTapAccessoryPipe.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
      forRowAtIndexPath indexPath: NSIndexPath) {
    if (editingStyle == .Delete) {
      didDeleteItemPipe.sendNext((objectForIndexPath(indexPath), indexPath))
    }
  }
}
