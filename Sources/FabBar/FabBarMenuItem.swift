import Foundation

/// An item displayed when a FabBar action button is held.
@available(iOS 26.0, *)
public struct FabBarMenuItem {
    enum Icon {
        case system(String)
        case asset(name: String, bundle: Bundle)
    }

    /// The localized title displayed in the menu.
    public let title: String

    let icon: Icon

    /// The action to perform when the menu item is selected.
    public let action: () -> Void

    /// Creates a menu item with an SF Symbol icon.
    public init(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = .system(systemImage)
        self.action = action
    }

    /// Creates a menu item with a custom image from a bundle.
    public init(
        title: String,
        image: String,
        imageBundle: Bundle? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = .asset(
            name: image,
            bundle: imageBundle ?? .main
        )
        self.action = action
    }
}
