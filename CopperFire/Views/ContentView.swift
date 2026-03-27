//
//  ContentView.swift
//  CopperFire
//
//  Created by Amanda Basset on 3/27/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = CopperFireModel()
    @State private var showIntro = true
    @State private var timer: Timer?
    @State private var baseRadius: CGFloat = 20
    @State private var currentRadius: CGFloat = 20
    @State private var viewSize: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                Color.clear.onAppear { viewSize = geo.size }
                    .onChange(of: geo.size) { _, size in viewSize = size }
            }

            CopperCanvasView(model: model)

            if showIntro {
                Text("press & hold to ignite copper")
                    .font(.custom("Georgia", size: 15))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("introText")
            }

            VStack {
                HStack {
                    Spacer()
                    Button("clear") {
                        model.clearCanvas()
                    }
                    .font(.custom("Georgia", size: 12))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.2))
                    .padding(20)
                    .accessibilityIdentifier("clearButton")
                }
                Spacer()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Ignore touches starting in the home indicator zone
                    if model.activeTouch == nil && value.startLocation.y > viewSize.height - 40 {
                        return
                    }
                    if model.activeTouch == nil {
                        model.activeTouch = ActiveTouch(
                            startTime: CACurrentMediaTime(),
                            lastStampTime: CACurrentMediaTime(),
                            location: value.location,
                            lastStampLocation: value.location,
                            radius: currentRadius
                        )
                        withAnimation(.easeOut(duration: 0.6)) {
                            showIntro = false
                        }
                        startTimer()
                    } else {
                        model.activeTouch?.location = value.location
                        model.activeTouch?.radius = currentRadius
                    }
                }
                .onEnded { _ in
                    guard let at = model.activeTouch else { return }
                    let elapsed = CACurrentMediaTime() - at.startTime
                    model.stampBloom(at: at.location, elapsed: elapsed, radius: at.radius)
                    model.activeTouch = nil
                }
        )
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    currentRadius = min(max(baseRadius * value.magnification, 5), 100)
                    model.activeTouch?.radius = currentRadius
                }
                .onEnded { value in
                    baseRadius = min(max(baseRadius * value.magnification, 5), 100)
                    currentRadius = baseRadius
                }
        )
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                cancelTouch()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            cancelTouch()
        }
        #if os(iOS)
        .statusBarHidden()
        #endif
    }

    private func cancelTouch() {
        model.activeTouch = nil
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            let now = CACurrentMediaTime()
            model.update(now: now)

            if model.activeTouch == nil && model.particles.isEmpty {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
