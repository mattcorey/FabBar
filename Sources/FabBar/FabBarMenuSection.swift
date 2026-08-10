/// An untitled group of related items in a FabBar action menu.
@available(iOS 26.0, *)
public struct FabBarMenuSection {
    /// The menu items displayed in this section.
    public let items: [FabBarMenuItem]

    /// Creates an untitled menu section.
    public init(items: [FabBarMenuItem]) {
        self.items = items
    }
}
