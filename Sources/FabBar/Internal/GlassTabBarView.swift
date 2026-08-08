import UIKit

/// The root UIKit view that assembles the tab bar with glass effects.
/// Uses UIGlassContainerEffect to enable morphing between the segmented control and FAB.
@available(iOS 26.0, *)
final class GlassTabBarView: UIView {
    let containerEffectView: UIVisualEffectView
    let segmentedGlassView: UIVisualEffectView
    let segmentedControl: TabBarSegmentedControl
    let compactTabButton: UIButton
    let fabGlassView: UIVisualEffectView
    let fabButton: FabBarActionButton

    private let spacing: CGFloat = Constants.fabSpacing
    private let contentPadding: CGFloat = Constants.contentPadding

    private(set) var tabCount: Int
    private var segmentedTrailingConstraint: NSLayoutConstraint?
    private var segmentedCompactWidthConstraint: NSLayoutConstraint?
    private var segmentedTopConstraint: NSLayoutConstraint?
    private var segmentedBottomConstraint: NSLayoutConstraint?
    private var fabTopConstraint: NSLayoutConstraint?
    private var fabBottomConstraint: NSLayoutConstraint?
    private var isMinimized = false

    var isSegmentedTrailingConstraintActive: Bool {
        segmentedTrailingConstraint?.isActive == true
    }

    private static let primaryActionIdentifier = UIAction.Identifier(
        "FabBar.primaryAction"
    )
    private static let expandActionIdentifier = UIAction.Identifier(
        "FabBar.expandAction"
    )

    init(
        segmentedControl: TabBarSegmentedControl,
        tabCount: Int,
        action: FabBarAction
    ) {
        self.segmentedControl = segmentedControl
        self.tabCount = tabCount

        // Create glass container effect for morphing
        let containerEffect = UIGlassContainerEffect()
        containerEffect.spacing = Constants.fabSpacing
        containerEffectView = UIVisualEffectView(effect: containerEffect)

        // Create segmented control glass effect
        let segmentedGlassEffect = UIGlassEffect()
        segmentedGlassEffect.isInteractive = true
        segmentedGlassView = UIVisualEffectView(effect: segmentedGlassEffect)

        let compactButton = UIButton(type: .system)
        compactButton.tintColor = .tintColor
        compactButton.alpha = 0
        compactButton.isHidden = true
        compactButton.accessibilityTraits = .button
        compactTabButton = compactButton

        // Create FAB button
        let fabGlassEffect = UIGlassEffect()
        fabGlassEffect.isInteractive = true
        fabGlassEffect.tintColor = .tintColor
        fabGlassView = UIVisualEffectView(effect: fabGlassEffect)

        let button = FabBarActionButton(type: .system)
        button.tintColor = .white
        button.accessibilityTraits = .button
        fabButton = button

        super.init(frame: .zero)

        // Ensure tint adjustment mode is automatic so views dim when sheets are presented
        tintAdjustmentMode = .automatic
        fabGlassView.tintAdjustmentMode = .automatic
        fabButton.tintAdjustmentMode = .automatic
        fabButton.menuPreviewView = fabGlassView

        setupViews()
        updateAction(action)
    }

    private func setupViews() {
        // Add container effect view
        addSubview(containerEffectView)
        containerEffectView.translatesAutoresizingMaskIntoConstraints = false

        // Add segmented glass view to container's contentView
        containerEffectView.contentView.addSubview(segmentedGlassView)
        segmentedGlassView.translatesAutoresizingMaskIntoConstraints = false

        // Add segmented control to segmented glass view's contentView
        segmentedGlassView.contentView.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        segmentedGlassView.contentView.addSubview(compactTabButton)
        compactTabButton.translatesAutoresizingMaskIntoConstraints = false

        // Add FAB glass view
        containerEffectView.contentView.addSubview(fabGlassView)
        fabGlassView.translatesAutoresizingMaskIntoConstraints = false

        fabGlassView.contentView.addSubview(fabButton)
        fabButton.translatesAutoresizingMaskIntoConstraints = false

        // Extra bottom inset compensates for UISegmentedControl's internal padding,
        // visually centering the content within the glass container.
        let segmentedControlBottomInsetAdjustment: CGFloat = 1

        segmentedTopConstraint = segmentedGlassView.topAnchor.constraint(
            equalTo: containerEffectView.contentView.topAnchor
        )
        segmentedBottomConstraint = segmentedGlassView.bottomAnchor.constraint(
            equalTo: containerEffectView.contentView.bottomAnchor
        )
        fabTopConstraint = fabGlassView.topAnchor.constraint(
            equalTo: containerEffectView.contentView.topAnchor
        )
        fabBottomConstraint = fabGlassView.bottomAnchor.constraint(
            equalTo: containerEffectView.contentView.bottomAnchor
        )
        segmentedCompactWidthConstraint = segmentedGlassView.widthAnchor.constraint(
            equalToConstant: Constants.compactControlSize
        )

        NSLayoutConstraint.activate([
            containerEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerEffectView.topAnchor.constraint(equalTo: topAnchor),
            containerEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            segmentedGlassView.leadingAnchor.constraint(equalTo: containerEffectView.contentView.leadingAnchor),
            segmentedTopConstraint!,
            segmentedBottomConstraint!,

            segmentedControl.leadingAnchor.constraint(equalTo: segmentedGlassView.contentView.leadingAnchor, constant: contentPadding),
            segmentedControl.trailingAnchor.constraint(equalTo: segmentedGlassView.contentView.trailingAnchor, constant: -contentPadding),
            segmentedControl.topAnchor.constraint(equalTo: segmentedGlassView.contentView.topAnchor, constant: contentPadding),
            segmentedControl.bottomAnchor.constraint(equalTo: segmentedGlassView.contentView.bottomAnchor, constant: -contentPadding - segmentedControlBottomInsetAdjustment),

            compactTabButton.leadingAnchor.constraint(equalTo: segmentedGlassView.contentView.leadingAnchor),
            compactTabButton.trailingAnchor.constraint(equalTo: segmentedGlassView.contentView.trailingAnchor),
            compactTabButton.topAnchor.constraint(equalTo: segmentedGlassView.contentView.topAnchor),
            compactTabButton.bottomAnchor.constraint(equalTo: segmentedGlassView.contentView.bottomAnchor),

            // FAB glass view
            fabGlassView.trailingAnchor.constraint(equalTo: containerEffectView.contentView.trailingAnchor),
            fabTopConstraint!,
            fabBottomConstraint!,
            fabGlassView.widthAnchor.constraint(equalTo: fabGlassView.heightAnchor),

            // Fill the entire glass area so taps anywhere trigger the action
            fabButton.leadingAnchor.constraint(equalTo: fabGlassView.contentView.leadingAnchor),
            fabButton.trailingAnchor.constraint(equalTo: fabGlassView.contentView.trailingAnchor),
            fabButton.topAnchor.constraint(equalTo: fabGlassView.contentView.topAnchor),
            fabButton.bottomAnchor.constraint(equalTo: fabGlassView.contentView.bottomAnchor),
        ])

        // Set up the trailing constraint based on tab count
        segmentedTrailingConstraint = makeSegmentedTrailingConstraint()
        segmentedTrailingConstraint?.isActive = true
    }

    func updateAction(_ action: FabBarAction) {
        fabButton.removeAction(
            identifiedBy: Self.primaryActionIdentifier,
            for: .touchUpInside
        )
        fabButton.addAction(
            UIAction(identifier: Self.primaryActionIdentifier) { _ in
                action.action()
            },
            for: .touchUpInside
        )

        fabButton.accessibilityLabel = action.accessibilityLabel
        fabButton.accessibilityIdentifier = action.accessibilityIdentifier
        fabButton.setImage(
            menuImage(
                systemImage: action.systemImage,
                image: nil,
                imageBundle: nil,
                pointSize: Constants.fabIconPointSize
            ),
            for: .normal
        )
        fabButton.showsMenuAsPrimaryAction = false
        fabButton.preferredMenuElementOrder = .fixed
        fabButton.menu = action.menuItems.isEmpty
            ? nil
            : UIMenu(
                options: .displayInline,
                children: action.menuItems.map(makeMenuAction)
            )
    }

    func updateExpandAction(_ action: @escaping () -> Void) {
        compactTabButton.removeAction(
            identifiedBy: Self.expandActionIdentifier,
            for: .touchUpInside
        )
        compactTabButton.addAction(
            UIAction(identifier: Self.expandActionIdentifier) { _ in action() },
            for: .touchUpInside
        )
    }

    func updateCompactTab(
        title: String,
        systemImage: String?,
        image: String?,
        imageBundle: Bundle?
    ) {
        compactTabButton.accessibilityLabel = title
        compactTabButton.setImage(
            menuImage(
                systemImage: systemImage,
                image: image,
                imageBundle: imageBundle,
                pointSize: Constants.tabIconPointSize
            ),
            for: .normal
        )
    }

    func setMinimized(_ minimized: Bool, animated: Bool) {
        guard minimized != isMinimized else { return }
        isMinimized = minimized

        if !minimized {
            segmentedControl.isHidden = false
        } else {
            compactTabButton.isHidden = false
        }

        segmentedTrailingConstraint?.isActive = !minimized
        segmentedCompactWidthConstraint?.isActive = minimized

        let compactInset = (Constants.barHeight - Constants.compactControlSize) / 2
        segmentedTopConstraint?.constant = minimized ? compactInset : 0
        segmentedBottomConstraint?.constant = minimized ? -compactInset : 0
        fabTopConstraint?.constant = minimized ? compactInset : 0
        fabBottomConstraint?.constant = minimized ? -compactInset : 0

        let changes = {
            self.segmentedControl.alpha = minimized ? 0 : 1
            self.compactTabButton.alpha = minimized ? 1 : 0
            self.layoutIfNeeded()
        }
        let completion: (Bool) -> Void = { _ in
            self.segmentedControl.isHidden = minimized
            self.compactTabButton.isHidden = !minimized
        }

        guard animated else {
            changes()
            completion(true)
            return
        }

        if UIAccessibility.isReduceMotionEnabled {
            UIView.animate(
                withDuration: 0.2,
                animations: changes,
                completion: completion
            )
        } else {
            UIView.animate(
                withDuration: 0.45,
                delay: 0,
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: changes,
                completion: completion
            )
        }
    }

    private func makeMenuAction(for item: FabBarMenuItem) -> UIAction {
        UIAction(
            title: item.title,
            image: menuImage(for: item)
        ) { _ in
            item.action()
        }
    }

    private func menuImage(for item: FabBarMenuItem) -> UIImage? {
        switch item.icon {
        case .system(let systemImage):
            menuImage(
                systemImage: systemImage,
                image: nil,
                imageBundle: nil,
                pointSize: nil
            )
        case .asset(let image, let bundle):
            menuImage(
                systemImage: nil,
                image: image,
                imageBundle: bundle,
                pointSize: nil
            )
        }
    }

    private func menuImage(
        systemImage: String?,
        image: String?,
        imageBundle: Bundle?,
        pointSize: CGFloat?
    ) -> UIImage? {
        let configuration = pointSize.map {
            UIImage.SymbolConfiguration(pointSize: $0, weight: .medium)
        }

        if let systemImage {
            return UIImage(
                systemName: systemImage,
                withConfiguration: configuration
            )
        }

        guard let image else { return nil }

        return UIImage(
            named: image,
            in: imageBundle ?? .main,
            with: configuration
        )
    }

    /// Creates the appropriate trailing constraint for the segmented glass view.
    /// For 3+ tabs, fills to the FAB. For fewer tabs, floats leading-aligned.
    private func makeSegmentedTrailingConstraint() -> NSLayoutConstraint {
        if tabCount >= 3 {
            segmentedGlassView.trailingAnchor.constraint(equalTo: fabGlassView.leadingAnchor, constant: -spacing)
        } else {
            segmentedGlassView.trailingAnchor.constraint(lessThanOrEqualTo: fabGlassView.leadingAnchor, constant: -spacing)
        }
    }

    /// Updates the tab count and swaps the trailing constraint to match.
    func updateTabCount(_ newCount: Int) {
        guard newCount != tabCount else { return }
        tabCount = newCount
        segmentedTrailingConstraint?.isActive = false
        segmentedTrailingConstraint = makeSegmentedTrailingConstraint()
        segmentedTrailingConstraint?.isActive = !isMinimized
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Capsule shape for segmented control
        segmentedGlassView.cornerConfiguration = .capsule()

        // Circle shape for FAB button (capsule with equal width/height = circle)
        fabGlassView.cornerConfiguration = .capsule()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isMinimized else {
            return super.point(inside: point, with: event)
        }

        let leadingControlFrame = segmentedGlassView.convert(
            segmentedGlassView.bounds,
            to: self
        )
        let trailingControlFrame = fabGlassView.convert(
            fabGlassView.bounds,
            to: self
        )

        return leadingControlFrame.contains(point) || trailingControlFrame.contains(point)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateFabGlassEffect()
    }

    private func updateFabGlassEffect() {
        // Create a new effect since modifying the existing tint doesn't
        // reliably update its visuals.
        let newEffect = UIGlassEffect()
        newEffect.isInteractive = true
        newEffect.tintColor = tintColor
        fabGlassView.effect = newEffect
    }
}
