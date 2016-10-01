//  Created by Joseph Constantakis on 6/28/16.

import ReactiveCocoa
import enum Result.NoError

public class ReactiveTableLink<Cell>
    : NSObject, UITableViewDataSource, UITableViewDelegate where Cell:UITableViewCell, Cell:ReactiveListCell {

  public typealias Element = Cell.Item
  public typealias PrepareCellBlock = ((Cell, IndexPath) -> Void)

  public var animateChanges = true
  public var insertAnimation: UITableViewRowAnimation = .automatic
  public var deleteAnimation: UITableViewRowAnimation = .automatic

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
    tableView.register(Cell.self, forCellReuseIdentifier: "Cell")
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

  public func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let object = objectForIndexPath(indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    guard var rxCell = cell as? Cell else {
      fatalError("Dequeued reusable cell that could not be cast to the Cell associated type")
      return cell
    }
    rxCell.object = object
    prepareCell?(rxCell, indexPath)
    return rxCell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectItem.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    tapAccessory.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
      forRowAt indexPath: IndexPath) {
    if (editingStyle == .delete) {
      deleteItem.sendNext((objectForIndexPath(indexPath), indexPath))
    }
  }
}
