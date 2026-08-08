import SwiftUI

/// The current placement of a FabBar bottom accessory.
@available(iOS 26.0, *)
public enum FabBarBottomAccessoryPlacement: Equatable, Sendable {
    /// The accessory is displayed above the expanded FabBar.
    case expanded

    /// The accessory is displayed inline between the minimized controls.
    case inline
}

@available(iOS 26.0, *)
public extension EnvironmentValues {
    /// The current placement of a FabBar bottom accessory.
    ///
    /// A `nil` value means that the view isn't currently hosted as a FabBar
    /// bottom accessory.
    @Entry var fabBarBottomAccessoryPlacement: FabBarBottomAccessoryPlacement?

    /// The target width available to an inline FabBar bottom accessory.
    ///
    /// The value is `nil` while the accessory is expanded or when the view
    /// isn't hosted as a FabBar bottom accessory.
    @Entry var fabBarBottomAccessoryWidth: CGFloat?
}
