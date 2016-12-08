//  Created by Joseph Constantakis on 6/28/16.

import ReactiveCocoa
import enum Result.NoError

open class ReactiveTableViewController<Cell>
    : UITableViewController where Cell:UITableViewCell, Cell:ReactiveListCell {

  public typealias Element = Cell.Item

  public let didSelectItem: Signal<(Element, NSIndexPath), Result.NoError>
  public let didTapAccessory: Signal<(Element, NSIndexPath), Result.NoError>
  public let didDeleteItem: Signal<(Element, NSIndexPath), Result.NoError>
  public let changeObserver = ChangeObserver<Element>()

  private let selectItem: Observer<(Element, NSIndexPath), Result.NoError>
  private let tapAccessory: Observer<(Element, NSIndexPath), Result.NoError>
  private let deleteItem: Observer<(Element, NSIndexPath), Result.NoError>

  // Don't use this, use one of the above convenience inits
  public init(animateChanges: Bool) {
    (didSelectItem, selectItem) = Signal.pipe()
    (didTapAccessory, tapAccessory) = Signal.pipe()
    (didDeleteItem, deleteItem) = Signal.pipe()
    super.init(style: .plain)
    changeObserver.subscribeTableView(tableView, cellClass: Cell.self, animate: animateChanges)
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

  open override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return changeObserver.objects.value.count
  }

  open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
      -> UITableViewCell {
    let object = objectForIndexPath(indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
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

  open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectItem.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  open override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    tapAccessory.sendNext((objectForIndexPath(indexPath), indexPath))
  }

  open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
      forRowAt indexPath: IndexPath) {
    if (editingStyle == .delete) {
      deleteItem.sendNext((objectForIndexPath(indexPath), indexPath))
    }
  }
}
