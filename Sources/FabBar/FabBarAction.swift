#if os(iOS)

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

    /// Menu items displayed from the button.
    ///
    /// With an action, the menu appears when the button is held. Without an
    /// action, tapping the button presents the menu directly.
    public let menuItems: [FabBarMenuItem]

    /// Untitled groups of menu items displayed when the button is held.
    ///
    /// Empty sections are omitted from the menu.
    public let menuSections: [FabBarMenuSection]

    /// The action to perform when the button is tapped.
    public let action: () -> Void

    let presentsMenuAsPrimaryAction: Bool

    /// Creates a floating action button with a primary action.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol name for the button icon.
    ///   - accessibilityLabel: The accessibility label for VoiceOver users.
    ///   - accessibilityIdentifier: An optional identifier for UI testing.
    ///   - menuItems: Optional items displayed when the button is held.
    ///   - action: The action to perform when the button is tapped.
    public init(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String? = nil,
        menuItems: [FabBarMenuItem] = [],
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.menuItems = menuItems
        self.menuSections = []
        self.action = action
        self.presentsMenuAsPrimaryAction = false
    }

    /// Creates a floating action button configuration with a sectioned menu.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol name for the button icon.
    ///   - accessibilityLabel: The accessibility label for VoiceOver users.
    ///   - accessibilityIdentifier: An optional identifier for UI testing.
    ///   - menuSections: Untitled groups of items displayed when the button is
    ///     held. Empty sections are omitted.
    ///   - action: The action to perform when the button is tapped.
    public init(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String? = nil,
        menuSections: [FabBarMenuSection],
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.menuItems = []
        self.menuSections = menuSections
        self.action = action
        self.presentsMenuAsPrimaryAction = false
    }

    /// Creates a floating action button that presents a menu when tapped.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol name for the button icon.
    ///   - accessibilityLabel: The accessibility label for VoiceOver users.
    ///   - accessibilityIdentifier: An optional identifier for UI testing.
    ///   - menuItems: The nonempty set of items displayed when tapped.
    public init(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String? = nil,
        menuItems: [FabBarMenuItem]
    ) {
        precondition(
            !menuItems.isEmpty,
            "A menu-only FabBar action requires at least one menu item."
        )
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.menuItems = menuItems
        self.menuSections = []
        self.action = {}
        self.presentsMenuAsPrimaryAction = true
    }

    /// Creates a floating action button that presents a sectioned menu when
    /// tapped.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol name for the button icon.
    ///   - accessibilityLabel: The accessibility label for VoiceOver users.
    ///   - accessibilityIdentifier: An optional identifier for UI testing.
    ///   - menuSections: Untitled groups containing at least one menu item.
    public init(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String? = nil,
        menuSections: [FabBarMenuSection]
    ) {
        precondition(
            menuSections.contains { !$0.items.isEmpty },
            "A menu-only FabBar action requires at least one menu item."
        )
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.menuItems = []
        self.menuSections = menuSections
        self.action = {}
        self.presentsMenuAsPrimaryAction = true
    }
}

#endif
