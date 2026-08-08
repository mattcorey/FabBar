/// Controls which selected tabs display a FabBar bottom accessory.
@available(iOS 26.0, *)
public enum FabBarBottomAccessoryScope<Value: Hashable> {
    /// Hides the accessory for every selected tab.
    case none

    /// Displays the accessory for every selected tab.
    case allTabs

    /// Displays the accessory only while a specific tab is selected.
    case tab(Value)

    func contains(_ value: Value) -> Bool {
        switch self {
        case .none:
            false
        case .allTabs:
            true
        case .tab(let scopedValue):
            value == scopedValue
        }
    }
}
