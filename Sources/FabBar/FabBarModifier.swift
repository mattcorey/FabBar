import SwiftUI

/// View modifier that positions a FabBar and optional bottom accessory.
@available(iOS 26.0, *)
struct FabBarModifier<Value: Hashable, BottomAccessory: View>: ViewModifier {
    @Binding var selection: Value
    let tabs: [FabBarTab<Value>]
    let action: FabBarAction
    let isVisible: Bool
    let isActionVisible: Bool
    let minimizeBehavior: FabBarMinimizeBehavior
    let bottomAccessoryScope: FabBarBottomAccessoryScope<Value>
    let bottomAccessory: BottomAccessory

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.fabBarSheetSource) private var sheetSource
    @State private var bottomSafeAreaInset: CGFloat = 0
    @State private var expandedAccessoryHeight: CGFloat = 0
    @State private var presentationModel: FabBarPresentationModel

    init(
        selection: Binding<Value>,
        tabs: [FabBarTab<Value>],
        action: FabBarAction,
        isVisible: Bool,
        isActionVisible: Bool,
        minimizeBehavior: FabBarMinimizeBehavior,
        bottomAccessoryScope: FabBarBottomAccessoryScope<Value>,
        bottomAccessory: BottomAccessory
    ) {
        _selection = selection
        self.tabs = tabs
        self.action = action
        self.isVisible = isVisible
        self.isActionVisible = isActionVisible
        self.minimizeBehavior = minimizeBehavior
        self.bottomAccessoryScope = bottomAccessoryScope
        self.bottomAccessory = bottomAccessory
        _presentationModel = State(
            initialValue: FabBarPresentationModel(behavior: minimizeBehavior)
        )
    }

    /// Whether the FabBar should be displayed.
    private var showsFabBar: Bool {
        horizontalSizeClass == .compact && isVisible
    }

    /// Total content margin needed to clear the FabBar and expanded accessory.
    private var bottomContentMargin: CGFloat {
        let accessoryMargin = showsBottomAccessory
            && !presentationModel.isMinimized
                ? expandedAccessoryHeight + Constants.accessorySpacing
                : 0

        return Constants.barHeight + Constants.bottomPadding + accessoryMargin
    }

    /// Whether the accessory belongs to the currently selected tab.
    private var showsBottomAccessory: Bool {
        bottomAccessoryScope.contains(selection)
    }

    /// Padding added on top of the device's existing bottom safe area.
    private var calculatedPadding: CGFloat {
        showsFabBar ? max(bottomContentMargin - bottomSafeAreaInset, 0) : 0
    }

    func body(content: Content) -> some View {
        Group {
            if minimizeBehavior == .never {
                content.safeAreaBar(edge: .bottom) {
                    safeAreaContent
                }
            } else {
                content.safeAreaInset(edge: .bottom, spacing: 0) {
                    safeAreaContent
                }
            }
        }
            .ignoresSafeArea(.all, edges: showsFabBar ? [.bottom] : [])
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.safeAreaInsets.bottom
            } action: { newValue in
                bottomSafeAreaInset = newValue
            }
            .environment(\.fabBarBottomSafeAreaPadding, calculatedPadding)
            .environment(
                \.fabBarPresentationModel,
                showsFabBar ? presentationModel : nil
            )
            .onChange(of: minimizeBehavior, initial: true) { _, behavior in
                presentationModel.behavior = behavior
            }
            .onChange(of: showsFabBar) { _, isShowing in
                if !isShowing {
                    presentationModel.expand()
                }
            }
    }

    @ViewBuilder
    private var safeAreaContent: some View {
        if showsFabBar {
            FabBarSafeAreaContent(
                selection: $selection,
                tabs: tabs,
                action: action,
                isActionVisible: isActionVisible,
                isMinimized: presentationModel.isMinimized,
                isBottomAccessoryEnabled: showsBottomAccessory,
                bottomAccessory: bottomAccessory,
                expandedAccessoryHeight: $expandedAccessoryHeight,
                onExpand: presentationModel.expand,
                sheetSource: sheetSource
            )
            .padding(.bottom, Constants.bottomPadding)
        }
    }
}

@available(iOS 26.0, *)
private struct FabBarSafeAreaContent<Value: Hashable, BottomAccessory: View>: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    @Binding var selection: Value
    let tabs: [FabBarTab<Value>]
    let action: FabBarAction
    let isActionVisible: Bool
    let isMinimized: Bool
    let isBottomAccessoryEnabled: Bool
    let bottomAccessory: BottomAccessory
    @Binding var expandedAccessoryHeight: CGFloat
    let onExpand: () -> Void
    let sheetSource: FabBarSheetSource?

    @State private var containerWidth: CGFloat = 0

    private var inlineAccessoryGeometry: FabBarInlineAccessoryGeometry {
        FabBarInlineAccessoryGeometry(
            containerWidth: containerWidth,
            isActionVisible: isActionVisible
        )
    }

    var body: some View {
        FabBarSafeAreaLayout(
            minimizationProgress: isMinimized ? 1 : 0,
            minimizedAccessoryCenterX: inlineAccessoryGeometry.centerX,
            accessorySpacing: Constants.accessorySpacing
        ) {
            if isBottomAccessoryEnabled {
                bottomAccessory
                    .environment(
                        \.fabBarBottomAccessoryPlacement,
                        isMinimized ? .inline : .expanded
                    )
                    .environment(
                        \.fabBarBottomAccessoryWidth,
                        isMinimized ? inlineAccessoryGeometry.width : nil
                    )
                    .frame(
                        width: isMinimized
                            ? inlineAccessoryGeometry.width
                            : nil
                    )
                    .frame(
                        minHeight: isMinimized
                            ? Constants.compactControlSize
                            : Constants.expandedAccessoryMinimumHeight,
                        maxHeight: isMinimized
                            ? Constants.compactControlSize
                            : nil
                    )
                    .glassEffect(
                        .regular,
                        in: .rect(
                            cornerRadius: Constants.bottomAccessoryCornerRadius
                        )
                    )
                    .padding(
                        .horizontal,
                        isMinimized
                            ? 0
                            : Constants.expandedAccessoryHorizontalPadding
                    )
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        if !isMinimized {
                            expandedAccessoryHeight = height
                        }
                    }
            }

            FabBar(
                selection: $selection,
                tabs: tabs,
                action: action,
                isActionVisible: isActionVisible,
                isMinimized: isMinimized,
                onExpand: onExpand,
                sheetSource: sheetSource
            )
            .padding(.horizontal, Constants.horizontalPadding)
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            containerWidth = width
        }
        .animation(
            accessibilityReduceMotion
                ? .easeInOut(duration: 0.2)
                : .smooth(duration: 0.45, extraBounce: 0),
            value: isMinimized
        )
        .animation(
            accessibilityReduceMotion
                ? .easeInOut(duration: 0.2)
                : .smooth(duration: 0.45, extraBounce: 0),
            value: isActionVisible
        )
    }
}

@available(iOS 26.0, *)
struct FabBarInlineAccessoryGeometry: Equatable {
    let width: CGFloat
    let centerX: CGFloat

    init(containerWidth: CGFloat, isActionVisible: Bool) {
        let leadingInset = Constants.horizontalPadding
            + Constants.compactControlSize
            + Constants.inlineAccessorySpacing
        let trailingInset = isActionVisible
            ? leadingInset
            : Constants.horizontalPadding

        guard containerWidth > leadingInset + trailingInset else {
            width = 0
            centerX = containerWidth / 2
            return
        }

        width = containerWidth - leadingInset - trailingInset
        centerX = leadingInset + (width / 2)
    }
}

@available(iOS 26.0, *)
private struct FabBarSafeAreaLayout: Layout, Animatable {
    var minimizationProgress: CGFloat
    var minimizedAccessoryCenterX: CGFloat
    let accessorySpacing: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(
                minimizationProgress,
                minimizedAccessoryCenterX
            )
        }
        set {
            minimizationProgress = newValue.first
            minimizedAccessoryCenterX = newValue.second
        }
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = measuredSizes(for: subviews, proposal: proposal)

        guard sizes.count == 2 else {
            return sizes.first ?? .zero
        }

        let accessory = sizes[0]
        let bar = sizes[1]
        let expandedHeight = accessory.height + accessorySpacing + bar.height
        let minimizedHeight = max(accessory.height, bar.height)

        return CGSize(
            width: proposal.width ?? max(accessory.width, bar.width),
            height: interpolated(
                from: expandedHeight,
                to: minimizedHeight
            )
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let sizes = measuredSizes(for: subviews, proposal: proposal)

        guard sizes.count == 2 else {
            guard let subview = subviews.first, let size = sizes.first else {
                return
            }

            subview.place(
                at: CGPoint(x: bounds.midX, y: bounds.minY),
                anchor: .top,
                proposal: ProposedViewSize(size)
            )
            return
        }

        let accessory = sizes[0]
        let bar = sizes[1]
        let minimizedHeight = max(accessory.height, bar.height)
        let expandedAccessoryY = bounds.minY
        let expandedBarY = bounds.minY + accessory.height + accessorySpacing
        let minimizedAccessoryY = bounds.minY
            + (minimizedHeight - accessory.height) / 2
        let minimizedBarY = bounds.minY + (minimizedHeight - bar.height) / 2

        subviews[0].place(
            at: CGPoint(
                x: interpolated(
                    from: bounds.midX,
                    to: bounds.minX + minimizedAccessoryCenterX
                ),
                y: interpolated(
                    from: expandedAccessoryY,
                    to: minimizedAccessoryY
                )
            ),
            anchor: .top,
            proposal: ProposedViewSize(accessory)
        )
        subviews[1].place(
            at: CGPoint(
                x: bounds.midX,
                y: interpolated(from: expandedBarY, to: minimizedBarY)
            ),
            anchor: .top,
            proposal: ProposedViewSize(bar)
        )
    }

    private func measuredSizes(
        for subviews: Subviews,
        proposal: ProposedViewSize
    ) -> [CGSize] {
        subviews.map {
            $0.sizeThatFits(
                ProposedViewSize(width: proposal.width, height: nil)
            )
        }
    }

    private func interpolated(from start: CGFloat, to end: CGFloat) -> CGFloat {
        start + (end - start) * minimizationProgress
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Adds an always-expanded FabBar to the bottom of the view.
    ///
    /// This is FabBar's original interface. Optional features use separate
    /// overloads and don't change the behavior of existing call sites.
    func fabBar<Value: Hashable>(
        selection: Binding<Value>,
        tabs: [FabBarTab<Value>],
        action: FabBarAction,
        isVisible: Bool = true,
        isActionVisible: Bool = true
    ) -> some View {
        fabBar(
            selection: selection,
            tabs: tabs,
            action: action,
            isVisible: isVisible,
            isActionVisible: isActionVisible,
            minimizeBehavior: .never
        )
    }

    /// Adds a FabBar that can minimize in response to marked scroll views.
    ///
    /// Supplying `minimizeBehavior` explicitly opts this bar into
    /// minimization. Use ``fabBarMinimizationScrollTarget()`` in each
    /// scrolling hierarchy that should drive the behavior.
    func fabBar<Value: Hashable>(
        selection: Binding<Value>,
        tabs: [FabBarTab<Value>],
        action: FabBarAction,
        isVisible: Bool = true,
        isActionVisible: Bool = true,
        minimizeBehavior: FabBarMinimizeBehavior
    ) -> some View {
        modifier(
            FabBarModifier(
                selection: selection,
                tabs: tabs,
                action: action,
                isVisible: isVisible,
                isActionVisible: isActionVisible,
                minimizeBehavior: minimizeBehavior,
                bottomAccessoryScope: .none,
                bottomAccessory: EmptyView()
            )
        )
    }

    /// Adds a FabBar with a bottom accessory that moves inline when the bar
    /// minimizes. FabBar supplies the accessory's glass surface and standard
    /// minimum sizing; the builder should provide content without applying
    /// another glass effect or forcing a container height.
    func fabBar<Value: Hashable, BottomAccessory: View>(
        selection: Binding<Value>,
        tabs: [FabBarTab<Value>],
        action: FabBarAction,
        isVisible: Bool = true,
        isActionVisible: Bool = true,
        minimizeBehavior: FabBarMinimizeBehavior = .never,
        bottomAccessoryScope: FabBarBottomAccessoryScope<Value> = .allTabs,
        @ViewBuilder bottomAccessory: () -> BottomAccessory
    ) -> some View {
        modifier(
            FabBarModifier(
                selection: selection,
                tabs: tabs,
                action: action,
                isVisible: isVisible,
                isActionVisible: isActionVisible,
                minimizeBehavior: minimizeBehavior,
                bottomAccessoryScope: bottomAccessoryScope,
                bottomAccessory: bottomAccessory()
            )
        )
    }
}
