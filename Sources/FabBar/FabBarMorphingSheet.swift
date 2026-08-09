#if os(iOS)

import SwiftUI

@available(iOS 26.0, *)
public extension View {
    /// Presents SwiftUI content in a sheet that morphs from the FabBar action.
    ///
    /// Apply this modifier after `fabBar(...)`. Apps that prefer a standard
    /// sheet can omit this modifier and continue using SwiftUI's `sheet`
    /// modifiers.
    func fabBarMorphingSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        configuration: FabBarSheetConfiguration = FabBarSheetConfiguration(),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            FabBarMorphingBooleanSheetModifier(
                isPresented: isPresented,
                configuration: configuration,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }

    /// Presents identifiable SwiftUI content in a sheet that morphs from the
    /// FabBar action.
    ///
    /// Apply this modifier after `fabBar(...)`. Setting `item` to a value
    /// presents the sheet; dismissing it resets the binding to `nil`.
    func fabBarMorphingSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        configuration: FabBarSheetConfiguration = FabBarSheetConfiguration(),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(
            FabBarMorphingItemSheetModifier(
                item: item,
                configuration: configuration,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }
}

#endif
