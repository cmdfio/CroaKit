import SwiftUI

/// One vector character, with a continuously deforming face and a light Metal body rig.
public struct CroaFrog: View {
    private let artworkWidth: CGFloat
    private let animationsEnabled: Bool

    /// A self-contained mascot. Tap to wink; long press to jump.
    /// Automatic motion respects Reduce Motion, scene activity and visibility.
    public init(width: CGFloat = 36.96, animationsEnabled: Bool = true) {
        self.artworkWidth = width.isFinite && width > 0 ? width : 36.96
        self.animationsEnabled = animationsEnabled
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false
    @State private var isAnimating = false
    @State private var winkRequest = 0
    @State private var jumpRequest = 0
    @State private var expression = Expression.blink
    @State private var leftEyeClosure: CGFloat = 0
    @State private var rightEyeClosure: CGFloat = 0
    @State private var yawn: CGFloat = 0
    @State private var croak: CGFloat = 0
    @State private var croakPuff: CGFloat = 0
    @State private var breath: CGFloat = 0
    @State private var jumpProgress: CGFloat = 0

    private enum Expression { case blink, wink, yawn, croak, jump }
    private var canAnimate: Bool { isVisible && scenePhase == .active }
    private var usesMotion: Bool { animationsEnabled && !reduceMotion }
    private var animatesAutomatically: Bool { canAnimate && usesMotion }

    public var body: some View {
        GeometryReader { geometry in
            FrogVectorRig(size: geometry.size,
                          leftEyeClosure: leftEyeClosure, rightEyeClosure: rightEyeClosure,
                          isWink: expression == .wink, yawn: yawn, croak: croak,
                          puff: croakPuff, breath: breath,
                          jumpProgress: jumpProgress, isJumping: isAnimating && expression == .jump,
                          usesMotion: usesMotion)
        }
        .aspectRatio(270.0 / 299, contentMode: .fit)
        .frame(width: artworkWidth)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        // Exclusive recognition prevents a long press from also playing a wink.
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .exclusively(before: TapGesture())
                .onEnded { gesture in
                    switch gesture {
                    case .first(true): requestJump()
                    case .second: wink()
                    default: break
                    }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Grenouille Francophile")
        .accessibilityHint("Touchez pour un clin d’œil. Maintenez pour un saut.")
        .accessibilityIdentifier("croakit.frog")
        .accessibilityAction { wink() }
        .accessibilityAction(named: Text("Faire un saut")) { requestJump() }
        // Reserve the flight above the original layout, including outside a
        // ScrollView. Appearing on screen must enable a standalone mascot too.
        .padding(.top, artworkWidth * 0.32)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .onScrollVisibilityChange(threshold: 0.5) { isVisible = $0 }
        .onChange(of: canAnimate) { _, active in
            if !active { winkRequest = 0; jumpRequest = 0 }
        }
        .task(id: animatesAutomatically) {
            guard animatesAutomatically else { return }
            await breathe()
        }
        .task(id: animatesAutomatically) {
            guard animatesAutomatically else { return }
            let clock = ContinuousClock()
            var deadline = clock.now
            var blinksUntilGesture = Int.random(in: 3...5)
            let gestures: [Expression] = [.yawn, .croak, .jump]
            var nextGesture = Int.random(in: gestures.indices)
            do {
                while !Task.isCancelled {
                    deadline = deadline.advanced(by: .seconds(Double.random(in: 3...5)))
                    try await clock.sleep(until: deadline)
                    if blinksUntilGesture == 0 {
                        await animate(gestures[nextGesture])
                        nextGesture = (nextGesture + 1) % gestures.count
                        blinksUntilGesture = Int.random(in: 3...5)
                        deadline = clock.now
                    } else {
                        await animate(.blink)
                        blinksUntilGesture -= 1
                    }
                }
            } catch {
                // Visibility, scene activity and motion settings cancel the whole cycle.
            }
        }
        .task(id: winkRequest) {
            guard winkRequest > 0 else { return }
            await animate(.wink)
        }
        .task(id: jumpRequest) {
            guard jumpRequest > 0, usesMotion else { return }
            await animate(.jump)
        }
        .onChange(of: usesMotion) { _, enabled in
            if !enabled { jumpRequest = 0 }
        }
    }

    private func wink() {
        guard canAnimate, !isAnimating else { return }
        winkRequest += 1
    }

    private func requestJump() {
        guard canAnimate, usesMotion, !isAnimating else { return }
        jumpRequest += 1
    }

    @MainActor private func breathe() async {
        defer { resetWithoutAnimation { breath = 0 } }
        do {
            while !Task.isCancelled {
                withAnimation(.timingCurve(0.45, 0, 0.55, 1, duration: 2.4)) { breath = 1 }
                try await Task.sleep(for: .milliseconds(2400))
                withAnimation(.timingCurve(0.45, 0, 0.55, 1, duration: 2.8)) { breath = 0 }
                try await Task.sleep(for: .milliseconds(2800))
            }
        } catch { }
    }

    @MainActor private func animate(_ nextExpression: Expression) async {
        guard canAnimate, !isAnimating, !Task.isCancelled else { return }
        isAnimating = true
        expression = nextExpression
        defer {
            resetWithoutAnimation {
                leftEyeClosure = 0
                rightEyeClosure = 0
                yawn = 0
                croak = 0
                croakPuff = 0
                jumpProgress = 0
                isAnimating = false
            }
        }
        do {
            switch nextExpression {
            case .blink, .wink: try await animateEyes(isBlink: nextExpression == .blink)
            case .yawn: try await animateYawn()
            case .croak: try await animateCroak()
            case .jump:
                withAnimation(.linear(duration: 1.78)) { jumpProgress = 1 }
                try await Task.sleep(for: .milliseconds(1780))
            }
        } catch { }
    }

    @MainActor private func animateEyes(isBlink: Bool) async throws {
        let closing = usesMotion ? (isBlink ? 0.09 : 0.16) : 0.08
        let opening = usesMotion ? (isBlink ? 0.15 : 0.22) : 0.08
        withAnimation(.easeInOut(duration: closing)) {
            leftEyeClosure = isBlink ? 1 : 0
            rightEyeClosure = 1
        }
        try await Task.sleep(for: .milliseconds(isBlink ? 160 : 300))
        withAnimation(.easeOut(duration: opening)) {
            leftEyeClosure = 0
            rightEyeClosure = 0
        }
        try await Task.sleep(for: .seconds(opening))
    }

    @MainActor private func animateYawn() async throws {
        withAnimation(.easeInOut(duration: 0.25)) {
            leftEyeClosure = 0.65
            rightEyeClosure = 0.65
        }
        try await Task.sleep(for: .milliseconds(180))
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.72)) {
            yawn = 1
            leftEyeClosure = 1
            rightEyeClosure = 1
        }
        try await Task.sleep(for: .milliseconds(1100))
        withAnimation(.timingCurve(0.45, 0, 0.3, 1, duration: 0.85)) { yawn = 0 }
        try await Task.sleep(for: .milliseconds(750))
        withAnimation(.easeOut(duration: 0.28)) {
            leftEyeClosure = 0
            rightEyeClosure = 0
        }
        try await Task.sleep(for: .milliseconds(280))
    }

    @MainActor private func animateCroak() async throws {
        withAnimation(.easeInOut(duration: 0.25)) { croak = 0.18 }
        try await Task.sleep(for: .milliseconds(250))
        for _ in 0..<2 {
            withAnimation(.spring(duration: 0.3, bounce: 0.08)) {
                croak = 1
                croakPuff = 1
            }
            try await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeInOut(duration: 0.28)) {
                croak = 0.22
                croakPuff = 0
            }
            try await Task.sleep(for: .milliseconds(300))
        }
        withAnimation(.timingCurve(0.4, 0, 0.3, 1, duration: 0.45)) { croak = 0 }
        try await Task.sleep(for: .milliseconds(450))
    }

    private func resetWithoutAnimation(_ update: () -> Void) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction, update)
    }
}
