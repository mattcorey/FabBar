import Testing
import UIKit
@testable import FabBar

@Suite("FabBar icon transition")
@MainActor
struct FabBarTransitionTests {
    @Test("Transition follows the selected tab icon in position and size")
    func transitionFollowsSelectedIcon() throws {
        guard #available(iOS 26.0, *) else { return }

        let (view, control) = makeThreeTabTransitionView()
        let sourceFrame = try #require(
            control.iconFrame(
                forSegmentAt: control.selectedSegmentIndex,
                in: view.compactTabButton
            )
        )

        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        view.setMinimized(true, animated: true)

        let startCenter = try #require(view.lastTransitionStartIconCenter)
        let endCenter = try #require(view.lastTransitionEndIconCenter)
        let expectedEndCenter = CGPoint(
            x: Constants.compactControlSize / 2,
            y: Constants.compactControlSize / 2
        )

        #expect(abs(startCenter.x - sourceFrame.midX) < 0.5)
        #expect(abs(startCenter.y - sourceFrame.midY) < 0.5)
        #expect(endCenter == expectedEndCenter)

        view.setMinimized(false, animated: true)

        #expect(view.lastTransitionStartIconCenter == expectedEndCenter)
        #expect(view.lastTransitionEndIconCenter == startCenter)

        let compactIconSize = try #require(view.compactTabIconView.image?.size)
        let endScale = view.lastTransitionEndIconScale

        #expect(abs(compactIconSize.width * endScale.width - sourceFrame.width) < 0.5)
        #expect(abs(compactIconSize.height * endScale.height - sourceFrame.height) < 0.5)
    }

    @available(iOS 26.0, *)
    private func makeThreeTabTransitionView() -> (
        GlassTabBarView,
        TabBarSegmentedControl
    ) {
        let control = TabBarSegmentedControl(
            items: [
                UIImage(systemName: "house") as Any,
                UIImage(systemName: "map") as Any,
                UIImage(systemName: "person") as Any
            ]
        )
        control.configureContentViews(
            [
                TabItemContentView(title: "Home", symbolName: "house"),
                TabItemContentView(title: "Explore", symbolName: "map"),
                TabItemContentView(title: "Profile", symbolName: "person")
            ],
            accentViews: [
                TabItemContentView(title: "Home", symbolName: "house"),
                TabItemContentView(title: "Explore", symbolName: "map"),
                TabItemContentView(title: "Profile", symbolName: "person")
            ]
        )
        control.selectedSegmentIndex = 0

        let view = GlassTabBarView(
            segmentedControl: control,
            tabCount: 3,
            action: FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "Add"
            ) {}
        )
        view.frame = CGRect(
            x: 0,
            y: 0,
            width: 378,
            height: Constants.barHeight
        )
        view.updateCompactTab(
            title: "Home",
            systemImage: "house",
            image: nil,
            imageBundle: nil
        )
        view.layoutIfNeeded()

        return (view, control)
    }
}
