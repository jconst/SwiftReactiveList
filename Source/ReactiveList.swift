//  Created by Joseph Constantakis on 6/27/16.

import ReactiveCocoa
import enum Result.NoError

public protocol ReactiveListCell {
  associatedtype Item: Equatable
  var object: Item { get set }
}

public protocol ReactiveList {
  associatedtype Element: Equatable

  /// When a new array is sent on the signal, the array is diffed with the previous
  /// array of elements, and the differences will be applied to the list, using insertion
  /// and deletion animations if desired.
  func setBindingToSignal(signal: Signal<[Element], Result.NoError>)

  /// Whether insertions and deletions to the table/collection are animated
  /// default is true
  var animateChanges: Bool { get set }

  func indexPathForObject(object: Element) -> NSIndexPath
  func objectForIndexPath(indexPath: NSIndexPath) -> Element
}
