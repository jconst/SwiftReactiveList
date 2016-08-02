//  Created by Joseph Constantakis on 6/27/16.

public protocol ReactiveListCell {
  associatedtype Item: Equatable
  var object: Item? { get set }
}
