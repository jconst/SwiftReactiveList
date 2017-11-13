//  Created by Joseph Constantakis on 6/28/16.

import ReactiveSwift
import enum Result.NoError

open class ReactiveTableViewController<Cell>
    : UITableViewController where Cell:UITableViewCell, Cell:ReactiveListCell {

  public typealias Element = Cell.Item

  public let didSelectItem: Signal<(Element, IndexPath), Result.NoError>
  public let didTapAccessory: Signal<(Element, IndexPath), Result.NoError>
  public let didDeleteItem: Signal<(Element, IndexPath), Result.NoError>
  public let changeObserver = ChangeObserver<Element>()

  private let selectItem: Signal<(Element, IndexPath), Result.NoError>.Observer
  private let tapAccessory: Signal<(Element, IndexPath), Result.NoError>.Observer
  private let deleteItem: Signal<(Element, IndexPath), Result.NoError>.Observer

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
    changeObserver.bind(to: producer)
  }

  public func bindToSignal(_ signal: Signal<[Element], Result.NoError>) {
    changeObserver.bind(to: SignalProducer(signal))
  }

  public func indexPathForObject(_ object: Element) -> IndexPath {
    return IndexPath(row: changeObserver.objects.value.index(of: object)!, section: 0)
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
    selectItem.send(value: (objectForIndexPath(indexPath), indexPath))
  }

  open override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    tapAccessory.send(value: (objectForIndexPath(indexPath), indexPath))
  }

  open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
      forRowAt indexPath: IndexPath) {
    if (editingStyle == .delete) {
      deleteItem.send(value: (objectForIndexPath(indexPath), indexPath))
    }
  }
}
