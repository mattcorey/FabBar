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
        isAtTop: Bool = false
    ) -> FabBarScrollGeometry {
        FabBarScrollGeometry(
            offset: offset,
            isAtTop: isAtTop,
            isVerticallyScrollable: true
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
}
