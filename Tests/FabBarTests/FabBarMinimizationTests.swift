import CoreGraphics
import Testing
import UIKit
@testable import FabBar

@Suite("FabBar minimization")
@MainActor
struct FabBarMinimizationTests {
    @Test("Never preserves expanded behavior")
    func neverPreservesExpandedBehavior() {
        guard #available(iOS 26.0, *) else { return }

        let model = FabBarPresentationModel(behavior: .never)

        model.observeScroll(
            from: scrollGeometry(offset: 0),
            to: scrollGeometry(offset: 40)
        )

        #expect(!model.isMinimized)
    }

    @Test("Scrolling down minimizes after intentional travel")
    func scrollingDownMinimizes() {
        guard #available(iOS 26.0, *) else { return }

        let model = FabBarPresentationModel(behavior: .onScrollDown)

        model.observeScroll(
            from: scrollGeometry(offset: 0),
            to: scrollGeometry(offset: 6)
        )
        #expect(!model.isMinimized)

        model.observeScroll(
            from: scrollGeometry(offset: 6),
            to: scrollGeometry(offset: 14)
        )
        #expect(model.isMinimized)
    }

    @Test("Returning to the top expands")
    func returningToTopExpands() {
        guard #available(iOS 26.0, *) else { return }

        let model = FabBarPresentationModel(behavior: .onScrollDown)

        model.observeScroll(
            from: scrollGeometry(offset: 0),
            to: scrollGeometry(offset: 20)
        )
        #expect(model.isMinimized)

        model.observeScroll(
            from: scrollGeometry(offset: 2),
            to: scrollGeometry(offset: 0, isAtTop: true)
        )
        #expect(!model.isMinimized)
    }

    @Test("Becoming non-scrollable at the top expands")
    func becomingNonScrollableAtTopExpands() {
        guard #available(iOS 26.0, *) else { return }

        let model = FabBarPresentationModel(behavior: .onScrollDown)

        model.observeScroll(
            from: scrollGeometry(offset: 0),
            to: scrollGeometry(offset: 20)
        )
        #expect(model.isMinimized)

        model.observeScroll(
            from: scrollGeometry(offset: 20),
            to: scrollGeometry(
                offset: 0,
                isAtTop: true,
                isVerticallyScrollable: false
            )
        )
        #expect(!model.isMinimized)
    }

    @Test("On-scroll-up uses the opposite direction")
    func scrollingUpMinimizes() {
        guard #available(iOS 26.0, *) else { return }

        let model = FabBarPresentationModel(behavior: .onScrollUp)

        model.observeScroll(
            from: scrollGeometry(offset: 40),
            to: scrollGeometry(offset: 20)
        )

        #expect(model.isMinimized)
    }

    @available(iOS 26.0, *)
    private func scrollGeometry(
        offset: CGFloat,
        isAtTop: Bool = false,
        isVerticallyScrollable: Bool = true
    ) -> FabBarScrollGeometry {
        FabBarScrollGeometry(
            offset: offset,
            isAtTop: isAtTop,
            isVerticallyScrollable: isVerticallyScrollable
        )
    }
}

@Suite("FabBar bottom accessory scope")
struct FabBarBottomAccessoryScopeTests {
    private enum Tab: Hashable {
        case home
        case plan
    }

    @Test("No-tabs scope excludes every selection")
    func noTabsScope() {
        guard #available(iOS 26.0, *) else { return }

        let scope = FabBarBottomAccessoryScope<Tab>.none

        #expect(!scope.contains(.home))
        #expect(!scope.contains(.plan))
    }

    @Test("All-tabs scope includes every selection")
    func allTabsScope() {
        guard #available(iOS 26.0, *) else { return }

        let scope = FabBarBottomAccessoryScope<Tab>.allTabs

        #expect(scope.contains(.home))
        #expect(scope.contains(.plan))
    }

    @Test("Single-tab scope includes only its tab")
    func singleTabScope() {
        guard #available(iOS 26.0, *) else { return }

        let scope = FabBarBottomAccessoryScope<Tab>.tab(.plan)

        #expect(scope.contains(.plan))
        #expect(!scope.contains(.home))
    }
}

@Suite("FabBar hit testing")
@MainActor
struct FabBarHitTestingTests {
    @Test("UIKit action owns the shared glass and menu")
    func actionOwnsSharedGlassAndMenu() {
        guard #available(iOS 26.0, *) else { return }

        let action = FabBarAction(
            systemImage: "plus",
            accessibilityLabel: "Add",
            menuItems: [
                FabBarMenuItem(title: "Add Item", systemImage: "plus") {}
            ]
        ) {}
        let control = TabBarSegmentedControl(
            items: [UIImage(systemName: "house") as Any]
        )
        let view = GlassTabBarView(
            segmentedControl: control,
            tabCount: 1,
            action: action
        )

        #expect(view.fabGlassView.superview === view.containerEffectView.contentView)
        #expect(view.fabGlassView.effect is UIGlassEffect)
        #expect(!view.fabButton.isHidden)
        #expect(view.fabButton.isUserInteractionEnabled)
        #expect(view.fabButton.menu?.children.count == 1)
        #expect(!view.fabButton.showsMenuAsPrimaryAction)
        #expect(view.fabButton.image(for: .normal) != nil)
        #expect(view.fabButton.menuPreviewView === view.fabGlassView)
    }

    @Test("Menu without an action opens as the primary action")
    func menuOnlyActionUsesMenuAsPrimaryAction() {
        guard #available(iOS 26.0, *) else { return }

        let action = FabBarAction(
            systemImage: "plus",
            accessibilityLabel: "Add",
            menuItems: [
                FabBarMenuItem(title: "Add Item", systemImage: "plus") {}
            ]
        )
        let view = GlassTabBarView(
            segmentedControl: TabBarSegmentedControl(
                items: [UIImage(systemName: "house") as Any]
            ),
            tabCount: 1,
            action: action
        )

        #expect(action.action == nil)
        #expect(view.fabButton.menu?.children.count == 1)
        #expect(view.fabButton.showsMenuAsPrimaryAction)
    }

    @Test("Action without a menu remains a primary button action")
    func actionOnlyUsesButtonAsPrimaryAction() {
        guard #available(iOS 26.0, *) else { return }

        var didPerformAction = false
        let view = GlassTabBarView(
            segmentedControl: TabBarSegmentedControl(
                items: [UIImage(systemName: "house") as Any]
            ),
            tabCount: 1,
            action: FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "Add"
            ) {
                didPerformAction = true
            }
        )

        view.fabButton.sendActions(for: .touchUpInside)

        #expect(didPerformAction)
        #expect(view.fabButton.menu == nil)
        #expect(!view.fabButton.showsMenuAsPrimaryAction)
    }

    @Test("Minimized bar passes center touches to its accessory")
    func minimizedBarPassesCenterTouches() {
        guard #available(iOS 26.0, *) else { return }

        let control = TabBarSegmentedControl(
            items: [UIImage(systemName: "house") as Any]
        )
        let view = GlassTabBarView(
            segmentedControl: control,
            tabCount: 1,
            action: FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "Add"
            ) {}
        )
        view.frame = CGRect(
            x: 0,
            y: 0,
            width: 360,
            height: Constants.barHeight
        )
        view.setMinimized(true, animated: false)
        view.layoutIfNeeded()

        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        let leadingControl = CGPoint(
            x: Constants.compactControlSize / 2,
            y: view.bounds.midY
        )
        let trailingControl = CGPoint(
            x: view.bounds.maxX - Constants.compactControlSize / 2,
            y: view.bounds.midY
        )

        #expect(!view.point(inside: center, with: nil))
        #expect(view.point(inside: leadingControl, with: nil))
        #expect(view.point(inside: trailingControl, with: nil))
    }

    @Test("Changing tab count keeps the expanded constraint inactive")
    func changingTabCountWhileMinimizedPreservesCompactConstraints() {
        guard #available(iOS 26.0, *) else { return }

        let control = TabBarSegmentedControl(
            items: [UIImage(systemName: "house") as Any]
        )
        let view = GlassTabBarView(
            segmentedControl: control,
            tabCount: 1,
            action: FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "Add"
            ) {}
        )

        view.setMinimized(true, animated: false)
        view.updateTabCount(3)

        #expect(!view.isSegmentedTrailingConstraintActive)
    }

    @Test("Stale animation completion cannot hide expanded controls")
    func staleAnimationCompletionCannotHideExpandedControls() {
        guard #available(iOS 26.0, *) else { return }

        let control = TabBarSegmentedControl(
            items: [UIImage(systemName: "house") as Any]
        )
        let view = GlassTabBarView(
            segmentedControl: control,
            tabCount: 1,
            action: FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "Add"
            ) {}
        )

        view.setMinimized(true, animated: false)
        view.setMinimized(false, animated: false)
        view.completeMinimizationTransition(to: true, finished: true)

        #expect(!view.segmentedControl.isHidden)
        #expect(view.compactTabButton.isHidden)
    }
}

@Suite("FabBar sheet configuration")
struct FabBarSheetConfigurationTests {
    @Test("An empty detent list falls back to a large sheet")
    func emptyDetentsFallBackToLarge() {
        guard #available(iOS 26.0, *) else { return }

        let configuration = FabBarSheetConfiguration(detents: [])

        #expect(configuration.detents == [.large])
    }

    @Test("Configuration reapplies to an existing sheet controller")
    @MainActor
    func configurationReappliesToExistingController() throws {
        guard #available(iOS 26.0, *) else { return }

        let controller = UIViewController()
        controller.modalPresentationStyle = .pageSheet

        FabBarSheetConfiguration(
            detents: [.medium],
            prefersGrabberVisible: false,
            isModalInPresentation: false
        )
        .apply(to: controller)

        let sheet = try #require(controller.sheetPresentationController)
        #expect(sheet.detents.map(\.identifier) == [.medium])
        #expect(!sheet.prefersGrabberVisible)
        #expect(!controller.isModalInPresentation)

        FabBarSheetConfiguration(
            detents: [.large],
            prefersGrabberVisible: true,
            isModalInPresentation: true
        )
        .apply(to: controller)

        #expect(sheet.detents.map(\.identifier) == [.large])
        #expect(sheet.prefersGrabberVisible)
        #expect(controller.isModalInPresentation)
    }
}
