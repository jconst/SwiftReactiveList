//  Created by Joseph Constantakis on 6/28/16.

import ReactiveCocoa
import enum Result.NoError

public class ReactiveTableViewController<Cell where Cell:UITableViewCell, Cell:ReactiveListCell>
    : UITableViewController {

  public typealias Element = Cell.Item

  public let didSelectItem: Signal<(Element, NSIndexPath), Result.NoError>
  public let didTapAccessory: Signal<(Element, NSIndexPath), Result.NoError>
  public let didDeleteItem: Signal<(Element, NSIndexPath), Result.NoError>

  private let changeObserver = ChangeObserver<Element>()
  private let selectItem: Observer<(Element, NSIndexPath), Result.NoError>
  private let tapAccessory: Observer<(Element, NSIndexPath), Result.NoError>
  private let deleteItem: Observer<(Element, NSIndexPath), Result.NoError>

  // Don't use this, use one of the above convenience inits
  public init(animateChanges: Bool) {
    (didSelectItem, selectItem) = Signal.pipe()
    (didTapAccessory, tapAccessory) = Signal.pipe()
    (didDeleteItem, deleteItem) = Signal.pipe()
    super.init(style: .Plain)
    changeObserver.subscribeTableView(tableView, cellClass: Cell.self, animate: animateChanges)
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

  public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
      -> UITableViewCell {
    let object = objectForIndexPath(indexPath)
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
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

  public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    selectItem.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
    tapAccessory.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
      forRowAtIndexPath indexPath: NSIndexPath) {
    if (editingStyle == .Delete) {
      deleteItem.sendNext((objectForIndexPath(indexPath), indexPath))
    }
  }
}
