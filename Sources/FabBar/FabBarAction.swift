import Foundation

/// Configuration for the floating action button (FAB) in FabBar.
///
/// The FAB appears as a circular glass button next to the tab items,
/// morphing with the iOS 26 glass effect.
@available(iOS 26.0, *)
public struct FabBarAction {
    /// The SF Symbol name for the button icon.
    public let systemImage: String

    /// The accessibility label for VoiceOver users.
    public let accessibilityLabel: String

    /// An optional accessibility identifier for UI testing.
    public let accessibilityIdentifier: String?

    /// Menu items displayed when the button is held.
    ///
    /// An empty array preserves the original action-only behavior.
    public let menuItems: [FabBarMenuItem]

    /// An optional matched transition source for presentations originating
    /// from the floating action button.
    public let transitionSource: FabBarTransitionSource?

    /// The action to perform when the button is tapped.
    public let action: () -> Void

    /// Creates a floating action button configuration.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol name for the button icon.
    ///   - accessibilityLabel: The accessibility label for VoiceOver users.
    ///   - accessibilityIdentifier: An optional identifier for UI testing.
    ///   - menuItems: Items displayed when the button is held. Defaults to an
    ///     empty array, which keeps the action-only behavior.
    ///   - transitionSource: An optional matched transition source used by
    ///     zooming sheet or navigation presentations.
    ///   - action: The action to perform when the button is tapped.
    public init(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String? = nil,
        menuItems: [FabBarMenuItem] = [],
        transitionSource: FabBarTransitionSource? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.menuItems = menuItems
        self.transitionSource = transitionSource
        self.action = action
    }
}
