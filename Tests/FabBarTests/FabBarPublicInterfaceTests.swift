import SwiftUI
import Testing
import FabBar

@Suite("FabBar public interface")
@MainActor
struct FabBarPublicInterfaceTests {
    private enum Tab: Hashable {
        case home
        case plan
    }

    private enum Destination: Identifiable {
        case item

        var id: Self { self }
    }

    @Test("The original action, view, and modifier calls still compile")
    func originalInterfaceStillCompiles() {
        guard #available(iOS 26.0, *) else { return }

        let selection = Binding.constant(Tab.home)
        let tabs = [
            FabBarTab(
                value: Tab.home,
                title: "Home",
                systemImage: "house"
            ),
        ]
        let action = FabBarAction(
            systemImage: "plus",
            accessibilityLabel: "Add"
        ) {}

        _ = FabBar(selection: selection, tabs: tabs, action: action)
        _ = EmptyView().fabBar(
            selection: selection,
            tabs: tabs,
            action: action
        )

        #expect(action.menuItems.isEmpty)
        #expect(action.menuSections.isEmpty)
        #expect(action.accessibilityIdentifier == nil)
    }

    @Test("Menu items and menu sections are separate options")
    func menuConfigurationInterfacesCompile() {
        guard #available(iOS 26.0, *) else { return }

        let item = FabBarMenuItem(
            title: "Add Item",
            systemImage: "plus"
        ) {}
        let itemAction = FabBarAction(
            systemImage: "plus",
            accessibilityLabel: "Add",
            menuItems: [item]
        ) {}
        let sectionAction = FabBarAction(
            systemImage: "plus",
            accessibilityLabel: "Add",
            menuSections: [FabBarMenuSection(items: [item])]
        ) {}

        #expect(itemAction.menuItems.count == 1)
        #expect(itemAction.menuSections.isEmpty)
        #expect(sectionAction.menuItems.isEmpty)
        #expect(sectionAction.menuSections.count == 1)
        #expect(sectionAction.menuSections[0].items.count == 1)
    }

    @Test("Minimization is an explicit opt-in")
    func minimizationInterfaceCompiles() {
        guard #available(iOS 26.0, *) else { return }

        let selection = Binding.constant(Tab.home)
        let tabs = [
            FabBarTab(
                value: Tab.home,
                title: "Home",
                systemImage: "house"
            ),
        ]
        let action = FabBarAction(
            systemImage: "plus",
            accessibilityLabel: "Add"
        ) {}

        _ = FabBar(
            selection: selection,
            tabs: tabs,
            action: action,
            isMinimized: true
        )
        _ = EmptyView().fabBar(
            selection: selection,
            tabs: tabs,
            action: action,
            minimizeBehavior: .onScrollDown
        )
    }

    @Test("Accessory content and scope are selected through one overload")
    func bottomAccessoryInterfaceCompiles() {
        guard #available(iOS 26.0, *) else { return }

        let selection = Binding.constant(Tab.plan)

        _ = EmptyView().fabBar(
            selection: selection,
            tabs: [
                FabBarTab(
                    value: Tab.plan,
                    title: "Plan",
                    systemImage: "calendar"
                ),
            ],
            action: FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "Add"
            ) {},
            bottomAccessoryScope: .tab(.plan)
        ) {
            Text("Accessory")
        }
    }

    @Test("Both morphing sheet forms are independent opt-ins")
    func morphingSheetInterfacesCompile() {
        guard #available(iOS 26.0, *) else { return }

        let isPresented = Binding.constant(false)
        let destination = Binding<Destination?>.constant(nil)

        _ = EmptyView().fabBarMorphingSheet(
            isPresented: isPresented
        ) {
            Text("Create")
        }

        _ = EmptyView().fabBarMorphingSheet(item: destination) { item in
            Text(String(describing: item))
        }
    }
}
