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
    case scannedDocument = "Scanned Document"

    var id: Self { self }
}

enum ExampleRoute: Hashable {
    case item(Int)
    case place(ExamplePlace)
}

struct ExamplePlace: Hashable, Identifiable {
    let name: String
    let description: String

    var id: String { name }
}

@available(iOS 26.0, *)
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var fabBarAddDestination: AddDestination?
    @State private var sidebarAddDestination: AddDestination?
    @State private var showingSettings = false
    @State private var tabCount = 3
    @State private var useNativeTabBar = false
    @State private var minimizesOnScroll = true
    @State private var showsBottomAccessory = true
    @State private var showsBottomAccessoryOnAllTabs = false
    @State private var hidesActionOnAllTabs = false
    @State private var homeNavigationPath: [ExampleRoute] = []
    @State private var exploreNavigationPath: [ExampleRoute] = []
    @State private var profileNavigationPath: [ExampleRoute] = []
    @State private var activityNavigationPath: [ExampleRoute] = []
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

    private var isFabBarActionVisible: Bool {
        guard selectedTab == .home || hidesActionOnAllTabs else {
            return true
        }

        switch selectedTab {
        case .home:
            return homeNavigationPath.isEmpty
        case .explore:
            return exploreNavigationPath.isEmpty
        case .profile:
            return profileNavigationPath.isEmpty
        case .activity:
            return activityNavigationPath.isEmpty
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                NavigationStack(path: $homeNavigationPath) {
                    ExampleTabList(systemImage: "house.fill")
                        .navigationTitle("Home")
                        .navigationDestination(for: ExampleRoute.self) { route in
                            ExampleDetailView(route: route)
                        }
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
                .fabBarSafeAreaPadding()
                .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab("Explore", systemImage: "map.fill", value: AppTab.explore) {
                ExploreTabView(navigationPath: $exploreNavigationPath)
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab("Profile", systemImage: "person.fill", value: AppTab.profile) {
                TabContentView(
                    title: "Profile",
                    systemImage: "person.fill",
                    navigationPath: $profileNavigationPath
                )
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab("Activity", systemImage: "bell.fill", value: AppTab.activity) {
                TabContentView(
                    title: "Activity",
                    systemImage: "bell.fill",
                    navigationPath: $activityNavigationPath
                )
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewSidebarBottomBar {
            SidebarAddAction(addDestination: $sidebarAddDestination)
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
                menuSections: [
                    FabBarMenuSection(items: [
                        FabBarMenuItem(title: "Add Item", systemImage: "plus") {
                            fabBarAddDestination = .item
                        },
                        FabBarMenuItem(
                            title: "Add Collection",
                            systemImage: "folder.badge.plus"
                        ) {
                            fabBarAddDestination = .collection
                        },
                    ]),
                    FabBarMenuSection(items: [
                        FabBarMenuItem(
                            title: "Scan Document",
                            systemImage: "doc.viewfinder"
                        ) {
                            fabBarAddDestination = .scannedDocument
                        },
                    ]),
                ]
            ) {
                fabBarAddDestination = .item
            },
            isVisible: !useNativeTabBar,
            isActionVisible: isFabBarActionVisible,
            minimizeBehavior: minimizesOnScroll ? .onScrollDown : .never,
            bottomAccessoryScope: fabBarBottomAccessoryScope
        ) {
            ExampleBottomAccessory()
        }
        .fabBarMorphingSheet(
            item: $fabBarAddDestination,
            configuration: FabBarSheetConfiguration(detents: [.medium])
        ) { destination in
            AddDestinationView(destination: destination)
        }
        .sheet(item: $sidebarAddDestination) { destination in
            AddDestinationView(destination: destination)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                tabCount: $tabCount,
                useNativeTabBar: $useNativeTabBar,
                minimizesOnScroll: $minimizesOnScroll,
                showsBottomAccessory: $showsBottomAccessory,
                showsBottomAccessoryOnAllTabs: $showsBottomAccessoryOnAllTabs,
                hidesActionOnAllTabs: $hidesActionOnAllTabs
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

struct AddDestinationView: View {
    let destination: AddDestination

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Add \(destination.rawValue)",
                systemImage: "plus.circle"
            )
            .navigationTitle("Add \(destination.rawValue)")
        }
    }
}

struct SidebarAddAction: View {
    @Binding var addDestination: AddDestination?

    var body: some View {
        Menu("Add", systemImage: "plus") {
            Button("Add Item", systemImage: "plus") {
                addDestination = .item
            }

            Button("Add Collection", systemImage: "folder.badge.plus") {
                addDestination = .collection
            }
        } primaryAction: {
            addDestination = .item
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }
}

@available(iOS 26.0, *)
struct SettingsView: View {
    @Binding var tabCount: Int
    @Binding var useNativeTabBar: Bool
    @Binding var minimizesOnScroll: Bool
    @Binding var showsBottomAccessory: Bool
    @Binding var showsBottomAccessoryOnAllTabs: Bool
    @Binding var hidesActionOnAllTabs: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Use Native Tab Bar Everywhere", isOn: $useNativeTabBar)
                } footer: {
                    Text(
                        "When off, compact layouts use FabBar and wider layouts use the native adaptable sidebar."
                    )
                }

                Section("Optional Features") {
                    Toggle("Minimize on Scroll", isOn: $minimizesOnScroll)
                    Toggle("Bottom Accessory", isOn: $showsBottomAccessory)
                    Toggle(
                        "Hide Action on Detail Pages for All Tabs",
                        isOn: $hidesActionOnAllTabs
                    )

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
            NavigationLink(value: ExampleRoute.item(index)) {
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
        }
        .fabBarMinimizationScrollTarget()
        .fabBarSafeAreaPadding()
    }
}

struct TabContentView: View {
    let title: String
    let systemImage: String
    @Binding var navigationPath: [ExampleRoute]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ExampleTabList(systemImage: systemImage)
                .navigationTitle(title)
                .navigationDestination(for: ExampleRoute.self) { route in
                    ExampleDetailView(route: route)
                }
        }
    }
}

struct ExploreTabView: View {
    @Binding var navigationPath: [ExampleRoute]

    private let places = [
        ExamplePlace(
            name: "San Francisco",
            description: "Golden Gate Bridge and tech hub"
        ),
        ExamplePlace(name: "New York", description: "The city that never sleeps"),
        ExamplePlace(
            name: "Tokyo",
            description: "Ancient traditions meet modern innovation"
        ),
        ExamplePlace(name: "Paris", description: "City of lights and romance"),
        ExamplePlace(name: "London", description: "Historic capital with royal heritage"),
        ExamplePlace(
            name: "Sydney",
            description: "Harbor city with iconic opera house"
        ),
        ExamplePlace(name: "Rome", description: "Eternal city of ancient wonders"),
        ExamplePlace(
            name: "Barcelona",
            description: "Gaudí's architectural playground"
        ),
        ExamplePlace(name: "Amsterdam", description: "Canals, bikes, and Dutch charm"),
        ExamplePlace(name: "Singapore", description: "Garden city of the future"),
        ExamplePlace(name: "Dubai", description: "Modern marvels in the desert"),
        ExamplePlace(name: "Cape Town", description: "Mountains meet the sea"),
        ExamplePlace(name: "Rio de Janeiro", description: "Carnival spirit and beaches"),
        ExamplePlace(name: "Vancouver", description: "Nature at your doorstep"),
        ExamplePlace(name: "Melbourne", description: "Coffee culture capital")
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(places) { place in
                NavigationLink(value: ExampleRoute.place(place)) {
                    VStack(alignment: .leading) {
                        Text(place.name)
                            .font(.headline)
                        Text(place.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .fabBarMinimizationScrollTarget()
            .fabBarSafeAreaPadding()
            .navigationTitle("Explore")
            .navigationDestination(for: ExampleRoute.self) { route in
                ExampleDetailView(route: route)
            }
        }
    }
}

struct ExampleDetailView: View {
    let route: ExampleRoute

    var body: some View {
        switch route {
        case .item(let index):
            ExampleDetailList(
                title: "Sample item \(index)",
                subtitle: "This detail page hides the action button.",
                systemImage: "doc.text"
            )
        case .place(let place):
            ExampleDetailList(
                title: place.name,
                subtitle: place.description,
                systemImage: "mappin.and.ellipse"
            )
        }
    }
}

struct ExampleDetailList: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        List(1...30, id: \.self) { index in
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detail row \(index)")
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
            }
        }
        .fabBarMinimizationScrollTarget()
        .fabBarSafeAreaPadding()
        .navigationTitle(title)
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        ContentView()
    } else {
        Text("Requires iOS 26")
    }
}
