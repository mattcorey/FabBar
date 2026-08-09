#if os(iOS)

import Foundation

/// A supported resting height for a sheet presented from the FabBar action.
@available(iOS 26.0, *)
public enum FabBarSheetDetent: Hashable, Sendable {
    case medium
    case large
}

/// UIKit-backed presentation options for a morphing FabBar sheet.
@available(iOS 26.0, *)
public struct FabBarSheetConfiguration: Hashable, Sendable {
    /// The heights where the sheet can rest, ordered from smallest to largest.
    public let detents: [FabBarSheetDetent]

    /// Whether the system sheet displays its drag indicator.
    public let prefersGrabberVisible: Bool

    /// Whether the sheet prevents interactive dismissal.
    public let isModalInPresentation: Bool

    public init(
        detents: [FabBarSheetDetent] = [.large],
        prefersGrabberVisible: Bool = false,
        isModalInPresentation: Bool = false
    ) {
        self.detents = detents.isEmpty ? [.large] : detents
        self.prefersGrabberVisible = prefersGrabberVisible
        self.isModalInPresentation = isModalInPresentation
    }
}

#endif
