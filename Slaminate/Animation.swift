//
//  Animation.swift
//  Slaminate
//
//  Created by Kristian Trenskow on 06/02/16.
//  Copyright © 2016 Trenskow.io. All rights reserved.
//

import Foundation

var ongoingAnimations = [Animation]()

@objcMembers public class Animation: NSObject {
    
    init(duration: TimeInterval) {
        self.duration = duration
        super.init()
        ongoingAnimations.append(self)
        perform(#selector(Animation.go as (Animation) -> () -> Animation), with: nil, afterDelay: 0.0, inModes: [RunLoop.Mode.common])
    }
    
    public convenience override init() {
        self.init(duration: 0.0)
    }
    
    @objc(isFinished) public var finished: Bool = false
    
    public var duration: TimeInterval
    public internal(set) var delay: TimeInterval = 0.0
    
    public var reversed: Bool {
        guard owner == nil else { return owner!.reversed }
        return false
    }
    
    fileprivate var _speed: Double = 1.0
    var speed: Double {
        get {
            guard owner == nil else { return owner!.speed }
            return _speed
        }
        set {
            _speed = speed;
        }
    }
    
    var _position: TimeInterval = 0.0
    @objc public var position: TimeInterval {
        get { return _position }
        set {
            setPosition(newValue, apply: true)
        }
    }
    
    func setPosition(_ position: TimeInterval, apply: Bool = false) {
        guard position != _position else { return }
        let oldValue = _position
        willChangeValue(forKey: "position")
        _position = position
        didChangeValue(forKey: "position")
        guard apply else { return }
        if oldValue <= delay && position > delay {
            emit(.animating)
        } else if (oldValue < delay + duration && position >= delay + duration) {
            emit(.completed)
        }
        emit(.position)
        postpone()
    }
    
    weak var owner: Animation? {
        didSet {
            if owner != nil {
                ongoingAnimations.remove(self)
                postpone()
            }
        }
    }
    
    func child(animation: Animation, didCompleteWithFinishState finished: Bool) {}
    
    @objc public enum AnimationEvent: Int {
        case position
        case delayed
        case animating
        case completed
    }
    
    fileprivate struct EventListener {
        var event: AnimationEvent
        var then: (Animation) -> Void
    }
    
    fileprivate var eventListeners = [EventListener]()
    
    fileprivate func emit(_ event: AnimationEvent) {
        eventListeners.filter({ $0.event == event }).forEach({ $0.then(self) })
    }
    
    public func on(_ event: AnimationEvent, then: @escaping (Animation) -> Void) -> Animation {
        eventListeners.append(
            EventListener(
                event: event,
                then: then
            )
        )
        return self
    }
    
    public func completed(_ closure: @escaping (Animation) -> Void) -> Animation {
        return on(.completed, then: closure)
    }
    
    public func animating(_ closure: @escaping (Animation) -> Void) -> Animation {
        return on(.animating, then:  closure)
    }
    
    public func delayed(_ delay: TimeInterval) -> Animation {
        self.delay = delay
        return self
    }
    
    public func then(duration: TimeInterval, curve: Curve?, animation: @escaping () -> Void) -> Animation {
        return then(
            animation: AnimationBuilder(
                duration: duration,
                curve: curve ?? Curve.linear,
                animation: animation
            )
        )
    }
    
    public func then(animation: Animation) -> Animation {
        return then(animations: [animation])
    }
    
    public func then(animations: [Animation]) -> Animation {
        return AnimationChain(animations: [self] + animations)
    }
    
    public func and(duration: TimeInterval, curve: Curve?, animation: @escaping () -> Void) -> Animation {
        return and(
            animation: AnimationBuilder(
                duration: duration,
                curve: curve ?? Curve.linear,
                animation: animation
            )
        )
    }
    
    public func and(animation: Animation) -> Animation {
        return and(animations: [animation])
    }
    
    public func and(animations: [Animation]) -> Animation {
        return AnimationGroup(animations: [self] + animations)
    }
    
    func postpone() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(Animation.go as (Animation) -> () -> Animation),
            object: nil
        )
    }
    
    public func manual() -> Animation {
        guard owner == nil else { return owner!.manual() }
        postpone()
        return self
    }
    
    func complete(_ finished: Bool) {
        self.finished = finished
        setPosition(delay + duration)
        emit(.completed)
        if let owner = owner {
            owner.child(animation: self, didCompleteWithFinishState: finished)
        } else {
            ongoingAnimations.remove(self)
        }
        
    }
    
    // This is a dummy method which just ends the animation.
    // Overridden by subclasses to do their own stuff - do not call super.
    // Used only by null animations.
    func commit() {
        complete(true)
    }
    
    @objc func precommit() {
        if (position >= delay) {
            emit(.animating)
        }
        setPosition(max(_position, delay))
        commit()
    }
    
    func preflight() {
        if position < delay {
            perform(#selector(Animation.precommit), with: nil, afterDelay: (delay - position) / speed, inModes: [RunLoop.Mode.common])
        } else {
            precommit()
        }
    }
    
    public func begin() {
        if position < delay {
            emit(.delayed)
        }
        preflight()
    }
    
    @objc public func go() -> Animation {
        return go(speed: 1.0)
    }
    
    public func go(speed: Double) -> Animation {
        var speed = speed
        if speed < 0.01 && speed > -0.01 { speed = 1.0 }
        guard owner == nil else {
            return owner!.go(speed: speed)
        }
        guard speed > 0.0 else { return reverse().go(speed: -speed) }
        _speed = speed
        postpone()
        begin()
        return self
    }
    
    func reverse() -> Animation {
        return ReversedAnimation(animation: self)
    }
        
}

extension Array where Element: Animation {
    func indexOf(_ element: Element) -> Array.Index? {
        for idx in self.indices {
            if self[idx] === element {
                return idx
            }
        }
        return nil
    }
    mutating func remove(_ element: Element) {
        while let index = indexOf(element) {
            self.remove(at: index)
        }
    }
}

public func Slaminate(duration: TimeInterval, curve: Curve?, animation: @escaping () -> Void) -> Animation {
    return AnimationBuilder(
        duration: duration,
        curve: curve ?? Curve.linear,
        animation: animation
    )
}

extension NSObject {
    @objc public class func slaminate(duration: TimeInterval, curve: Curve? = nil, animation: @escaping () -> Void) -> Animation {
        return AnimationBuilder(
            duration: duration,
            curve: curve ?? Curve.linear,
            animation: animation
        )
    }
    @objc public class func slaminating() -> Bool {
        return AnimationBuilder.top != nil
    }
    @objc public func setValue(_ toValue: Any, fromValue: Any?, key: String, duration: TimeInterval, curve: Curve? = nil) -> Animation! {
        return self.pick(animationForKey: key, fromValue: fromValue, toValue: toValue, duration: duration, curve: curve)
    }
    @objc public func setValue(_ value: AnyObject?, forKeyPath keyPath: String, duration: TimeInterval, curve: Curve? = nil) -> Animation {
        return Slaminate(duration: duration, curve: curve, animation: { [weak self] in self?.setValue(value, forKeyPath: keyPath) })
    }
    @objc public func setValue(_ value: AnyObject?, forKey key: String, duration: TimeInterval, curve: Curve? = nil) -> Animation {
        return setValue(value, forKeyPath: key, duration: duration, curve: curve)
    }
}
