//  Created by Joseph Constantakis on 6/28/16.

import ReactiveCocoa
import enum Result.NoError

public enum TableInit {
  case Coder(coder: NSCoder)
  case Style(style: UITableViewStyle)
}

public class ReactiveTableViewController<Cell where Cell:UITableViewCell, Cell:ReactiveListCell>
    : UITableViewController, ReactiveList {

  public typealias ListCell = Cell
  public typealias Element = Cell.Item

  public var animateChanges = true
  public var insertAnimation: UITableViewRowAnimation = .Automatic
  public var deleteAnimation: UITableViewRowAnimation = .Automatic

  public let didSelectItemSignal: Signal<(Element, NSIndexPath), Result.NoError>
  public let didTapAccessorySignal: Signal<(Element, NSIndexPath), Result.NoError>
  public let didDeleteItemSignal: Signal<(Element, NSIndexPath), Result.NoError>

  private let changeObserver = ChangeObserver<Element>()
  private let didSelectItemPipe: Observer<(Element, NSIndexPath), Result.NoError>
  private let didTapAccessoryPipe: Observer<(Element, NSIndexPath), Result.NoError>
  private let didDeleteItemPipe: Observer<(Element, NSIndexPath), Result.NoError>

  public required convenience init?(coder aDecoder: NSCoder) {
    self.init(.Coder(coder: aDecoder))
  }

  public override convenience init(style: UITableViewStyle) {
    self.init(.Style(style: style))
  }

  // Don't use this, use one of the above convenience inits
  public required init(_ method: TableInit) {
    (didSelectItemSignal, didSelectItemPipe) = Signal.pipe()
    (didTapAccessorySignal, didTapAccessoryPipe) = Signal.pipe()
    (didDeleteItemSignal, didDeleteItemPipe) = Signal.pipe()
    switch method {
      case .Coder(let coder):
        super.init(coder: coder)!
      case .Style(let style):
        super.init(style: style)
    }
    tableView!.registerClass(Cell.self, forCellReuseIdentifier: "Cell")
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
    self.changeObserver.changeSignal.observeNext{ [unowned self](rowsToRemove, rowsToInsert) in
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

  override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var object = objectForIndexPath(indexPath)
    var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    guard var rxCell = cell as? Cell else {
      fatalError("Dequeued reusable cell that could not be cast to the Cell associated type")
      return cell
    }
    rxCell.object = object
    prepareCell(rxCell, indexPath: indexPath)
    return rxCell
  }

  override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    didSelectItemPipe.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  override public func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
    didTapAccessoryPipe.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  override public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
      forRowAtIndexPath indexPath: NSIndexPath) {
    if (editingStyle == .Delete) {
      didDeleteItemPipe.sendNext((objectForIndexPath(indexPath), indexPath))
    }
  }

  public func prepareCell(cell: Cell, indexPath: NSIndexPath) {
    // Default implementation is empty
  }
}
