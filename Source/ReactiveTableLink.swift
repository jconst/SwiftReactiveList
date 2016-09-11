//  Created by Joseph Constantakis on 6/28/16.

import ReactiveCocoa
import enum Result.NoError

public class ReactiveTableLink<Cell where Cell:UITableViewCell, Cell:ReactiveListCell>
    : NSObject, UITableViewDataSource, UITableViewDelegate {

  public typealias Element = Cell.Item
  public typealias PrepareCellBlock = ((Cell, NSIndexPath) -> Void)

  public var animateChanges = true
  public var insertAnimation: UITableViewRowAnimation = .Automatic
  public var deleteAnimation: UITableViewRowAnimation = .Automatic

  public let didSelectItem: Signal<(Element, NSIndexPath), Result.NoError>
  public let didTapAccessory: Signal<(Element, NSIndexPath), Result.NoError>
  public let didDeleteItem: Signal<(Element, NSIndexPath), Result.NoError>

  private let changeObserver = ChangeObserver<Element>()
  private var prepareCell: PrepareCellBlock?
  private let selectItem: Observer<(Element, NSIndexPath), Result.NoError>
  private let tapAccessory: Observer<(Element, NSIndexPath), Result.NoError>
  private let deleteItem: Observer<(Element, NSIndexPath), Result.NoError>

  // Don't use this, use one of the above convenience inits
  public init(tableView: UITableView) {
    (didSelectItem, selectItem) = Signal.pipe()
    (didTapAccessory, tapAccessory) = Signal.pipe()
    (didDeleteItem, deleteItem) = Signal.pipe()
    super.init()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.registerClass(Cell.self, forCellReuseIdentifier: "Cell")
    self.changeObserver.changeSignal.startWithNext{ [unowned self](rowsToRemove, rowsToInsert) in
      var onlyOrderChanged = (rowsToRemove.count == 0) && (rowsToInsert.count == 0)
      if self.animateChanges == true && onlyOrderChanged == false {
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths(rowsToRemove.map(indexPathWithRow), withRowAnimation: self.deleteAnimation)
        tableView.insertRowsAtIndexPaths(rowsToInsert.map(indexPathWithRow), withRowAnimation: self.insertAnimation)
        tableView.endUpdates()
      }
      else {
        tableView.reloadData()
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

  public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var object = objectForIndexPath(indexPath)
    var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    guard var rxCell = cell as? Cell else {
      fatalError("Dequeued reusable cell that could not be cast to the Cell associated type")
      return cell
    }
    rxCell.object = object
    prepareCell?(rxCell, indexPath)
    return rxCell
  }

  public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    selectItem.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
    tapAccessory.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
      forRowAtIndexPath indexPath: NSIndexPath) {
    if (editingStyle == .Delete) {
      deleteItem.sendNext((objectForIndexPath(indexPath), indexPath))
    }
  }
}
