//
//  CopperFireTests.swift
//  CopperFireTests
//
//  Created by Amanda Basset on 3/27/26.
//

import XCTest
import SwiftUI
@testable import CopperFire

// MARK: - CopperGradient Tests

final class CopperGradientTests: XCTestCase {

    func testSampleClampsBelow0() {
        let (r1, g1, b1) = CopperGradient.cgSample(-0.5)
        let (r2, g2, b2) = CopperGradient.cgSample(0)
        XCTAssertEqual(r1, r2, accuracy: 0.001)
        XCTAssertEqual(g1, g2, accuracy: 0.001)
        XCTAssertEqual(b1, b2, accuracy: 0.001)
    }

    func testSampleClampsAbove1() {
        let (r1, g1, b1) = CopperGradient.cgSample(1.5)
        let (r2, g2, b2) = CopperGradient.cgSample(1)
        XCTAssertEqual(r1, r2, accuracy: 0.001)
        XCTAssertEqual(g1, g2, accuracy: 0.001)
        XCTAssertEqual(b1, b2, accuracy: 0.001)
    }

    func testSampleAtBoundaries() {
        // t=0 → warm copper
        let (r0, g0, b0) = CopperGradient.cgSample(0)
        XCTAssertEqual(r0, 0.80, accuracy: 0.02)
        XCTAssertEqual(g0, 0.50, accuracy: 0.02)
        XCTAssertEqual(b0, 0.20, accuracy: 0.02)

        // t=1 → deep teal
        let (r1, g1, b1) = CopperGradient.cgSample(1)
        XCTAssertEqual(r1, 0.10, accuracy: 0.02)
        XCTAssertEqual(g1, 0.40, accuracy: 0.02)
        XCTAssertEqual(b1, 0.45, accuracy: 0.02)
    }

    func testSampleMidpoint() {
        // t=0.5 should be between copper-rose (0.4) and violet (0.6)
        let (r, g, b) = CopperGradient.cgSample(0.5)
        // Midpoint between (0.70, 0.20, 0.35) and (0.45, 0.15, 0.55)
        XCTAssertEqual(r, 0.575, accuracy: 0.03)
        XCTAssertEqual(g, 0.175, accuracy: 0.03)
        XCTAssertEqual(b, 0.45, accuracy: 0.03)
    }

    func testCGSampleMatchesSample() {
        for t in stride(from: 0.0, through: 1.0, by: 0.25) {
            let (r, g, b) = CopperGradient.cgSample(CGFloat(t))
            var cr: CGFloat = 0, cg: CGFloat = 0, cb: CGFloat = 0, ca: CGFloat = 0
            UIColor(CopperGradient.sample(CGFloat(t))).getRed(&cr, green: &cg, blue: &cb, alpha: &ca)
            XCTAssertEqual(r, cr, accuracy: 0.02, "Mismatch at t=\(t)")
            XCTAssertEqual(g, cg, accuracy: 0.02, "Mismatch at t=\(t)")
            XCTAssertEqual(b, cb, accuracy: 0.02, "Mismatch at t=\(t)")
        }
    }
}

// MARK: - GradientT Tests

final class GradientTTests: XCTestCase {

    func testStartsAtZero() {
        XCTAssertEqual(CopperFireModel.gradientT(for: 0), 0, accuracy: 0.001)
    }

    func testRampsUpLinearly() {
        // At 2.5s (halfway through 5s ramp), should be ~0.5
        XCTAssertEqual(CopperFireModel.gradientT(for: 2.5), 0.5, accuracy: 0.001)
    }

    func testHoldsAtTop() {
        // At 5s → ramp complete, hold at 1.0
        XCTAssertEqual(CopperFireModel.gradientT(for: 5.0), 1.0, accuracy: 0.001)
        // At 7s → still holding at 1.0
        XCTAssertEqual(CopperFireModel.gradientT(for: 7.0), 1.0, accuracy: 0.001)
        // At 7.99s → still holding
        XCTAssertEqual(CopperFireModel.gradientT(for: 7.99), 1.0, accuracy: 0.001)
    }

    func testRampsDown() {
        // Ramp down starts at 8s (5+3), ends at 13s (5+3+5)
        // At 10.5s → halfway down → 0.5
        XCTAssertEqual(CopperFireModel.gradientT(for: 10.5), 0.5, accuracy: 0.001)
    }

    func testHoldsAtBottom() {
        // Hold at bottom: 13s to 14s
        XCTAssertEqual(CopperFireModel.gradientT(for: 13.5), 0.0, accuracy: 0.001)
    }

    func testCyclesCorrectly() {
        // Full cycle = 14s. At 14s, should be back to 0 (start of new ramp)
        XCTAssertEqual(CopperFireModel.gradientT(for: 14.0), 0.0, accuracy: 0.001)
        // At 16.5s = 14 + 2.5 → same as 2.5s → 0.5
        XCTAssertEqual(CopperFireModel.gradientT(for: 16.5), 0.5, accuracy: 0.001)
    }
}

// MARK: - CopperFireModel Tests

@MainActor
final class CopperFireModelTests: XCTestCase {

    func testInitialState() async {
        let model = CopperFireModel()
        XCTAssertNil(model.paintBuffer)
        XCTAssertNil(model.bufferImage)
        XCTAssertNil(model.activeTouch)
        XCTAssertTrue(model.particles.isEmpty)
        XCTAssertEqual(model.canvasSize, .zero)
        XCTAssertEqual(model.bufferScale, 2.0)
    }

    func testSetupBufferCreatesContext() async {
        let model = CopperFireModel()
        model.setupBuffer(size: CGSize(width: 100, height: 100), scale: 2.0)
        XCTAssertNotNil(model.paintBuffer)
        XCTAssertNotNil(model.bufferImage)
        XCTAssertEqual(model.canvasSize, CGSize(width: 100, height: 100))
        XCTAssertEqual(model.bufferScale, 2.0)
    }

    func testSetupBufferSkipsDuplicateCall() async {
        let model = CopperFireModel()
        model.setupBuffer(size: CGSize(width: 100, height: 100), scale: 2.0)
        let firstBuffer = model.paintBuffer
        model.setupBuffer(size: CGSize(width: 100, height: 100), scale: 2.0)
        XCTAssertTrue(model.paintBuffer === firstBuffer)
    }

    func testSetupBufferRecreatesOnSizeChange() async {
        let model = CopperFireModel()
        model.setupBuffer(size: CGSize(width: 100, height: 100), scale: 2.0)
        let firstBuffer = model.paintBuffer
        model.setupBuffer(size: CGSize(width: 200, height: 200), scale: 2.0)
        XCTAssertFalse(model.paintBuffer === firstBuffer)
        XCTAssertEqual(model.canvasSize, CGSize(width: 200, height: 200))
    }

    func testSetupBufferDefaultsScaleWhenZero() async {
        let model = CopperFireModel()
        model.setupBuffer(size: CGSize(width: 100, height: 100), scale: 0)
        XCTAssertEqual(model.bufferScale, 2.0)
    }

    func testSpawnParticlesAtZeroIntensity() async {
        let model = CopperFireModel()
        model.spawnParticles(at: CGPoint(x: 50, y: 50), intensity: 0)
        // count = Int(1 + 0 * 2) = 1
        XCTAssertEqual(model.particles.count, 1)
    }

    func testSpawnParticlesAtFullIntensity() async {
        let model = CopperFireModel()
        model.spawnParticles(at: CGPoint(x: 50, y: 50), intensity: 1.0)
        // count = Int(1 + 1 * 2) = 3
        XCTAssertEqual(model.particles.count, 3)
    }

    func testSpawnParticlesRespectsMaxLimit() async {
        let model = CopperFireModel()
        for _ in 0..<200 {
            model.spawnParticles(at: .zero, intensity: 1.0)
        }
        XCTAssertLessThanOrEqual(model.particles.count, 500)
    }

    func testSpawnedParticleProperties() async {
        let model = CopperFireModel()
        let point = CGPoint(x: 50, y: 75)
        model.spawnParticles(at: point, intensity: 0.5)

        let p = model.particles[0]
        XCTAssertEqual(p.position, point)
        XCTAssertGreaterThanOrEqual(p.life, 0.5)
        XCTAssertLessThanOrEqual(p.life, 1.0)
        XCTAssertGreaterThanOrEqual(p.decay, 0.008)
        XCTAssertLessThanOrEqual(p.decay, 0.02)
        XCTAssertGreaterThanOrEqual(p.size, 1.5)
        XCTAssertLessThanOrEqual(p.size, 3.5)
    }

    func testUpdateDecaysAndMovesParticles() async {
        let model = CopperFireModel()
        model.spawnParticles(at: CGPoint(x: 50, y: 50), intensity: 0)
        let initial = model.particles[0]

        model.update(now: CACurrentMediaTime())

        let updated = model.particles[0]
        XCTAssertEqual(updated.position.x, initial.position.x + initial.velocity.dx, accuracy: 0.001)
        XCTAssertEqual(updated.position.y, initial.position.y + initial.velocity.dy, accuracy: 0.001)
        XCTAssertLessThan(updated.life, initial.life)
        XCTAssertEqual(updated.velocity.dy, initial.velocity.dy - 0.01, accuracy: 0.001)
    }

    func testUpdateRemovesDeadParticles() async {
        let model = CopperFireModel()
        model.particles.append(Particle(
            position: .zero,
            velocity: .zero,
            life: 0.005,
            decay: 0.01,
            size: 2,
            color: .white
        ))
        XCTAssertEqual(model.particles.count, 1)

        model.update(now: CACurrentMediaTime())
        XCTAssertTrue(model.particles.isEmpty)
    }

    func testUpdateWithActiveTouchStampsAndSpawns() async {
        let model = CopperFireModel()
        model.setupBuffer(size: CGSize(width: 200, height: 200), scale: 2.0)

        let now = CACurrentMediaTime()
        model.activeTouch = ActiveTouch(
            startTime: now - 1.0,
            lastStampTime: now - 0.1,
            location: CGPoint(x: 100, y: 100),
            lastStampLocation: CGPoint(x: 100, y: 100),
            radius: 20
        )

        model.update(now: now)
        XCTAssertFalse(model.particles.isEmpty)
    }

    func testUpdateInterpolatesAlongPath() async {
        let model = CopperFireModel()
        model.setupBuffer(size: CGSize(width: 200, height: 200), scale: 2.0)

        let now = CACurrentMediaTime()
        model.activeTouch = ActiveTouch(
            startTime: now - 1.0,
            lastStampTime: now - 0.1,
            location: CGPoint(x: 150, y: 150),
            lastStampLocation: CGPoint(x: 50, y: 50),
            radius: 20
        )

        model.update(now: now)
        XCTAssertEqual(model.activeTouch?.lastStampLocation, CGPoint(x: 150, y: 150))
    }

    func testClearCanvas() async {
        let model = CopperFireModel()
        model.setupBuffer(size: CGSize(width: 100, height: 100), scale: 2.0)
        model.spawnParticles(at: .zero, intensity: 1.0)
        XCTAssertFalse(model.particles.isEmpty)

        model.clearCanvas()
        XCTAssertTrue(model.particles.isEmpty)
        XCTAssertNotNil(model.bufferImage)
    }

    func testStampBloomRequiresBuffer() async {
        let model = CopperFireModel()
        model.stampBloom(at: CGPoint(x: 50, y: 50), elapsed: 1.0, radius: 20)
        XCTAssertNil(model.bufferImage)
    }

    func testStampBloomRequiresMinRadius() async {
        let model = CopperFireModel()
        model.setupBuffer(size: CGSize(width: 100, height: 100), scale: 2.0)

        // radius <= 1 should early-return without stamping
        model.stampBloom(at: CGPoint(x: 50, y: 50), elapsed: 1.0, radius: 0.5)
        XCTAssertNotNil(model.bufferImage)
    }
}

// MARK: - ActiveTouch Tests

final class ActiveTouchTests: XCTestCase {

    func testActiveTouchInit() {
        let touch = ActiveTouch(
            startTime: 100.0,
            lastStampTime: 100.0,
            location: CGPoint(x: 50, y: 75),
            lastStampLocation: CGPoint(x: 50, y: 75),
            radius: 20
        )
        XCTAssertEqual(touch.startTime, 100.0)
        XCTAssertEqual(touch.location, CGPoint(x: 50, y: 75))
        XCTAssertEqual(touch.radius, 20)
    }

    func testActiveTouchMutability() {
        var touch = ActiveTouch(
            startTime: 0,
            lastStampTime: 0,
            location: .zero,
            lastStampLocation: .zero,
            radius: 10
        )
        touch.location = CGPoint(x: 100, y: 200)
        touch.radius = 50
        XCTAssertEqual(touch.location, CGPoint(x: 100, y: 200))
        XCTAssertEqual(touch.radius, 50)
    }
}

// MARK: - Particle Tests

final class ParticleTests: XCTestCase {

    func testParticleInit() {
        let p = Particle(
            position: CGPoint(x: 10, y: 20),
            velocity: CGVector(dx: 1, dy: -1),
            life: 1.0,
            decay: 0.01,
            size: 2.5,
            color: .red
        )
        XCTAssertEqual(p.position, CGPoint(x: 10, y: 20))
        XCTAssertEqual(p.velocity.dx, 1.0)
        XCTAssertEqual(p.velocity.dy, -1.0)
        XCTAssertEqual(p.life, 1.0)
        XCTAssertEqual(p.decay, 0.01)
        XCTAssertEqual(p.size, 2.5)
    }
}
