import SwiftUI

/// Pure Canvas view that renders a top-down foosball table illustration.
///
/// The view is entirely declarative — no state, no gestures. It scales
/// proportionally to whatever frame its parent assigns.
struct FoosballView: View {

    // MARK: - Rod layout constants
    // Five rods: goalkeeper (red), defence (blue), midfield (red), attack (blue), goalkeeper (red).

    private static let rodFractions:  [CGFloat] = [0.11, 0.28, 0.50, 0.72, 0.89]
    private static let playerCounts:  [Int]     = [1,    2,    5,    2,    1   ]
    private static let rodColors:     [Color]   = [.red, .blue, .red, .blue, .red]

    // MARK: - Body

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Outer frame (dark wood)
            ctx.fill(Path(roundedRect: CGRect(x: 0, y: 0, width: w, height: h), cornerRadius: 8),
                     with: .color(Color(red: 0.30, green: 0.17, blue: 0.06)))

            // Playing field (green)
            let pad: CGFloat = w * 0.07
            let field = CGRect(x: pad, y: pad, width: w - pad * 2, height: h - pad * 2)
            ctx.fill(Path(roundedRect: field, cornerRadius: 4),
                     with: .color(Color(red: 0.13, green: 0.52, blue: 0.13)))

            // Goal boxes
            let gw = field.width  * 0.11
            let gh = field.height * 0.38
            let gy = field.midY - gh / 2
            ctx.fill(Path(CGRect(x: field.minX,      y: gy, width: gw, height: gh)),
                     with: .color(.white.opacity(0.15)))
            ctx.fill(Path(CGRect(x: field.maxX - gw, y: gy, width: gw, height: gh)),
                     with: .color(.white.opacity(0.15)))

            // Centre line
            var centreLine = Path()
            centreLine.move(to:    CGPoint(x: field.midX, y: field.minY + 4))
            centreLine.addLine(to: CGPoint(x: field.midX, y: field.maxY - 4))
            ctx.stroke(centreLine, with: .color(.white.opacity(0.45)), lineWidth: 1)

            // Centre circle
            let cr = field.width * 0.10
            ctx.stroke(
                Path(ellipseIn: CGRect(x: field.midX - cr, y: field.midY - cr,
                                       width: cr * 2, height: cr * 2)),
                with: .color(.white.opacity(0.45)), lineWidth: 1)

            // Rods and players
            for (i, fraction) in Self.rodFractions.enumerated() {
                let rx = field.minX + field.width * fraction

                var rodPath = Path()
                rodPath.move(to:    CGPoint(x: rx, y: 0))
                rodPath.addLine(to: CGPoint(x: rx, y: h))
                ctx.stroke(rodPath,
                           with: .color(Color(white: 0.58).opacity(0.85)),
                           lineWidth: w * 0.020)

                let count   = Self.playerCounts[i]
                let spacing = field.height / CGFloat(count + 1)
                for p in 1...count {
                    let py = field.minY + spacing * CGFloat(p)
                    let pr = w * 0.027
                    let playerRect = CGRect(x: rx - pr, y: py - pr, width: pr * 2, height: pr * 2)
                    ctx.fill(Path(ellipseIn: playerRect), with: .color(Self.rodColors[i]))
                    ctx.stroke(Path(ellipseIn: playerRect),
                               with: .color(.white.opacity(0.7)), lineWidth: 1)
                }
            }

            // Ball
            let br = w * 0.024
            let bx = field.midX + field.width  * 0.06
            let by = field.midY - field.height * 0.06
            ctx.fill(Path(ellipseIn: CGRect(x: bx - br, y: by - br, width: br * 2, height: br * 2)),
                     with: .color(.white))
        }
    }
}
