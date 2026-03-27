//
//  CopperCanvasView.swift
//  CopperFire
//
//  Created by Amanda Basset on 3/27/26.
//

import SwiftUI

struct CopperCanvasView: View {
    @Bindable var model: CopperFireModel
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else { return }

            let fullRect = CGRect(origin: .zero, size: size)
            context.fill(Rectangle().path(in: fullRect),
                         with: .color(Color(red: 10.0/255.0, green: 9.0/255.0, blue: 8.0/255.0)))

            model.setupBuffer(size: size, scale: displayScale)

            if let img = model.bufferImage {
                context.draw(
                    Image(decorative: img, scale: model.bufferScale),
                    in: fullRect
                )
            }

            if let at = model.activeTouch {
                let now = CACurrentMediaTime()
                let elapsed = now - at.startTime
                let t = CopperFireModel.gradientT(for: elapsed)
                let color = CopperGradient.sample(t)
                let pulse = 0.5 + 0.5 * sin(now * 5)
                let alpha = 0.15 + pulse * 0.15

                let ring = Circle().path(in: CGRect(
                    x: at.location.x - at.radius,
                    y: at.location.y - at.radius,
                    width: at.radius * 2, height: at.radius * 2
                ))
                context.stroke(ring, with: .color(color.opacity(alpha)), lineWidth: 1.5)

                let dot = Circle().path(in: CGRect(
                    x: at.location.x - 3, y: at.location.y - 3,
                    width: 6, height: 6
                ))
                context.fill(dot, with: .color(color.opacity(0.6)))
            }

            if !model.particles.isEmpty {
                context.blendMode = .screen
                for p in model.particles {
                    let r = p.size * p.life
                    let rect = CGRect(
                        x: p.position.x - r, y: p.position.y - r,
                        width: r * 2, height: r * 2
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(p.color.opacity(Double(p.life * 0.5)))
                    )
                }
                context.blendMode = .normal
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
