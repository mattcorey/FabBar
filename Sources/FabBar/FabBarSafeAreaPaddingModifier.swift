#if os(iOS)

import SwiftUI

@available(iOS 26.0, *)
public extension View {
    /// No longer needed because ``fabBar(selection:tabs:action:isVisible:isActionVisible:)``
    /// automatically adjusts scrollable content margins.
    @available(
        *,
        deprecated,
        message: "FabBar now manages scrollable content margins automatically."
    )
    func fabBarSafeAreaPadding() -> some View {
        self
    }
}

#endif
