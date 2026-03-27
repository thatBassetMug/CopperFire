//
//  CopperFireModel.swift
//  CopperFire
//
//  Created by Amanda Basset on 3/27/26.
//

import SwiftUI

struct ActiveTouch {
    var startTime: TimeInterval
    var lastStampTime: TimeInterval
    var location: CGPoint
    var lastStampLocation: CGPoint
    var radius: CGFloat
}

struct Particle {
    var position: CGPoint
    var velocity: CGVector
    var life: CGFloat
    var decay: CGFloat
    var size: CGFloat
    var color: Color
}

@Observable
class CopperFireModel {
    private(set) var paintBuffer: CGContext?
    private(set) var bufferImage: CGImage?
    var activeTouch: ActiveTouch?
    var particles: [Particle] = []
    var canvasSize: CGSize = .zero

    private(set) var bufferScale: CGFloat = 2.0

    private static let backgroundColor = CGColor(
        red: 10.0 / 255.0, green: 9.0 / 255.0, blue: 8.0 / 255.0, alpha: 1.0
    )

    /// Maps elapsed time to 0→1→(hold)→0→1… with a pause at each end
    static func gradientT(for elapsed: TimeInterval) -> CGFloat {
        let rampUp = 5.0    // seconds copper → teal
        let holdTop = 3.0   // seconds to hold at teal
        let rampDown = 5.0  // seconds teal → copper
        let holdBot = 1.0   // seconds to hold at copper
        let cycle = rampUp + holdTop + rampDown + holdBot

        let phase = elapsed.truncatingRemainder(dividingBy: cycle)
        if phase < rampUp {
            return CGFloat(phase / rampUp)
        } else if phase < rampUp + holdTop {
            return 1.0
        } else if phase < rampUp + holdTop + rampDown {
            return CGFloat(1.0 - (phase - rampUp - holdTop) / rampDown)
        } else {
            return 0.0
        }
    }

    func setupBuffer(size: CGSize, scale: CGFloat) {
        let newScale = scale > 0 ? scale : 2.0
        guard size != canvasSize || newScale != bufferScale else { return }
        canvasSize = size
        bufferScale = newScale
        let w = Int(size.width * bufferScale)
        let h = Int(size.height * bufferScale)
        let cs = CGColorSpaceCreateDeviceRGB()
        paintBuffer = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        paintBuffer?.scaleBy(x: bufferScale, y: bufferScale)
        paintBuffer?.translateBy(x: 0, y: size.height)
        paintBuffer?.scaleBy(x: 1, y: -1)
        fillBackground()
        updateSnapshot()
    }

    private func fillBackground() {
        paintBuffer?.setFillColor(Self.backgroundColor)
        paintBuffer?.fill(CGRect(origin: .zero, size: canvasSize))
    }

    func updateSnapshot() {
        bufferImage = paintBuffer?.makeImage()
    }

    func stampBloom(at point: CGPoint, elapsed: TimeInterval, radius: CGFloat) {
        guard let ctx = paintBuffer else { return }
        let t = Self.gradientT(for: elapsed)
        guard radius > 1 else { return }

        let (r, g, b) = CopperGradient.cgSample(t)
        let baseAlpha = 0.15 + t * 0.25
        let cs = CGColorSpaceCreateDeviceRGB()

        let colors = [
            CGColor(colorSpace: cs, components: [r, g, b, baseAlpha])!,
            CGColor(colorSpace: cs, components: [r, g, b, baseAlpha * 0.7])!,
            CGColor(colorSpace: cs, components: [r, g, b, baseAlpha * 0.35])!,
            CGColor(colorSpace: cs, components: [r, g, b, baseAlpha * 0.1])!,
            CGColor(colorSpace: cs, components: [r, g, b, 0])!,
        ] as CFArray

        let locs: [CGFloat] = [0, 0.3, 0.6, 0.85, 1.0]
        guard let gradient = CGGradient(
            colorsSpace: cs, colors: colors, locations: locs
        ) else { return }

        ctx.setBlendMode(.screen)
        ctx.drawRadialGradient(
            gradient,
            startCenter: point, startRadius: 0,
            endCenter: point, endRadius: radius,
            options: []
        )
        ctx.setBlendMode(.normal)
        updateSnapshot()
    }

    func update(now: TimeInterval) {
        if var at = activeTouch {
            let elapsed = now - at.startTime
            if now - at.lastStampTime > 0.016 {
                // Interpolate between last stamp position and current position
                let dx = at.location.x - at.lastStampLocation.x
                let dy = at.location.y - at.lastStampLocation.y
                let dist = sqrt(dx * dx + dy * dy)
                let spacing = max(at.radius * 0.15, 3)

                if dist < spacing {
                    // Close enough — single stamp
                    stampBloom(at: at.location, elapsed: elapsed, radius: at.radius)
                } else {
                    // Place stamps along the path
                    let steps = max(Int(dist / spacing), 1)
                    for i in 1...steps {
                        let frac = CGFloat(i) / CGFloat(steps)
                        let pt = CGPoint(
                            x: at.lastStampLocation.x + dx * frac,
                            y: at.lastStampLocation.y + dy * frac
                        )
                        stampBloom(at: pt, elapsed: elapsed, radius: at.radius)
                    }
                }

                let intensity = Self.gradientT(for: elapsed)
                spawnParticles(at: at.location, intensity: intensity)
                at.lastStampTime = now
                at.lastStampLocation = at.location
                activeTouch = at
            }
        }

        particles = particles.compactMap { p in
            var p = p
            p.position.x += p.velocity.dx
            p.position.y += p.velocity.dy
            p.velocity.dy -= 0.01
            p.life -= p.decay
            return p.life > 0 ? p : nil
        }
    }

    func spawnParticles(at point: CGPoint, intensity: CGFloat) {
        let count = Int(1 + intensity * 2)
        let color = CopperGradient.sample(intensity)
        for _ in 0..<count {
            guard particles.count < 500 else { break }
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 0.2...0.8)
            particles.append(Particle(
                position: point,
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed - 0.5
                ),
                life: CGFloat.random(in: 0.5...1.0),
                decay: CGFloat.random(in: 0.008...0.02),
                size: CGFloat.random(in: 1.5...3.5),
                color: color
            ))
        }
    }

    func clearCanvas() {
        fillBackground()
        particles.removeAll()
        updateSnapshot()
    }
}
