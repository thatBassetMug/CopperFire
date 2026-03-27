//
//  DisplayLinkPublisher.swift
//  CopperFire
//
//  Created by Amanda Basset on 3/27/26.
//

import Combine
import QuartzCore

struct DisplayLinkPublisher: Publisher {
    typealias Output = CADisplayLink
    typealias Failure = Never

    func receive<S: Subscriber>(subscriber: S) where S.Input == CADisplayLink, S.Failure == Never {
        let subscription = DisplayLinkSubscription(subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }

    private final class DisplayLinkSubscription<S: Subscriber>: NSObject, Subscription where S.Input == CADisplayLink, S.Failure == Never {
        private var subscriber: S?
        private var displayLink: CADisplayLink?

        init(subscriber: S) {
            self.subscriber = subscriber
            super.init()
            displayLink = CADisplayLink(target: self, selector: #selector(tick))
            displayLink?.add(to: .main, forMode: .common)
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            displayLink?.invalidate()
            displayLink = nil
            subscriber = nil
        }

        @objc private func tick(_ link: CADisplayLink) {
            _ = subscriber?.receive(link)
        }
    }
}
