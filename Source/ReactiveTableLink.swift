//  Created by Joseph Constantakis on 6/28/16.

import MultiDelegate
import ReactiveCocoa
import enum Result.NoError

public class ReactiveTableLink<Cell where Cell:UITableViewCell, Cell:ReactiveListCell>
    : NSObject, UITableViewDataSource, UITableViewDelegate {

  public typealias Element = Cell.Item
  public typealias PrepareCellBlock = ((Cell, NSIndexPath) -> Void)

  public var animateChanges = true
  public var insertAnimation: UITableViewRowAnimation = .Automatic
  public var deleteAnimation: UITableViewRowAnimation = .Automatic

  public let didSelectItemSignal: Signal<(Element, NSIndexPath), Result.NoError>
  public let didTapAccessorySignal: Signal<(Element, NSIndexPath), Result.NoError>
  public let didDeleteItemSignal: Signal<(Element, NSIndexPath), Result.NoError>

  private let changeObserver = ChangeObserver<Element>()
  private var prepareCell: PrepareCellBlock?
  private let didSelectItemPipe: Observer<(Element, NSIndexPath), Result.NoError>
  private let didTapAccessoryPipe: Observer<(Element, NSIndexPath), Result.NoError>
  private let didDeleteItemPipe: Observer<(Element, NSIndexPath), Result.NoError>

  public var dataSource: UITableViewDataSource? { didSet{
    multiDelegate.addDelegate(dataSource)
  }}
  public var delegate: UITableViewDelegate? { didSet{
    multiDelegate.addDelegate(delegate)
  }}
  private var multiDelegate: AIMultiDelegate {
    return AIMultiDelegate(delegates: [self])
  }

  public init(tableView: UITableView) {
    (didSelectItemSignal, didSelectItemPipe) = Signal.pipe()
    (didTapAccessorySignal, didTapAccessoryPipe) = Signal.pipe()
    (didDeleteItemSignal, didDeleteItemPipe) = Signal.pipe()
    super.init()

    tableView.setValue(multiDelegate, forKey: "delegate")
    tableView.setValue(multiDelegate, forKey: "dataSource")

    tableView.registerClass(Cell.self, forCellReuseIdentifier: "Cell")
    self.changeObserver.changeSignal.observeNext{ [unowned self](rowsToRemove, rowsToInsert) in
      var onlyOrderChanged = (rowsToRemove.count == 0) && (rowsToInsert.count == 0)
      if self.animateChanges == true && onlyOrderChanged == false {
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths(rowsToRemove, withRowAnimation: self.deleteAnimation)
        tableView.insertRowsAtIndexPaths(rowsToInsert, withRowAnimation: self.insertAnimation)
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
    didSelectItemPipe.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
    didTapAccessoryPipe.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
      forRowAtIndexPath indexPath: NSIndexPath) {
    if (editingStyle == .Delete) {
      didDeleteItemPipe.sendNext((objectForIndexPath(indexPath), indexPath))
    }
  }
}
