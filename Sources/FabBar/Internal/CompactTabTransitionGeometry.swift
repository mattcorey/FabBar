import UIKit

/// Tracks the selected tab icon's geometry so minimization can animate one
/// continuous icon between its expanded and compact positions.
@available(iOS 26.0, *)
@MainActor
final class CompactTabTransitionGeometry {
    struct Transition {
        let startCenter: CGPoint
        let endCenter: CGPoint
        let startScale: CGSize
        let endScale: CGSize
    }

    private var expandedIconFrames: [Int: CGRect] = [:]
    private var expandedIconFramesAvailableWidth: CGFloat?
    private let spacing = Constants.fabSpacing
    private let contentPadding = Constants.contentPadding

    private(set) var lastStartCenter: CGPoint?
    private(set) var lastEndCenter: CGPoint?
    private(set) var lastStartScale = CGSize(width: 1, height: 1)
    private(set) var lastEndScale = CGSize(width: 1, height: 1)

    let compactCenter = CGPoint(
        x: Constants.compactControlSize / 2,
        y: Constants.compactControlSize / 2
    )

    func captureExpandedIconFrames(
        tabCount: Int,
        control: TabBarSegmentedControl,
        in coordinateView: UIView,
        availableWidth: CGFloat
    ) {
        expandedIconFrames = Dictionary(
            uniqueKeysWithValues: (0..<tabCount).compactMap { index in
                control.iconFrame(
                    forSegmentAt: index,
                    in: coordinateView
                ).map { (index, $0) }
            }
        )
        expandedIconFramesAvailableWidth = availableWidth
    }

    func clearExpandedIconFrames() {
        expandedIconFrames.removeAll()
        expandedIconFramesAvailableWidth = nil
    }

    func transition(
        minimizing: Bool,
        selectedIndex: Int,
        control: TabBarSegmentedControl,
        availableWidth: CGFloat,
        compactIconSize: CGSize
    ) -> Transition {
        let tabCount = control.numberOfSegments
        let cacheMatchesAvailableWidth = expandedIconFramesAvailableWidth.map {
            abs($0 - availableWidth) < 0.5
        } == true
        let cachedFrame = cacheMatchesAvailableWidth
            ? expandedIconFrames[selectedIndex]
            : nil
        let expandedCenter = cachedFrame.map {
            CGPoint(x: $0.midX, y: $0.midY)
        }
            ?? estimatedExpandedCenter(
                selectedIndex: selectedIndex,
                tabCount: tabCount,
                control: control,
                availableWidth: availableWidth
            )
            ?? compactCenter
        let expandedIconSize = cachedFrame?.size
            ?? control.iconFrame(
                forSegmentAt: selectedIndex,
                in: control
            )?.size
            ?? compactIconSize
        let expandedScale = scale(
            expandedSize: expandedIconSize,
            compactSize: compactIconSize
        )
        let compactScale = CGSize(width: 1, height: 1)
        let result = minimizing
            ? Transition(
                startCenter: expandedCenter,
                endCenter: compactCenter,
                startScale: expandedScale,
                endScale: compactScale
            )
            : Transition(
                startCenter: compactCenter,
                endCenter: expandedCenter,
                startScale: compactScale,
                endScale: expandedScale
            )

        lastStartCenter = result.startCenter
        lastEndCenter = result.endCenter
        lastStartScale = result.startScale
        lastEndScale = result.endScale
        return result
    }

    private func scale(
        expandedSize: CGSize,
        compactSize: CGSize
    ) -> CGSize {
        guard compactSize.width > 0, compactSize.height > 0 else {
            return CGSize(width: 1, height: 1)
        }

        return CGSize(
            width: expandedSize.width / compactSize.width,
            height: expandedSize.height / compactSize.height
        )
    }

    private func estimatedExpandedCenter(
        selectedIndex: Int,
        tabCount: Int,
        control: TabBarSegmentedControl,
        availableWidth: CGFloat
    ) -> CGPoint? {
        let index = selectedIndex
        guard index >= 0, index < tabCount, tabCount > 0 else { return nil }

        let maximumGlassWidth = max(
            availableWidth - Constants.barHeight - spacing,
            0
        )
        let expandedGlassWidth = tabCount >= 3
            ? maximumGlassWidth
            : min(
                CGFloat(tabCount) * Constants.fewTabsSegmentWidth
                    + (contentPadding * 2),
                maximumGlassWidth
            )
        let controlWidth = max(expandedGlassWidth - (contentPadding * 2), 0)
        let segmentWidth = controlWidth / CGFloat(tabCount)
        let horizontalCenter = contentPadding
            + (CGFloat(index) + 0.5) * segmentWidth

        let currentIconCenter = control.iconCenter(
            forSegmentAt: index,
            in: control
        )
        let verticalOffset = currentIconCenter.map {
            $0.y - control.bounds.midY
        } ?? 0
        let expandedControlHeight = Constants.barHeight
            - (contentPadding * 2)
            - 1
        let verticalCenter = contentPadding
            + (expandedControlHeight / 2)
            + verticalOffset

        return CGPoint(x: horizontalCenter, y: verticalCenter)
    }
}
