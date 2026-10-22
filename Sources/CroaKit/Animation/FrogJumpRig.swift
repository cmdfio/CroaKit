import SwiftUI

/// Matched contours generated from the five supplied SVG poses, with the
/// existing front-facing mascot at both ends of the animation.
struct FrogJumpArtwork: Decodable, Sendable {
    struct Layer: Decodable, Sendable { let name: String; let fill: String; let stroke: CGFloat }
    struct Pose: Decodable, Sendable { let points: [[[CGFloat]]]; let opacity: [CGFloat] }
    let layers: [Layer]
    let poses: [Pose]
    let times: [CGFloat]
    let indices: [Int]
    let duration: CGFloat
    let transitions: [String: [[[[CGFloat]]]]]
    let joins: [[String]]

    static let shared: FrogJumpArtwork? = {
        guard let url = CroaResources.bundle.url(forResource: "francophile-frog-jump", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(FrogJumpArtwork.self, from: data)
    }()

    func frame(_ progress: CGFloat) -> (Int, Int, CGFloat) {
        let time = min(1, max(0, progress)) * duration
        var interval = 0
        while interval < times.count - 2 && time > times[interval + 1] { interval += 1 }
        let t = min(1, max(0, (time - times[interval]) / (times[interval + 1] - times[interval])))
        return (indices[interval], indices[interval + 1], t * t * (3 - 2 * t))
    }
}

struct FrogJumpDrawing: View, Animatable {
    let size: CGSize
    let padding: CGFloat
    nonisolated var progress: CGFloat
    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private let ink = Color(red: 6 / 255, green: 12 / 255, blue: 8 / 255)

    private struct Piece {
        let points: [CGPoint]
        let path: Path
        let color: Color
        let stroke: CGFloat
        let opacity: CGFloat
    }

    var body: some View {
        Canvas { context, _ in
            guard let artwork = FrogJumpArtwork.shared else { return }
            let (a, b, t) = artwork.frame(progress)
            guard let transition = artwork.transitions["\(a)-\(b)"] else { return }
            context.translateBy(x: padding, y: padding)
            context.scaleBy(x: size.width / 270, y: size.height / 299)
            var pieces: [String: Piece] = [:]
            for index in artwork.layers.indices {
                let layer = artwork.poses[index]
                let fade = layer.opacity[a] > 0 ? min(1, t / 0.45) : max(0, (t - 0.55) / 0.45)
                let eased = fade * fade * (3 - 2 * fade)
                let opacity = layer.opacity[a] == layer.opacity[b] ? layer.opacity[a] : (layer.opacity[a] > 0 ? 1 - eased : eased)
                let points = transition[index][0].indices.map { i in
                    let p = transition[index][0][i], q = transition[index][1][i]
                    return CGPoint(x: p[0] + (q[0] - p[0]) * t, y: p[1] + (q[1] - p[1]) * t)
                }
                let hex = UInt32(artwork.layers[index].fill.dropFirst(), radix: 16) ?? 0
                pieces[artwork.layers[index].name] = Piece(points: points, path: curve(points),
                    color: Color(red: Double((hex >> 16) & 255) / 255,
                                 green: Double((hex >> 8) & 255) / 255,
                                 blue: Double(hex & 255) / 255),
                    stroke: artwork.layers[index].stroke, opacity: opacity)
            }

            // The beret's dark underside shares the forehead/hat vertices.
            // It follows those contours, never an independent body silhouette.
            if let face = pieces["face"], let hat = pieces["hat"],
               let top = face.points.map(\.y).min(), let bottom = face.points.map(\.y).max() {
                var brim = Path()
                for i in face.points.indices {
                    let p = face.points[i], next = face.points[(i + 1) % face.points.count]
                    let q = nearest(p, in: hat.points), r = nearest(next, in: hat.points)
                    guard p.y < top + (bottom-top) * 0.42, next.y < top + (bottom-top) * 0.42,
                          distance(p, q) < 48*48, distance(next, r) < 48*48 else { continue }
                    brim.move(to: p); brim.addLine(to: q); brim.addLine(to: r); brim.addLine(to: next)
                    brim.closeSubpath()
                }
                context.stroke(brim, with: .color(ink), style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))
                context.fill(brim, with: .color(ink))
            }

            // Close small joint gaps with bridges anchored on the same paths.
            for pair in artwork.joins {
                guard let first = pieces[pair[0]], let second = pieces[pair[1]],
                      min(first.opacity, second.opacity) > 0.001 else { continue }
                var best: (CGPoint, CGPoint)?
                var shortest = CGFloat.infinity
                for p in first.points {
                    let q = nearest(p, in: second.points), d = distance(p, q)
                    if d < shortest { shortest = d; best = (p, q) }
                }
                guard shortest < 32*32, let (p, q) = best else { continue }
                var join = Path(); join.move(to: p); join.addLine(to: q)
                var jointContext = context
                jointContext.opacity = min(first.opacity, second.opacity)
                jointContext.stroke(join, with: .color(ink), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                jointContext.stroke(join, with: .color(first.color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }

            // The head and chest share a continuous outer contour and exact
            // neck vertices. Only the outside of the body receives a stroke.
            let order = ["body", "chest"] + artwork.layers.map(\.name).filter { !["body", "chest", "face"].contains($0) }
            for name in order {
                guard let piece = pieces[name], piece.opacity > 0.001 else { continue }
                var layerContext = context
                layerContext.opacity = piece.opacity
                let maskName = name == "tongue" ? "mouth" :
                    (name.hasSuffix("White") || name.hasSuffix("Glint")) ?
                    (name.hasPrefix("left") ? "leftEye" : "rightEye") : ""
                if let mask = pieces[maskName] { layerContext.clip(to: mask.path) }
                if piece.stroke > 0 {
                    layerContext.stroke(piece.path, with: .color(ink),
                                        style: StrokeStyle(lineWidth: piece.stroke,
                                                           lineCap: .round, lineJoin: .round))
                }
                layerContext.fill(piece.path, with: .color(piece.color))
            }
        }
        .frame(width: size.width + padding * 2, height: size.height + padding * 2)
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }

    private func distance(_ p: CGPoint, _ q: CGPoint) -> CGFloat {
        (p.x-q.x)*(p.x-q.x) + (p.y-q.y)*(p.y-q.y)
    }

    private func nearest(_ p: CGPoint, in points: [CGPoint]) -> CGPoint {
        points.min { distance(p, $0) < distance(p, $1) } ?? p
    }

    private func curve(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.move(to: points[0])
        for i in points.indices {
            let p0 = points[(i + points.count - 1) % points.count]
            let p1 = points[i], p2 = points[(i + 1) % points.count]
            let p3 = points[(i + 2) % points.count]
            let limit = sqrt(distance(p1, p2)) * 0.5
            func control(_ p: CGPoint, _ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
                let scale = min(1, limit / max(0.00001, sqrt(dx*dx + dy*dy)))
                return CGPoint(x: p.x + dx*scale, y: p.y + dy*scale)
            }
            path.addCurve(to: p2,
                          control1: control(p1, (p2.x-p0.x)/6, (p2.y-p0.y)/6),
                          control2: control(p2, -(p3.x-p1.x)/6, -(p3.y-p1.y)/6))
        }
        path.closeSubpath()
        return path
    }
}

struct FrogJumpShadow: View, Animatable {
    let size: CGSize
    nonisolated var progress: CGFloat
    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let time = progress * 1.78
        let flight = min(1, max(0, (time - 0.36) / 0.94))
        let lift = 76 * 4 * flight * (1-flight)
        let fade = min(smooth(time / 0.12), smooth((1.78-time) / 0.20))
        Ellipse()
            .fill(.black.opacity(Double(fade * (0.16-lift*0.001))))
            .frame(width: size.width * (82-lift*0.35) * 2 / 270, height: size.height * 14 / 299)
            .position(x: size.width * 0.5, y: size.height * 302 / 299)
            .accessibilityHidden(true)
    }

    private func smooth(_ value: CGFloat) -> CGFloat {
        let t = min(1, max(0, value))
        return t * t * (3-2*t)
    }
}
