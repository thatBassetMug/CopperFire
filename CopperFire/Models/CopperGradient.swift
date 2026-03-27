//
//  CopperGradient.swift
//  CopperFire
//
//  Created by Amanda Basset on 3/27/26.
//

import SwiftUI
import UIKit

enum CopperGradient {
    private static let stops: [(position: CGFloat, color: Color)] = [
        (0.00, Color(red: 0.80, green: 0.50, blue: 0.20)),  // warm copper
        (0.20, Color(red: 0.85, green: 0.35, blue: 0.15)),  // deep copper-orange
        (0.40, Color(red: 0.70, green: 0.20, blue: 0.35)),  // copper-rose
        (0.60, Color(red: 0.45, green: 0.15, blue: 0.55)),  // violet
        (0.80, Color(red: 0.20, green: 0.25, blue: 0.60)),  // indigo-blue
        (1.00, Color(red: 0.10, green: 0.40, blue: 0.45)),  // deep teal
    ]

    static func sample(_ t: CGFloat) -> Color {
        let t = min(max(t, 0), 1)

        if t <= stops.first!.position { return stops.first!.color }
        if t >= stops.last!.position { return stops.last!.color }

        for i in 0..<(stops.count - 1) {
            let a = stops[i]
            let b = stops[i + 1]
            if t >= a.position && t <= b.position {
                let local = (t - a.position) / (b.position - a.position)
                return blend(a.color, b.color, t: local)
            }
        }

        return stops.last!.color
    }

    private static func blend(_ a: Color, _ b: Color, t: CGFloat) -> Color {
        let ca = UIColor(a).cgColor.components ?? [0, 0, 0, 1]
        let cb = UIColor(b).cgColor.components ?? [0, 0, 0, 1]
        return Color(
            red: Double(ca[0] + (cb[0] - ca[0]) * t),
            green: Double(ca[1] + (cb[1] - ca[1]) * t),
            blue: Double(ca[2] + (cb[2] - ca[2]) * t)
        )
    }

    static func cgSample(_ t: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let color = UIColor(sample(t))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }
}
