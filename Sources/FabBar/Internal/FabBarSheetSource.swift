import SwiftUI
import UIKit

@available(iOS 26.0, *)
@MainActor
protocol FabBarSheetSourceObserver: AnyObject {
    func fabBarSheetSourceDidChange(_ source: FabBarSheetSource)
}

/// Stable bridge between the SwiftUI presentation modifier and UIKit FAB.
@available(iOS 26.0, *)
@MainActor
final class FabBarSheetSource {
    weak var observer: (any FabBarSheetSourceObserver)?

    weak var view: UIView? {
        didSet {
            guard oldValue !== view else { return }
            observer?.fabBarSheetSourceDidChange(self)
        }
    }
}

@available(iOS 26.0, *)
extension EnvironmentValues {
    @Entry var fabBarSheetSource: FabBarSheetSource?
}
