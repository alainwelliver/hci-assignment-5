// AI Attribution: Generated with Claude Opus 4.6

import UIKit

@MainActor
final class Haptics {
    static let shared = Haptics()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        prepareAll()
    }

    func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        notification.prepare()
        selection.prepare()
    }

    private var enabled: Bool {
        UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard enabled else { return }
        let gen = (style == .light) ? lightImpact : mediumImpact
        gen.impactOccurred()
        gen.prepare()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        notification.notificationOccurred(type)
        notification.prepare()
    }

    func selectionChanged() {
        guard enabled else { return }
        selection.selectionChanged()
        selection.prepare()
    }
}
