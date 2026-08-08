import SwiftUI
import UIKit

@available(iOS 26.0, *)
@MainActor
protocol FabBarPresentationHostDelegate: AnyObject {
    func fabBarPresentationHostDidAppear(
        _ host: FabBarPresentationHostViewController
    )
}

@available(iOS 26.0, *)
final class FabBarPresentationHostViewController: UIViewController {
    weak var readinessDelegate: (any FabBarPresentationHostDelegate)?

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        self.view = view
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readinessDelegate?.fabBarPresentationHostDidAppear(self)
    }
}

@available(iOS 26.0, *)
@MainActor
protocol FabBarHostedSheetDelegate: AnyObject {
    func fabBarHostedSheetDidDisappear(_ controller: UIViewController)
}

@available(iOS 26.0, *)
final class FabBarHostingController<Content: View>:
    UIHostingController<Content> {
    weak var lifecycleDelegate: (any FabBarHostedSheetDelegate)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard isBeingDismissed || presentingViewController == nil else {
            return
        }
        lifecycleDelegate?.fabBarHostedSheetDidDisappear(self)
    }
}

/// Presents client-provided SwiftUI content from the UIKit FAB source view.
@available(iOS 26.0, *)
struct FabBarSheetPresenter<Item: Identifiable, SheetContent: View>:
    UIViewControllerRepresentable {
    @Binding var item: Item?

    let source: FabBarSheetSource
    let configuration: FabBarSheetConfiguration
    let onDismiss: (() -> Void)?
    let sheetContent: (Item) -> SheetContent

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let host = FabBarPresentationHostViewController()
        host.readinessDelegate = context.coordinator
        context.coordinator.host = host
        context.coordinator.connect(to: source)
        return host
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {
        context.coordinator.parent = self
        context.coordinator.connect(to: source)
        context.coordinator.updatePresentation()
    }

    static func dismantleUIViewController(
        _ uiViewController: UIViewController,
        coordinator: Coordinator
    ) {
        coordinator.disconnect()
        coordinator.dismissImmediately()
    }

    @MainActor
    final class Coordinator: NSObject,
        UIAdaptivePresentationControllerDelegate,
        UISheetPresentationControllerDelegate,
        FabBarHostedSheetDelegate,
        FabBarPresentationHostDelegate,
        FabBarSheetSourceObserver {
        var parent: FabBarSheetPresenter
        weak var host: FabBarPresentationHostViewController?

        private weak var connectedSource: FabBarSheetSource?
        private var presentedController: FabBarHostingController<SheetContent>?
        private var presentedItemID: Item.ID?
        private var isPresenting = false
        private var isDismissing = false

        init(parent: FabBarSheetPresenter) {
            self.parent = parent
        }

        func connect(to source: FabBarSheetSource) {
            guard connectedSource !== source else { return }
            disconnect()
            connectedSource = source
            source.observer = self
        }

        func disconnect() {
            if connectedSource?.observer === self {
                connectedSource?.observer = nil
            }
            connectedSource = nil
        }

        func updatePresentation() {
            guard let item = parent.item else {
                dismissPresentedController()
                return
            }

            if let presentedController {
                if presentedItemID != item.id {
                    presentedController.rootView = parent.sheetContent(item)
                    presentedItemID = item.id
                }
                return
            }

            guard !isPresenting,
                  !isDismissing,
                  let host,
                  let sourceView = parent.source.view,
                  sourceView.window != nil,
                  let presenter = presentingController(for: host) else {
                return
            }

            isPresenting = true
            let controller = FabBarHostingController(
                rootView: parent.sheetContent(item)
            )
            controller.lifecycleDelegate = self
            controller.modalPresentationStyle = .pageSheet
            controller.isModalInPresentation = configuration.isModalInPresentation
            controller.preferredTransition = .zoom { [weak source = parent.source] _ in
                source?.view
            }
            configureSheet(controller)

            presentedController = controller
            presentedItemID = item.id
            controller.presentationController?.delegate = self

            presenter.present(controller, animated: true) { [weak self] in
                guard let self else { return }
                self.isPresenting = false
                self.updatePresentation()
            }
        }

        func dismissImmediately() {
            guard let presentedController else { return }
            presentedController.dismiss(animated: false)
            clearPresentation(for: presentedController, updatesBinding: false)
        }

        func presentationControllerDidDismiss(
            _ presentationController: UIPresentationController
        ) {
            clearPresentation(
                for: presentationController.presentedViewController,
                updatesBinding: true
            )
        }

        func fabBarHostedSheetDidDisappear(_ controller: UIViewController) {
            clearPresentation(for: controller, updatesBinding: true)
        }

        func fabBarPresentationHostDidAppear(
            _ host: FabBarPresentationHostViewController
        ) {
            updatePresentation()
        }

        func fabBarSheetSourceDidChange(_ source: FabBarSheetSource) {
            updatePresentation()
        }

        private var configuration: FabBarSheetConfiguration {
            parent.configuration
        }

        private func configureSheet(
            _ controller: FabBarHostingController<SheetContent>
        ) {
            guard let sheet = controller.sheetPresentationController else {
                return
            }

            sheet.detents = configuration.uiKitDetents
            sheet.prefersGrabberVisible = configuration.prefersGrabberVisible
            sheet.delegate = self
        }

        private func dismissPresentedController() {
            guard let presentedController,
                  !isDismissing else {
                return
            }

            isDismissing = true
            presentedController.dismiss(animated: true) { [weak self, weak presentedController] in
                guard let self, let presentedController else { return }
                self.clearPresentation(
                    for: presentedController,
                    updatesBinding: false
                )
            }
        }

        private func clearPresentation(
            for controller: UIViewController,
            updatesBinding: Bool
        ) {
            guard controller === presentedController else { return }

            let dismissedItemID = presentedItemID
            presentedController = nil
            presentedItemID = nil
            isPresenting = false
            isDismissing = false

            if updatesBinding,
               let currentItem = parent.item,
               currentItem.id == dismissedItemID {
                parent.item = nil
            }

            parent.onDismiss?()
            updatePresentation()
        }

        private func presentingController(
            for host: UIViewController
        ) -> UIViewController? {
            guard host.viewIfLoaded?.window != nil else { return nil }

            var presenter = host
            while let parent = presenter.parent {
                presenter = parent
            }

            guard presenter.presentedViewController == nil else {
                return nil
            }
            return presenter
        }
    }
}

@available(iOS 26.0, *)
@MainActor
private extension FabBarSheetConfiguration {
    var uiKitDetents: [UISheetPresentationController.Detent] {
        var result: [UISheetPresentationController.Detent] = []

        if detents.contains(.medium) {
            result.append(.medium())
        }
        if detents.contains(.large) {
            result.append(.large())
        }

        return result.isEmpty ? [.large()] : result
    }
}

/// Installs an opt-in sheet presenter that morphs from the FabBar action.
@available(iOS 26.0, *)
struct FabBarMorphingSheetModifier<Item: Identifiable, SheetContent: View>:
    ViewModifier {
    @Binding var item: Item?

    let configuration: FabBarSheetConfiguration
    let onDismiss: (() -> Void)?
    let sheetContent: (Item) -> SheetContent

    @State private var source = FabBarSheetSource()

    func body(content: Content) -> some View {
        content
            .environment(\.fabBarSheetSource, source)
            .background {
                FabBarSheetPresenter(
                    item: $item,
                    source: source,
                    configuration: configuration,
                    onDismiss: onDismiss,
                    sheetContent: sheetContent
                )
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            }
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Presents SwiftUI content in a sheet that morphs from the FabBar action.
    ///
    /// Apply this modifier after ``fabBar(selection:tabs:action:isVisible:minimizeBehavior:)``
    /// or its bottom-accessory overload. Apps that prefer a standard sheet can
    /// omit this modifier and continue using SwiftUI's `sheet` modifiers.
    func fabBarMorphingSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        configuration: FabBarSheetConfiguration = FabBarSheetConfiguration(),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(
            FabBarMorphingSheetModifier(
                item: item,
                configuration: configuration,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }
}
