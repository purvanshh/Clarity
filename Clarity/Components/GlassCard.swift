import SwiftUI
import AppKit

// MARK: - Design tokens (single source of truth)

enum ClarityChrome {
    static let cornerRadius: CGFloat = 20
    static let panelWidth: CGFloat = 420
    /// Stable shell height so navigation + footer never jump when switching tabs.
    static let panelHeight: CGFloat = 448
    static let footerHeight: CGFloat = 36
}

// MARK: - Window chrome

/// Clears MenuBarExtra panel chrome so native vibrancy can sample the desktop.
enum MenuBarGlassWindow {
    @MainActor
    static func configureIfNeeded() {
        for window in NSApp.windows where shouldConfigure(window) {
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.hasShadow = true

            if let content = window.contentView {
                content.wantsLayer = true
                content.layer?.backgroundColor = NSColor.clear.cgColor
                content.layer?.isOpaque = false
                content.layer?.cornerRadius = ClarityChrome.cornerRadius
                content.layer?.masksToBounds = true

                for subview in content.subviews {
                    subview.wantsLayer = true
                    subview.layer?.backgroundColor = NSColor.clear.cgColor
                    if let effect = subview as? NSVisualEffectView {
                        effect.blendingMode = .behindWindow
                        effect.state = .followsWindowActiveState
                        effect.isEmphasized = true
                        effect.wantsLayer = true
                        effect.layer?.cornerRadius = ClarityChrome.cornerRadius
                        effect.layer?.masksToBounds = true
                    }
                }
            }
        }
    }

    @MainActor
    private static func shouldConfigure(_ window: NSWindow) -> Bool {
        if window.styleMask.contains(.borderless) { return true }
        let name = String(describing: type(of: window))
        if name.localizedCaseInsensitiveContains("status") { return true }
        if name.localizedCaseInsensitiveContains("menubar") { return true }
        if name.localizedCaseInsensitiveContains("panel") { return true }
        return NSApp.activationPolicy() == .accessory
            && window.frame.width > 200
            && window.frame.width < 640
    }
}

// MARK: - Single glass surface

struct GlassVisualEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        view.isEmphasized = true
        view.wantsLayer = true
        view.layer?.cornerRadius = ClarityChrome.cornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = .behindWindow
        nsView.state = .followsWindowActiveState
        nsView.isEmphasized = true
        nsView.layer?.cornerRadius = ClarityChrome.cornerRadius
        nsView.layer?.masksToBounds = true
    }
}

/// ONE outer glass surface for the popover. No nested competing rounded panels.
struct NativeGlassBackground: View {
    var body: some View {
        ZStack {
            // Deep behind-window blur (desktop / Xcode visibly softens through).
            GlassVisualEffect(material: .hudWindow)
            // Lighter vibrancy layer for luminosity without darkening.
            GlassVisualEffect(material: .popover)
                .opacity(0.45)
            // Soft system material wash — not an opaque dark overlay.
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.35)

            if #available(macOS 26.0, *) {
                // Liquid Glass refraction on the surface only; never receives hits.
                Color.clear
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: ClarityChrome.cornerRadius))
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
    }
}

struct GlassEdgeHighlight: View {
    var body: some View {
        RoundedRectangle(cornerRadius: ClarityChrome.cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.34),
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.8
            )
            .allowsHitTesting(false)
    }
}

/// Selected-state capsule drawn *behind* controls (never intercepts clicks).
struct GlassSelectionCapsule: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .allowsHitTesting(false)
    }
}

/// Track behind a segmented control (non-interactive).
struct GlassTrack: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.55))
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .allowsHitTesting(false)
    }
}

/// Compact elevated inset for the inline add-task composer.
struct GlassSurface<Content: View>: View {
    var cornerRadius: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
    }
}

struct ClearMenuBarContainerBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.containerBackground(.clear, for: .window)
        } else {
            content
        }
    }
}

extension View {
    func clearMenuBarContainerBackground() -> some View {
        modifier(ClearMenuBarContainerBackground())
    }
}
