import UIKit

/// UIKit action button whose context-menu preview includes its glass surface.
@available(iOS 26.0, *)
final class FabBarActionButton: UIButton {
    weak var menuPreviewView: UIView?

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        targetedPreview()
            ?? super.contextMenuInteraction(
                interaction,
                previewForHighlightingMenuWithConfiguration: configuration
            )
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        targetedPreview()
            ?? super.contextMenuInteraction(
                interaction,
                previewForDismissingMenuWithConfiguration: configuration
            )
    }

    private func targetedPreview() -> UITargetedPreview? {
        guard let menuPreviewView else { return nil }

        let parameters = UIPreviewParameters()
        parameters.visiblePath = UIBezierPath(
            roundedRect: menuPreviewView.bounds,
            cornerRadius: menuPreviewView.bounds.height / 2
        )
        return UITargetedPreview(view: menuPreviewView, parameters: parameters)
    }
}
