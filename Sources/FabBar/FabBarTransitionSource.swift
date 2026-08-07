import SwiftUI

/// Identifies the floating action button as the source of a matched zoom
/// transition, such as a sheet presentation.
@available(iOS 26.0, *)
public struct FabBarTransitionSource {
    let id: AnyHashable
    let namespace: Namespace.ID

    public init<ID: Hashable>(id: ID, in namespace: Namespace.ID) {
        self.id = AnyHashable(id)
        self.namespace = namespace
    }
}
