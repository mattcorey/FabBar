# FabBar

A faithful recreation of the iOS 26 Liquid Glass tab bar with a tinted floating action button.

> **Warning:** This library relies on internal UIKit view hierarchy manipulation that may break in future iOS updates. Use at your own risk.

![FabBar Screenshot](Assets/fabbar-screenshot.png)

## Why FabBar?

Many apps have a primary action that users perform frequently: composing a social media post, logging a meal, creating a task. Placing this action at the bottom of the screen keeps it in the thumb zone and always visible, reducing friction for the most common user flow.

With iOS 26's tab bar, developers can declare a tab with `role: .search` and abuse it as a primary action, but this approach has several issues:

- You're lying to the system, it's not actually a search tab
- VoiceOver reads it as a tab, not a button
- Requires listening for tab changes and undoing them in SwiftUI, which is prone to race conditions
- No ability to tint, so it looks like a search tab rather than a primary action

Developers have another option: placing a custom floating action button above the tab bar. Typically, this is placed on the right side of the screen. However, with iOS 26's centered tab bar, this creates an awkward layout. With fewer than four tabs, there's negative space on either side of the bar, and placing a FAB on the trailing edge creates unbalanced empty space below it. And there's no way to customize the native tab bar's placement or sizing to work around this.

FabBar provides one solution: recreate the tab bar entirely for full control.

## How It Works

FabBar provides a SwiftUI API but uses UIKit internally.

The key challenge in faithfully recreating the tab bar is the bubbly interactive glass effect on touch down. This effect is only available to tab bars and one other component: segmented controls. FabBar uses a `UISegmentedControl` as its foundation, hiding the default labels and overlaying custom tab item views.

Why UIKit? FabBar manipulates `UISegmentedControl`'s internal view hierarchy to hide the native labels and overlay custom views. This isn't possible with SwiftUI's Picker. Additionally, mixing custom UIKit controls with SwiftUI's `.glassEffect()` causes framerate issues during touch interactions.

This approach is inherently brittle and may break across OS updates. See [Known Limitations](#known-limitations) for other tradeoffs.

Credit to [Kavsoft](https://youtu.be/wfHIe8GpKAU?si=ASViL-OuhqQwEWzr) for the original idea of using a segmented control to imitate a tab bar.

## Installation

Add FabBar as a Swift Package dependency:

```swift
dependencies: [
    .package(url: "https://github.com/mattcorey/FabBar.git", from: "1.1.0")
]
```

## Usage

```swift
import FabBar

enum AppTab: Hashable {
    case home, explore, profile
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var tabBarVisibility: Visibility {
        horizontalSizeClass == .compact ? .hidden : .visible
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }
            Tab("Explore", systemImage: "compass", value: .explore) {
                ExploreView()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }
            Tab("Profile", systemImage: "person.fill", value: .profile) {
                ProfileView()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }
        }
        .fabBar(
            selection: $selectedTab,
            tabs: [
                FabBarTab(value: .home, title: "Home", systemImage: "house.fill"),
                FabBarTab(value: .explore, title: "Explore", systemImage: "compass"),
                FabBarTab(value: .profile, title: "Profile", systemImage: "person.fill"),
            ],
            action: FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "Add Item"
            ) {
                // Handle FAB tap
            }
        )
    }
}
```

The `.fabBar()` modifier handles positioning, safe area management, and automatically hides on iPad (showing the native tab bar instead). Use `.fabBarSafeAreaPadding()` on scrollable content within each tab to ensure content isn't hidden behind the bar.

For more control over positioning, you can use the `FabBar` view directly.

### Optional Features

The original `FabBar`, `FabBarAction`, and `.fabBar(...)` calls remain valid
without any new arguments. Every enhancement in this release is opt-in:

- Add `menuItems` only when the action needs a long-press menu.
- Supply `minimizeBehavior` only when the bar should minimize.
- Set `isActionVisible` when app state should temporarily move the action
  button offscreen. The expanded tab control recenters, and an inline bottom
  accessory expands into the vacated trailing space.
- Choose the bottom-accessory overload only when accessory content exists;
  that overload keeps its content and tab scope together.
- Add `fabBarMorphingSheet` only when a presentation should morph from the
  action button. Regular SwiftUI sheets continue to work normally.

### Custom Images

Use custom images from your asset catalog instead of SF Symbols:

```swift
FabBarTab(
    value: .library,
    title: "Library",
    image: "custom.library.icon",
    imageBundle: .main
)
```

### Tab Reselection

Handle when users tap an already-selected tab (useful for scroll-to-top):

```swift
FabBarTab(
    value: .home,
    title: "Home",
    systemImage: "house.fill",
    onReselect: {
        // User tapped this tab while it was already selected
        scrollToTop()
    }
)
```

### Conditional Visibility

Hide the FabBar based on app state (e.g., during selection mode):

```swift
.fabBar(
    selection: $selectedTab,
    tabs: tabs,
    action: action,
    isVisible: !isSelecting
)
```

### Action Visibility

Control the floating action independently while leaving tab selection and
minimization behavior intact. When the value becomes `false`, the action slides
beyond the trailing screen edge and stops accepting input. The expanded tab
control recenters, while a minimized bottom accessory stretches into the space
the action left behind. This is useful when a navigation stack should show the
action only at its root.

```swift
@State private var navigationPath: [Destination] = []

TabView(selection: $selectedTab) {
    Tab("Home", systemImage: "house", value: AppTab.home) {
        NavigationStack(path: $navigationPath) {
            HomeView()
        }
    }
}
.fabBar(
    selection: $selectedTab,
    tabs: tabs,
    action: action,
    isActionVisible: navigationPath.isEmpty
)
```

### Long-Press Menu

`FabBarAction` remains a normal primary action when tapped. Add `menuItems`
to show a menu only when the user holds the button. Leaving the array empty
preserves the original action-only behavior.

```swift
FabBarAction(
    systemImage: "plus",
    accessibilityLabel: "Create",
    menuItems: [
        FabBarMenuItem(title: "Create Item", systemImage: "plus") {
            createItem()
        },
        FabBarMenuItem(title: "Create Collection", systemImage: "folder.badge.plus") {
            createCollection()
        },
    ]
) {
    createItem()
}
```

### Minimize on Scroll

Minimization is opt-in. Configure the behavior on `.fabBar()` and mark one
scrolling hierarchy in each participating tab. The selected tab becomes a
compact button on the leading edge and the action remains available on the
trailing edge. Tapping the compact tab or returning to the top expands the bar.

```swift
TabView(selection: $selectedTab) {
    Tab("Home", systemImage: "house", value: AppTab.home) {
        HomeView()
            .fabBarMinimizationScrollTarget()
    }
}
.fabBar(
    selection: $selectedTab,
    tabs: tabs,
    action: action,
    minimizeBehavior: .onScrollDown
)
```

Available behaviors are `.never` (used by the original overload), `.automatic`,
`.onScrollDown`, and `.onScrollUp`.

`fabBarMinimizationScrollTarget()` observes the first scroll view in the
hierarchy where it is applied. For a `NavigationSplitView`, apply it separately
inside the sidebar and detail branches so each column's active content can
drive the shared bar state.

### Bottom Accessory

Choose the bottom-accessory overload when content should sit above the expanded
bar and move between the compact controls when minimized. Read
`fabBarBottomAccessoryPlacement` to adapt the accessory's own layout. While
inline, `fabBarBottomAccessoryWidth` provides the actual center-lane width so
the accessory can make responsive layout decisions before clipping occurs.
FabBar supplies the accessory's glass surface and standard minimum sizing, so
the accessory builder should provide content without applying an additional
glass effect or forcing a container height.
The accessory builder exists only on this overload, so callers that don't need
an accessory don't provide accessory-related arguments. Use
`bottomAccessoryScope` to make it native to one tab instead of displaying it
throughout the tab view. The default is `.allTabs`; use `.none` to hide an
already-configured accessory dynamically.

```swift
.fabBar(
    selection: $selectedTab,
    tabs: tabs,
    action: action,
    minimizeBehavior: .onScrollDown,
    bottomAccessoryScope: .tab(AppTab.player)
) {
    PlayerAccessory()
}

struct PlayerAccessory: View {
    @Environment(\.fabBarBottomAccessoryPlacement) private var placement
    @Environment(\.fabBarBottomAccessoryWidth) private var inlineWidth

    var body: some View {
        PlayerControls(showsDetails: placement != .inline)
            .frame(width: inlineWidth)
    }
}
```

### Morphing Sheet

Apply `fabBarMorphingSheet` after `fabBar` to present client-provided SwiftUI
content from the action button. FabBar keeps the visible action and its menu in
the shared UIKit glass container, then hosts the sheet content internally so
UIKit can use that same glass view as the zoom source.

For a single destination, use the familiar `isPresented` form:

```swift
@State private var isCreating = false

TabView {
    // tabs
}
.fabBar(
    selection: $selectedTab,
    tabs: tabs,
    action: FabBarAction(
        systemImage: "plus",
        accessibilityLabel: "Create"
    ) {
        isCreating = true
    }
)
.fabBarMorphingSheet(isPresented: $isCreating) {
    CreateView()
}
```

Use the `item` form when menu choices select different destinations:

```swift
enum CreateDestination: Identifiable {
    case item
    case collection

    var id: Self { self }
}

@State private var createDestination: CreateDestination?

TabView {
    // tabs
}
.fabBar(
    selection: $selectedTab,
    tabs: tabs,
    action: FabBarAction(
        systemImage: "plus",
        accessibilityLabel: "Create"
    ) {
        createDestination = .item
    }
)
.fabBarMorphingSheet(
    item: $createDestination,
    configuration: FabBarSheetConfiguration(detents: [.medium])
) { destination in
    CreateView(destination: destination)
}
```

This API is optional. Continue using SwiftUI's regular `sheet` modifiers when
a source morph is not needed. A morphing sheet is hosted in a new SwiftUI root;
apply custom environment values inside its content builder when the destination
depends on values that are normally inherited from an ancestor.

### Manual Positioning

For more control, use the `FabBar` view directly instead of the modifier. Apply 21pt padding on all sides:

```swift
.safeAreaBar(edge: .bottom) {
    if horizontalSizeClass == .compact {
        FabBar(selection: $selectedTab, tabs: tabs, action: action)
            .padding(.horizontal, 21)
            .padding(.bottom, 21)
    }
}
.ignoresSafeArea(.container, edges: .bottom)
```

## Example

See the [Example project](Example/FabBarExample) for a complete implementation.

## Known Limitations

**Large Content Viewer:** Native tab bars show the [Large Content Viewer](https://developer.apple.com/videos/play/wwdc2019/261/) on long press when using accessibility text sizes. FabBar uses a segmented control internally, which shows a popover instead. Attempts to add Large Content Viewer support were unsuccessful due to inability to disable the default popover.

![Large Text Mode](Assets/large-text-mode.png)

**VoiceOver focus after tab selection:** After activating a new tab with VoiceOver, focus may jump to the first tab instead of remaining on the selected tab.

**No native tab reselection behavior:** Native tab bars automatically scroll to top when reselecting a tab. FabBar doesn't get this behavior; use the `onReselect` callback to implement it yourself.

**Hardcoded dimensions:** Bar height, spacing, and font sizes are hardcoded to match iOS 26's tab bar. If Apple changes these values in future iOS versions, FabBar won't automatically update to match.

## License

MIT License. See [LICENSE](LICENSE) for details.
