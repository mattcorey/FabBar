import SwiftUI

/// A customizable iOS 26 glass tab bar with a floating action button.
///
/// FabBar provides a native-looking iOS 26 tab bar where you control what goes in it,
/// including a FAB that morphs with the glass effect.
///
/// ## Usage
///
/// The recommended way to use FabBar is with the `.fabBar()` modifier:
///
/// ```swift
/// TabView(selection: $selectedTab) {
///     Tab(value: .home) {
///         HomeView()
///             .fabBarSafeAreaPadding()
///             .toolbarVisibility(.hidden, for: .tabBar)
///     }
///     // more tabs...
/// }
/// .fabBar(
///     selection: $selectedTab,
///     tabs: [
///         FabBarTab(value: .home, title: "Home", systemImage: "house.fill"),
///         FabBarTab(value: .explore, title: "Explore", systemImage: "compass"),
///         FabBarTab(value: .profile, title: "Profile", systemImage: "person.fill"),
///     ],
///     action: FabBarAction(systemImage: "plus", accessibilityLabel: "Add Item") {
///         // Handle tap
///     }
/// )
/// ```
///
/// For more control over positioning, you can use the `FabBar` view directly.

@available(iOS 26.0, *)
public struct FabBar<Value: Hashable>: View {
    /// The currently selected tab.
    @Binding public var selection: Value

    /// The tabs to display.
    public let tabs: [FabBarTab<Value>]

    /// The floating action button configuration.
    public var action: FabBarAction

    /// Whether the bar is displaying its compact controls.
    public var isMinimized: Bool

    /// Called when the selected compact tab is tapped.
    public var onExpand: () -> Void

    /// Creates a FabBar with the specified configuration.
    ///
    /// - Parameters:
    ///   - selection: A binding to the currently selected tab.
    ///   - tabs: The tabs to display.
    ///   - action: The floating action button configuration.
    ///   - isMinimized: Whether to show compact controls. Defaults to `false`.
    ///   - onExpand: Called when the selected compact tab is tapped.
    public init(
        selection: Binding<Value>,
        tabs: [FabBarTab<Value>],
        action: FabBarAction,
        isMinimized: Bool = false,
        onExpand: @escaping () -> Void = {}
    ) {
        self._selection = selection
        self.tabs = tabs
        self.action = action
        self.isMinimized = isMinimized
        self.onExpand = onExpand
    }

    public var body: some View {
        if tabs.isEmpty {
            Color.clear
                .frame(height: Constants.barHeight)
                .onAppear {
                    fabBarLogger.warning("FabBar initialized with empty tabs array - nothing will be displayed")
                }
        } else {
            FabBarRepresentable(
                tabs: tabs,
                action: action,
                isMinimized: isMinimized,
                onExpand: onExpand,
                activeTab: $selection
            )
            .overlay(alignment: .trailing) {
                FabBarActionOverlay(
                    action: action,
                    size: isMinimized
                        ? Constants.compactControlSize
                        : Constants.barHeight
                )
                .frame(height: Constants.barHeight)
            }
            .frame(height: Constants.barHeight)
        }
    }
}

@available(iOS 26.0, *)
private struct FabBarActionOverlay: View {
    let action: FabBarAction
    let size: CGFloat

    var body: some View {
        if let transitionSource = action.transitionSource {
            actionControl
                .matchedTransitionSource(
                id: transitionSource.id,
                in: transitionSource.namespace
            )
        } else {
            icon
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var actionControl: some View {
        if action.menuItems.isEmpty {
            Button(action: action.action) {
                transitionLabel
            }
            .accessibilityLabel(action.accessibilityLabel)
            .applyAccessibilityIdentifier(action.accessibilityIdentifier)
        } else {
            Menu {
                ForEach(Array(action.menuItems.enumerated()), id: \.offset) { _, item in
                    Button(action: item.action) {
                        menuLabel(for: item)
                    }
                }
            } label: {
                transitionLabel
            } primaryAction: {
                action.action()
            }
            .menuOrder(.fixed)
            .accessibilityLabel(action.accessibilityLabel)
            .applyAccessibilityIdentifier(action.accessibilityIdentifier)
        }
    }

    private var transitionLabel: some View {
        icon
            .glassEffect(
                .clear.interactive().tint(.accentColor),
                in: .circle
            )
            .contentShape(.hoverEffect, Circle())
            .hoverEffect()
            .accessibilityHidden(true)
    }

    private var icon: some View {
        Image(systemName: action.systemImage)
            .font(.system(size: Constants.fabIconPointSize, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func menuLabel(for item: FabBarMenuItem) -> some View {
        switch item.icon {
        case .system(let systemImage):
            Label(item.title, systemImage: systemImage)
        case .asset(let image, let bundle):
            Label {
                Text(item.title)
            } icon: {
                Image(image, bundle: bundle)
            }
        }
    }
}

@available(iOS 26.0, *)
private extension View {
    @ViewBuilder
    func applyAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}
