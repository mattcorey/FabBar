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
struct FabBarSheetPresenter<PresentationID: Hashable, SheetContent: View>:
    UIViewControllerRepresentable {
    let presentationID: PresentationID?
    let source: FabBarSheetSource
    let configuration: FabBarSheetConfiguration
    let onDismiss: (() -> Void)?
    let sheetContent: () -> SheetContent?
    let dismissPresentation: (PresentationID) -> Void

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
        private var presentedPresentationID: PresentationID?
        private var dismissedPresentationID: PresentationID?
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
            guard let presentationID = parent.presentationID,
                  let content = parent.sheetContent() else {
                dismissedPresentationID = nil
                dismissPresentedController()
                return
            }

            guard presentationID != dismissedPresentationID else { return }
            dismissedPresentationID = nil

            if let presentedController {
                presentedController.rootView = content
                applyConfiguration(to: presentedController)
                presentedPresentationID = presentationID
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
                rootView: content
            )
            controller.lifecycleDelegate = self
            controller.modalPresentationStyle = .pageSheet
            controller.preferredTransition = .zoom { [weak source = parent.source] _ in
                source?.view
            }
            applyConfiguration(to: controller)

            presentedController = controller
            presentedPresentationID = presentationID

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

        private func applyConfiguration(
            to controller: FabBarHostingController<SheetContent>
        ) {
            configuration.apply(to: controller)

            guard let sheet = controller.sheetPresentationController else {
                return
            }

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

            let shouldUpdateBinding = updatesBinding && !isDismissing
            let dismissedPresentationID = presentedPresentationID
            presentedController = nil
            presentedPresentationID = nil
            isPresenting = false
            isDismissing = false

            if shouldUpdateBinding, let dismissedPresentationID {
                self.dismissedPresentationID = dismissedPresentationID
                parent.dismissPresentation(dismissedPresentationID)
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
extension FabBarSheetConfiguration {
    func apply(to controller: UIViewController) {
        controller.isModalInPresentation = isModalInPresentation

        guard let sheet = controller.sheetPresentationController else {
            return
        }

        sheet.detents = uiKitDetents
        sheet.prefersGrabberVisible = prefersGrabberVisible
    }

    private var uiKitDetents: [UISheetPresentationController.Detent] {
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
struct FabBarMorphingItemSheetModifier<Item: Identifiable, SheetContent: View>:
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
                    presentationID: item?.id,
                    source: source,
                    configuration: configuration,
                    onDismiss: onDismiss,
                    sheetContent: {
                        item.map(sheetContent)
                    },
                    dismissPresentation: { dismissedID in
                        guard item?.id == dismissedID else { return }
                        item = nil
                    }
                )
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            }
    }
}

@available(iOS 26.0, *)
struct FabBarMorphingBooleanSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool

    let configuration: FabBarSheetConfiguration
    let onDismiss: (() -> Void)?
    let sheetContent: () -> SheetContent

    @State private var source = FabBarSheetSource()

    func body(content: Content) -> some View {
        content
            .environment(\.fabBarSheetSource, source)
            .background {
                FabBarSheetPresenter(
                    presentationID: isPresented ? true : nil,
                    source: source,
                    configuration: configuration,
                    onDismiss: onDismiss,
                    sheetContent: {
                        isPresented ? sheetContent() : nil
                    },
                    dismissPresentation: { _ in
                        isPresented = false
                    }
                )
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            }
    }
}
