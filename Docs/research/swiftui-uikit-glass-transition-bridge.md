# Bridging FabBar glass and zoom transitions across UIKit and SwiftUI

Date: 2026-08-07

## Executive conclusion

There is no public cross-framework Liquid Glass namespace, identifier, or container API. SwiftUI's `GlassEffectContainer`, `glassEffectID`, and `glassEffectUnion` operate on SwiftUI glass effects extracted from that container's SwiftUI content. UIKit's `UIGlassContainerEffect` combines nested `UIVisualEffectView` instances configured with `UIGlassEffect`; its only public coordination setting is geometric `spacing`. Neither API accepts the other framework's container, namespace, effect, or identifier. This is an inference from Apple's complete public API surfaces in the current Xcode beta SDK, corroborated by Apple's separate SwiftUI and UIKit integration recipes. [SwiftUI `GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer), [SwiftUI `glassEffectUnion`](https://developer.apple.com/documentation/swiftui/view/glasseffectunion(id:namespace:)), [UIKit `UIGlassContainerEffect`](https://developer.apple.com/documentation/uikit/uiglasscontainereffect), [Apple's SwiftUI glass recipe](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views), [WWDC25 UIKit recipe](https://developer.apple.com/videos/play/wwdc2025/284/?time=1400)

Consequently, simply moving a SwiftUI `Button` or `Menu` inline inside a UIKit layout does not make its SwiftUI `glassEffect` participate in the surrounding `UIGlassContainerEffect`. `UIHostingController` embeds SwiftUI content in UIKit and `UIViewRepresentable` embeds a UIKit view in SwiftUI, but neither API promises to merge rendering systems' glass effects. [Apple `UIHostingController`](https://developer.apple.com/documentation/swiftui/uihostingcontroller), [Apple `UIViewRepresentable`](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)

The strongest fully public bridge for FabBar is at the **view-controller transition** level, not the glass-effect level: retain the actual FAB glass as UIKit inside the same `UIGlassContainerEffect` as the segmented control, present the destination SwiftUI view in a `UIHostingController`, and set that controller's `preferredTransition` to `.zoom { ... }`, returning the UIKit FAB source view. Apple explicitly documents that a UIKit zoom source can be a `UIView`, that zoom works for sheets, and that a hosting controller can be presented like any other view controller. [Apple `UIViewController.Transition`](https://developer.apple.com/documentation/uikit/uiviewcontroller/transition), [WWDC24 fluid transitions](https://developer.apple.com/videos/play/wwdc2024/10145/?time=182), [Apple `UIHostingController`](https://developer.apple.com/documentation/swiftui/uihostingcontroller), [Apple `UISheetPresentationController`](https://developer.apple.com/documentation/uikit/uisheetpresentationcontroller)

## What broke in the current implementation

The branch has two independent visible systems at the FAB location: UIKit owns the segmented glass container while a SwiftUI overlay owns the `Menu` and `matchedTransitionSource`. When the SwiftUI overlay owns the visible FAB glass, its geometry is aligned with the UIKit bar but its glass isn't a child effect of the UIKit container, so the two glass surfaces cannot merge. When UIKit's FAB glass is restored, the segmented/FAB merge returns, but SwiftUI's transition source no longer owns that visible UIKit surface and therefore cannot remove it during menu or sheet presentation. The blue blob is the expected outcome of that ownership split. This conclusion follows from the repository hierarchy and Apple's rule that participating UIKit glass effects must be nested under the same UIKit glass container. [UIKit `UIGlassContainerEffect`](https://developer.apple.com/documentation/uikit/uiglasscontainereffect), [WWDC25 container construction](https://developer.apple.com/videos/play/wwdc2025/284/?time=1420)

SwiftUI's `matchedTransitionSource(id:in:)` and `.navigationTransition(.zoom(sourceID:in:))` form a SwiftUI source/destination pair using a SwiftUI `Namespace.ID`; the public overload does not accept a `UIView`. UIKit's zoom transition separately accepts a source-view-provider closure returning a `UIView`. There is no public overload that pairs the SwiftUI destination modifier directly with a UIKit source view. [Apple `matchedTransitionSource`](https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource(id:in:configuration:)), [Apple `ZoomNavigationTransition`](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition), [Apple UIKit zoom transition](https://developer.apple.com/documentation/uikit/uiviewcontroller/transition/zoom(options:sourceviewprovider:))

## Evaluation of the proposed approaches

### 1. Put the SwiftUI action inline inside UIKit

This can improve layout and hit-testing ownership, but hosting alone does not join a SwiftUI glass effect to a UIKit glass container. If the glass remains on an external UIKit `UIVisualEffectView`, a SwiftUI `matchedTransitionSource` around hosted button content still does not own the external glass that must disappear. If the glass remains SwiftUI, it still is not one of the nested UIKit `UIGlassEffect` views that the UIKit container combines. [Apple `UIGlassContainerEffect`](https://developer.apple.com/documentation/uikit/uiglasscontainereffect), [Apple `UIHostingController`](https://developer.apple.com/documentation/swiftui/uihostingcontroller)

Verdict: not a complete fix by itself. A nested-host experiment could be useful, but relying on a SwiftUI namespace across separate hosting roots or on UIKit discovering a SwiftUI-rendered glass surface is not covered by Apple's public contract.

### 2. Share an ID or namespace between SwiftUI and UIKit glass

No public bridge exists. SwiftUI's union and ID modifiers require a SwiftUI `Namespace.ID` and operate with `GlassEffectContainer`; UIKit exposes only `UIGlassEffect`, `UIGlassContainerEffect`, and `spacing`. The current Xcode beta public interfaces expose no conversion, shared identifier, or mixed-framework registration API. [SwiftUI `glassEffectID`](https://developer.apple.com/documentation/swiftui/view/glasseffectid(_:in:)), [SwiftUI `glassEffectUnion`](https://developer.apple.com/documentation/swiftui/view/glasseffectunion(id:namespace:)), [UIKit `UIGlassContainerEffect`](https://developer.apple.com/documentation/uikit/uiglasscontainereffect)

Verdict: unavailable with public API.

There is a viable variation: move **both glass surfaces** into SwiftUI. The existing `UISegmentedControl` can remain UIKit content through `UIViewRepresentable`, while its enclosing surface and the FAB surface both use SwiftUI `glassEffect` inside one `GlassEffectContainer`. Apple documents that representables are SwiftUI views and that a SwiftUI glass container combines glass effects in its content, but it does not specifically guarantee identical interactive-glass feedback when the touch is handled by a represented UIKit control, so this route needs a focused prototype. [Apple `UIViewRepresentable`](https://developer.apple.com/documentation/swiftui/uiviewrepresentable), [Apple's SwiftUI glass recipe](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)

### 3. Keep the FAB UIKit and bridge its morph to SwiftUI content

UIKit's zoom transition is designed for this bridge. `UIViewController.Transition.zoom` requests a source `UIView` and applies to a presented or pushed view controller. `UIHostingController` is a `UIViewController` that hosts SwiftUI, so FabBar can construct one for client-supplied destination content, configure it as a sheet, set its `preferredTransition`, and present it from the nearest UIKit controller. Apple's WWDC24 session says zoom works with sheet and full-screen-cover presentations in both frameworks; WWDC25 specifically recommends the updated zoom transition for morphing a glass source into a sheet. [Apple UIKit zoom](https://developer.apple.com/documentation/uikit/uiviewcontroller/transition/zoom(options:sourceviewprovider:)), [WWDC24](https://developer.apple.com/videos/play/wwdc2024/10145/?time=182), [WWDC25](https://developer.apple.com/videos/play/wwdc2025/284/?time=795)

This route does require FabBar to own presentation (or provide a presentation modifier that owns it). An arbitrary client `.sheet` creates and manages its controller inside SwiftUI, and the public SwiftUI sheet API does not expose that generated controller so a library can assign a UIKit `preferredTransition`. Conversely, UIKit can explicitly present a `UIHostingController` and configure its `UISheetPresentationController` detents before presentation. [Apple `UIHostingController`](https://developer.apple.com/documentation/swiftui/uihostingcontroller), [Apple `UISheetPresentationController`](https://developer.apple.com/documentation/uikit/uisheetpresentationcontroller)

Verdict: the most strongly documented route for retaining UIKit glass merging and obtaining a real UIKit-source-to-SwiftUI-destination sheet morph. Its cost is a larger FabBar presentation API and ownership of sheet lifecycle, detents, dismissal state, and environment propagation.

## Menus

Assigning `UIButton.menu` automatically enables the button's context-menu interaction. With `showsMenuAsPrimaryAction == false`, the control keeps its primary tap action while the menu remains a secondary/hold interaction; UIKit also exposes `isHeld` while the menu is visible. [Apple `UIButton.menu`](https://developer.apple.com/documentation/uikit/uibutton/menu), [Apple `showsMenuAsPrimaryAction`](https://developer.apple.com/documentation/uikit/uicontrol/showsmenuasprimaryaction), [Apple `UIButton.isHeld`](https://developer.apple.com/documentation/uikit/uibutton/isheld)

Apple states that menus originating from glass buttons receive the button-to-overlay morph automatically. For FabBar, the important detail is that the menu's source must include the actual visible glass. If the `UIButton` is only transparent content inside a separate parent `UIVisualEffectView`, the automatic control preview may not own the parent glass; that is consistent with the current blue-blob result. A UIKit implementation can instead make the actual glass source participate in the context-menu interaction and provide `UITargetedPreview` for the glass view through the documented context-menu delegate hooks. [WWDC25 presentations](https://developer.apple.com/videos/play/wwdc2025/284/?time=795), [Apple `UIContextMenuInteractionDelegate`](https://developer.apple.com/documentation/uikit/uicontextmenuinteractiondelegate), [Apple `UITargetedPreview`](https://developer.apple.com/documentation/uikit/uitargetedpreview)

## Recommendation

1. Revert the experimental state where UIKit glass remains visible behind a SwiftUI transition source; it necessarily leaves two owners for one visual object.
2. Prototype the all-UIKit-source route first: both glass elements remain nested in the current `UIGlassContainerEffect`; the menu interaction targets the actual FAB glass; a FabBar-owned presenter wraps destination SwiftUI in `UIHostingController` and uses UIKit `.zoom(sourceViewProvider:)` for the sheet.
3. If preserving arbitrary client `.sheet` composition is non-negotiable, prototype moving both glass surfaces to one SwiftUI `GlassEffectContainer` while retaining the segmented control through `UIViewRepresentable`. This preserves SwiftUI `Menu` and `matchedTransitionSource`, but carries higher visual/interaction-regression risk around the segmented control.
4. Do not invest further in a shared UIKit/SwiftUI glass namespace or in hiding/showing one of two overlapping surfaces around presentation; no public API supports the former, and the latter is lifecycle-sensitive coordination rather than a single morphing source.

## Local SDK verification

The current Xcode beta SDK was checked in addition to the linked Apple documentation:

- `UIKit.framework/Headers/UIGlassEffect.h` exposes `UIGlassEffect`, `UIGlassContainerEffect`, and `spacing`, with the nesting requirement in its public comments.
- `SwiftUICore.framework/.../SwiftUICore.swiftinterface` exposes `GlassEffectContainer`, `glassEffect`, `glassEffectID`, and `glassEffectUnion`, all as SwiftUI view APIs.
- `UIKit.framework/Headers/UIViewControllerTransition.h` documents zooming from a provided `UIView` to a presented or pushed view controller.
- `SwiftUI.framework/.../SwiftUI.swiftinterface` confirms `UIHostingController` inherits `UIViewController`, and that SwiftUI `matchedTransitionSource` uses `Namespace.ID`.
- `UIKit.framework/Headers/UIControl.h` and `UIButton.h` expose context-menu callbacks, `showsMenuAsPrimaryAction`, `menu`, and `isHeld`.
