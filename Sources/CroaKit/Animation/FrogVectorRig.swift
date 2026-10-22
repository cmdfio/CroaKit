import SwiftUI

/// Matched SVG contours interpolate continuously; Metal handles breathing,
/// the jump trajectory and the compression at takeoff/landing.
struct FrogVectorRig: View {
    let size: CGSize
    var leftEyeClosure: CGFloat
    var rightEyeClosure: CGFloat
    var isWink: Bool
    var yawn: CGFloat
    var croak: CGFloat
    var puff: CGFloat
    var breath: CGFloat
    var jumpProgress: CGFloat = 0
    var isJumping = false
    var usesMotion: Bool

    private let ink = Color(red: 6 / 255, green: 12 / 255, blue: 8 / 255)
    private var opening: CGFloat { min(1, max(0, yawn + croak)) }

    var body: some View {
        ZStack {
            if isJumping {
                FrogJumpDrawing(size: size, padding: size.width * 0.55, progress: jumpProgress)
            } else {
            Image(decorative: "FrancophileFrogRig", bundle: CroaResources.bundle).resizable().scaledToFit()
            // Close the black gap behind the original smile, as in the web rig.
            FrogMouthShape(yawn: 0, croak: 0)
                .fill(Color(red: 51 / 255, green: 158 / 255, blue: 68 / 255))
            eye(left: true, closure: leftEyeClosure)
            eye(left: false, closure: rightEyeClosure)
            mouth
            Image(decorative: "FrancophileFrogCroakPuffs", bundle: CroaResources.bundle)
                .resizable()
                .frame(width: size.width * 295 / 270 * 0.91, height: size.height * 0.83)
                .position(x: size.width * (295 * 0.91 / 2 + 28) / 270,
                          y: size.height * (299 * 0.83 / 2 + 47) / 299)
                .scaleEffect(0.82 + puff * 0.18,
                             anchor: UnitPoint(x: 197.0 / 270, y: 145.0 / 299))
                .offset(x: size.width * puff * 0.025)
                .opacity(puff)
            }
        }
        .frame(width: size.width, height: size.height)
        // Transparent room for the head to move without cropping the beret.
        .padding(size.width * 0.55)
        .drawingGroup()
        .modifier(FrogSoftMotion(size: size, padding: size.width * 0.55,
                                 breath: breath, yawn: yawn, croak: croak,
                                 jumpProgress: jumpProgress, isJumping: isJumping,
                                 enabled: usesMotion))
        .frame(width: size.width, height: size.height)
        .background {
            if isJumping { FrogJumpShadow(size: size, progress: jumpProgress) }
        }
    }

    private func eye(left: Bool, closure: CGFloat) -> some View {
        ZStack {
            Image(decorative: left ? "FrancophileFrogLeftEye" : "FrancophileFrogEye", bundle: CroaResources.bundle)
                .resizable().scaledToFit()
                .mask(FrogEyeAperture(closure: closure, left: left,
                                      wink: !left && isWink))
            FrogClosedEyelid(left: left, wink: !left && isWink)
                .stroke(ink, style: StrokeStyle(lineWidth: size.width * 5.5 / 270,
                                                lineCap: .round, lineJoin: .round))
                .opacity(closure)
        }
    }

    private var mouth: some View {
        let outline = FrogMouthShape(yawn: yawn, croak: croak)
        return ZStack {
            outline.fill(ink)
            outline.fill(Color(red: 0.67, green: 0.13, blue: 0.12)).opacity(opening)
            FrogMouthShape(yawn: yawn, croak: croak, tongue: true)
                .fill(Color(red: 0.92, green: 0.36, blue: 0.42))
                .overlay {
                    FrogMouthShape(yawn: yawn, croak: croak, tongue: true)
                        .stroke(ink, lineWidth: size.width * 2.8 / 270 * opening)
                }
                .opacity(opening)
                .mask(outline)
            outline.stroke(ink, lineWidth: size.width * 3.8 / 270 * opening)
        }
    }
}

private struct FrogMouthShape: Shape {
    var yawn: CGFloat
    var croak: CGFloat
    var tongue = false

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(yawn, croak) }
        set { yawn = newValue.first; croak = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let a = tongue ? FrogMouthContours.yawnTongue : FrogMouthContours.yawn
        let b = tongue ? FrogMouthContours.croakTongue : FrogMouthContours.croak
        let y = min(1, max(0, yawn)), c = min(1, max(0, croak))
        let points = a.indices.map { i in
            let rest = tongue ? CGPoint(x: 137, y: 158) : FrogMouthContours.smile[i]
            return CGPoint(
                x: rect.minX + (rest.x + (a[i].x-rest.x)*y + (b[i].x-rest.x)*c) / 270 * rect.width,
                y: rect.minY + (rest.y + (a[i].y-rest.y)*y + (b[i].y-rest.y)*c) / 299 * rect.height)
        }
        // Periodic Catmull–Rom tangents retain smooth curves between SVG samples.
        var path = Path()
        path.move(to: points[0])
        for i in points.indices {
            let p0 = points[(i + points.count - 1) % points.count]
            let p1 = points[i], p2 = points[(i+1) % points.count]
            let p3 = points[(i+2) % points.count]
            path.addCurve(to: p2,
                          control1: CGPoint(x: p1.x + (p2.x-p0.x)/6, y: p1.y + (p2.y-p0.y)/6),
                          control2: CGPoint(x: p2.x - (p3.x-p1.x)/6, y: p2.y - (p3.y-p1.y)/6))
        }
        path.closeSubpath()
        return path
    }
}

private struct FrogEyeAperture: Shape {
    var closure: CGFloat
    let left: Bool
    let wink: Bool

    var animatableData: CGFloat {
        get { closure }
        set { closure = newValue }
    }

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 270 * rect.width,
                    y: rect.minY + y / 299 * rect.height)
        }
        let amount = min(1, max(0, closure))
        let spread = 44 * (1 - amount)
        let x: CGFloat = left ? 49 : 156
        let bend: CGFloat = (wink ? -14 : 9) * amount
        var path = Path()
        path.move(to: point(x, 110 - spread))
        path.addCurve(to: point(x+71, 110-spread),
                      control1: point(x+18, 110-spread+bend),
                      control2: point(x+53, 110-spread+bend))
        path.addLine(to: point(x+71, 110+spread))
        path.addCurve(to: point(x, 110+spread),
                      control1: point(x+53, 110+spread+bend),
                      control2: point(x+18, 110+spread+bend))
        path.closeSubpath()
        return path
    }
}

private struct FrogClosedEyelid: Shape {
    let left: Bool
    let wink: Bool

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 270 * rect.width,
                    y: rect.minY + y / 299 * rect.height)
        }
        let x: CGFloat = left ? 58 : 165
        let controlY: CGFloat = wink ? 96 : 119
        var path = Path()
        path.move(to: point(x, 110))
        path.addCurve(to: point(x+53, 110), control1: point(x+13, controlY), control2: point(x+38, controlY))
        return path
    }
}

private struct FrogSoftMotion: ViewModifier, Animatable {
    let size: CGSize
    let padding: CGFloat
    nonisolated var breath: CGFloat
    nonisolated var yawn: CGFloat
    nonisolated var croak: CGFloat
    nonisolated var jumpProgress: CGFloat
    let isJumping: Bool
    let enabled: Bool

    nonisolated var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(breath, yawn), AnimatablePair(croak, jumpProgress)) }
        set { breath = newValue.first.first; yawn = newValue.first.second; croak = newValue.second.first; jumpProgress = newValue.second.second }
    }

    func body(content: Content) -> some View {
        content.layerEffect(
            ShaderLibrary.bundle(CroaResources.bundle).croaFrogSoftMotion(
                .float2(Float(size.width), Float(size.height)), .float(Float(padding)),
                .float(Float(breath)), .float(Float(yawn)), .float(Float(croak)),
                .float(isJumping ? Float(jumpProgress) : -1)),
            maxSampleOffset: CGSize(width: padding, height: padding), isEnabled: enabled)
    }
}
