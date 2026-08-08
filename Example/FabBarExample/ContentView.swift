import FabBar
import SwiftUI

enum AppTab: Hashable {
    case home
    case explore
    case profile
    case activity
}

enum AddDestination: String, Identifiable {
    case item = "Item"
    case collection = "Collection"

    var id: Self { self }
}

@available(iOS 26.0, *)
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var addDestination: AddDestination?
    @State private var showingSettings = false
    @State private var tabCount = 3
    @State private var useNativeTabBar = false
    @State private var minimizesOnScroll = true
    @State private var showsBottomAccessory = true
    @State private var showsBottomAccessoryOnAllTabs = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var tabBarVisibility: Visibility {
        if useNativeTabBar {
            return .visible
        }
        return horizontalSizeClass == .compact ? .hidden : .visible
    }

    private var visibleTabs: [FabBarTab<AppTab>] {
        let allTabs: [FabBarTab<AppTab>] = [
            FabBarTab(value: .home, title: "Home", systemImage: "house.fill", onReselect: {
                print("Reselected: home")
            }),
            FabBarTab(value: .explore, title: "Explore", systemImage: "map.fill", onReselect: {
                print("Reselected: explore")
            }),
            FabBarTab(value: .profile, title: "Profile", systemImage: "person.fill", onReselect: {
                print("Reselected: profile")
            }),
            FabBarTab(value: .activity, title: "Activity", systemImage: "bell.fill", onReselect: {
                print("Reselected: activity")
            }),
        ]
        return Array(allTabs.prefix(tabCount))
    }

    private var fabBarBottomAccessoryScope: FabBarBottomAccessoryScope<AppTab> {
        guard !useNativeTabBar, showsBottomAccessory else {
            return .none
        }

        return showsBottomAccessoryOnAllTabs ? .allTabs : .tab(.explore)
    }

    private var shouldShowNativeBottomAccessory: Bool {
        useNativeTabBar
            && showsBottomAccessory
            && (showsBottomAccessoryOnAllTabs || selectedTab == .explore)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                NavigationStack {
                    ExampleTabList(systemImage: "house.fill")
                        .navigationTitle("Home")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                            }
                        }
                }
                .fabBarMinimizationScrollTarget()
                .fabBarSafeAreaPadding()
                .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab("Explore", systemImage: "map.fill", value: AppTab.explore) {
                ExploreTabView()
                    .fabBarMinimizationScrollTarget()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab("Profile", systemImage: "person.fill", value: AppTab.profile) {
                TabContentView(title: "Profile", systemImage: "person.fill")
                    .fabBarMinimizationScrollTarget()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab("Activity", systemImage: "bell.fill", value: AppTab.activity) {
                TabContentView(title: "Activity", systemImage: "bell.fill")
                    .fabBarMinimizationScrollTarget()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }
        }
        .exampleNativeTabBarFeatures(
            isEnabled: useNativeTabBar,
            minimizesOnScroll: minimizesOnScroll,
            showsBottomAccessory: shouldShowNativeBottomAccessory
        )
        .fabBar(
            selection: $selectedTab,
            tabs: visibleTabs,
            action: FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "Add",
                menuItems: [
                    FabBarMenuItem(title: "Add Item", systemImage: "plus") {
                        addDestination = .item
                    },
                    FabBarMenuItem(
                        title: "Add Collection",
                        systemImage: "folder.badge.plus"
                    ) {
                        addDestination = .collection
                    },
                ]
            ) {
                addDestination = .item
            },
            isVisible: !useNativeTabBar,
            minimizeBehavior: minimizesOnScroll ? .onScrollDown : .never,
            bottomAccessoryScope: fabBarBottomAccessoryScope
        ) {
            ExampleBottomAccessory()
        }
        .fabBarMorphingSheet(
            item: $addDestination,
            configuration: FabBarSheetConfiguration(detents: [.medium])
        ) { destination in
            NavigationStack {
                ContentUnavailableView(
                    "Add \(destination.rawValue)",
                    systemImage: "plus.circle"
                )
                .navigationTitle("Add \(destination.rawValue)")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                tabCount: $tabCount,
                useNativeTabBar: $useNativeTabBar,
                minimizesOnScroll: $minimizesOnScroll,
                showsBottomAccessory: $showsBottomAccessory,
                showsBottomAccessoryOnAllTabs: $showsBottomAccessoryOnAllTabs
            )
                .presentationDetents([.medium])
        }
        .onChange(of: tabCount) {
            // Reset to home if the selected tab is no longer visible
            if !visibleTabs.contains(where: { $0.value == selectedTab }) {
                selectedTab = .home
            }
        }
    }
}

@available(iOS 26.0, *)
struct SettingsView: View {
    @Binding var tabCount: Int
    @Binding var useNativeTabBar: Bool
    @Binding var minimizesOnScroll: Bool
    @Binding var showsBottomAccessory: Bool
    @Binding var showsBottomAccessoryOnAllTabs: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Tab Bar") {
                    Toggle("Use Native Tab Bar", isOn: $useNativeTabBar)
                }

                Section("Optional Features") {
                    Toggle("Minimize on Scroll", isOn: $minimizesOnScroll)
                    Toggle("Bottom Accessory", isOn: $showsBottomAccessory)

                    if showsBottomAccessory {
                        Toggle(
                            "Show Accessory on All Tabs",
                            isOn: $showsBottomAccessoryOnAllTabs
                        )
                    }
                }

                if !useNativeTabBar {
                    Section("Number of Tabs") {
                        Picker("Number of Tabs", selection: $tabCount) {
                            Text("2").tag(2)
                            Text("3").tag(3)
                            Text("4").tag(4)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

@available(iOS 26.0, *)
struct ExampleBottomAccessory: View {
    @Environment(\.fabBarBottomAccessoryPlacement) private var fabBarPlacement
    @Environment(\.tabViewBottomAccessoryPlacement) private var nativePlacement

    private var isInline: Bool {
        fabBarPlacement == .inline || nativePlacement == .inline
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .foregroundStyle(.tint)

            if !isInline {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Bottom accessory")
                        .font(.subheadline.weight(.semibold))
                    Text("Moves inline with the compact bar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "play.fill")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .animation(.smooth, value: isInline)
    }
}

@available(iOS 26.0, *)
private extension View {
    @ViewBuilder
    func exampleNativeTabBarFeatures(
        isEnabled: Bool,
        minimizesOnScroll: Bool,
        showsBottomAccessory: Bool
    ) -> some View {
        if isEnabled {
            tabBarMinimizeBehavior(
                minimizesOnScroll ? .onScrollDown : .never
            )
            .exampleBottomAccessory(isPresented: showsBottomAccessory)
        } else {
            self
        }
    }

    @ViewBuilder
    func exampleBottomAccessory(isPresented: Bool) -> some View {
        if isPresented {
            tabViewBottomAccessory {
                ExampleBottomAccessory()
            }
        } else {
            self
        }
    }
}

struct ExampleTabList: View {
    let systemImage: String

    var body: some View {
        List(1...30, id: \.self) { index in
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sample item \(index)")
                        .font(.headline)
                    Text("Scroll to test tab bar minimization")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
            }
        }
        .fabBarSafeAreaPadding()
    }
}

struct TabContentView: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            ExampleTabList(systemImage: systemImage)
                .navigationTitle(title)
        }
    }
}

struct ExploreTabView: View {
    private let places = [
        ("San Francisco", "Golden Gate Bridge and tech hub"),
        ("New York", "The city that never sleeps"),
        ("Tokyo", "Ancient traditions meet modern innovation"),
        ("Paris", "City of lights and romance"),
        ("London", "Historic capital with royal heritage"),
        ("Sydney", "Harbor city with iconic opera house"),
        ("Rome", "Eternal city of ancient wonders"),
        ("Barcelona", "Gaudí's architectural playground"),
        ("Amsterdam", "Canals, bikes, and Dutch charm"),
        ("Singapore", "Garden city of the future"),
        ("Dubai", "Modern marvels in the desert"),
        ("Cape Town", "Mountains meet the sea"),
        ("Rio de Janeiro", "Carnival spirit and beaches"),
        ("Vancouver", "Nature at your doorstep"),
        ("Melbourne", "Coffee culture capital"),
    ]

    var body: some View {
        NavigationStack {
            List(places, id: \.0) { place in
                VStack(alignment: .leading) {
                    Text(place.0)
                        .font(.headline)
                    Text(place.1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .fabBarSafeAreaPadding()
            .navigationTitle("Explore")
        }
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        ContentView()
    } else {
        Text("Requires iOS 26")
    }
}
