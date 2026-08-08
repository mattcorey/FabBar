import Observation
import SwiftUI

/// Controls whether scrolling can minimize a FabBar.
///
/// The default used by FabBar is ``never``, preserving the package's original
/// full-width behavior unless minimization is explicitly enabled.
@available(iOS 26.0, *)
public enum FabBarMinimizeBehavior: Equatable, Sendable {
    /// Chooses the platform-style behavior. On iPhone, this currently behaves
    /// like ``onScrollDown``.
    case automatic

    /// Keeps the full-width FabBar visible at all times.
    case never

    /// Minimizes when the user scrolls down into content.
    case onScrollDown

    /// Minimizes when the user scrolls upward through content.
    case onScrollUp
}

@available(iOS 26.0, *)
@MainActor
@Observable
final class FabBarPresentationModel {
    private static let minimizationThreshold: CGFloat = 12

    var behavior: FabBarMinimizeBehavior {
        didSet {
            guard behavior != oldValue else { return }
            accumulatedTravel = 0
            if behavior == .never {
                isMinimized = false
            }
        }
    }

    private(set) var isMinimized = false
    private var accumulatedTravel: CGFloat = 0

    init(behavior: FabBarMinimizeBehavior) {
        self.behavior = behavior
    }

    func observeScroll(from oldValue: FabBarScrollGeometry, to newValue: FabBarScrollGeometry) {
        guard behavior != .never else { return }

        if newValue.isAtTop {
            expand()
            return
        }

        guard newValue.isVerticallyScrollable else { return }

        let delta = newValue.offset - oldValue.offset
        let minimizingDelta: CGFloat

        switch behavior {
        case .automatic, .onScrollDown:
            minimizingDelta = delta
        case .onScrollUp:
            minimizingDelta = -delta
        case .never:
            return
        }

        guard minimizingDelta > 0 else {
            accumulatedTravel = 0
            return
        }

        accumulatedTravel += minimizingDelta
        if accumulatedTravel >= Self.minimizationThreshold {
            isMinimized = true
            accumulatedTravel = 0
        }
    }

    func expand() {
        isMinimized = false
        accumulatedTravel = 0
    }
}

@available(iOS 26.0, *)
struct FabBarScrollGeometry: Equatable {
    let offset: CGFloat
    let isAtTop: Bool
    let isVerticallyScrollable: Bool
}

@available(iOS 26.0, *)
extension EnvironmentValues {
    @Entry var fabBarPresentationModel: FabBarPresentationModel?
}

@available(iOS 26.0, *)
private struct FabBarMinimizationScrollTargetModifier: ViewModifier {
    @Environment(\.fabBarPresentationModel) private var presentationModel

    func body(content: Content) -> some View {
        content.onScrollGeometryChange(for: FabBarScrollGeometry.self) { geometry in
            let offset = geometry.contentOffset.y + geometry.contentInsets.top

            return FabBarScrollGeometry(
                offset: offset,
                isAtTop: offset <= 0.5,
                isVerticallyScrollable:
                    geometry.contentSize.height > geometry.containerSize.height + 1
            )
        } action: { oldValue, newValue in
            presentationModel?.observeScroll(from: oldValue, to: newValue)
        }
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Marks the first scroll view in this hierarchy as a source of FabBar
    /// minimization updates.
    ///
    /// Apply this once within each tab whose scrolling should minimize the bar.
    func fabBarMinimizationScrollTarget() -> some View {
        modifier(FabBarMinimizationScrollTargetModifier())
    }
}
