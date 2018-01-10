//
//  NSObject+Swizzle.swift
//  Slaminate
//
//  Created by Kristian Trenskow on 08/02/16.
//  Copyright © 2016 Trenskow.io. All rights reserved.
//

import UIKit

extension NSObject {
    
    fileprivate static var instanceSwizzles:[InstanceSwizzle]!
    
    static var swizzled = false {
        didSet {
            if instanceSwizzles == nil {
                instanceSwizzles = [
                    InstanceSwizzle(cls: NSObject.classForCoder(), "willChangeValueForKey:"),
                    InstanceSwizzle(cls: NSObject.classForCoder(), "didChangeValueForKey:"),
                    InstanceSwizzle(cls: NSObject.classForCoder(), "setValue:forKey:"),
                    
                    InstanceSwizzle(cls: NSLayoutConstraint.classForCoder(), "setConstant:"),
                    InstanceSwizzle(cls: NSLayoutConstraint.classForCoder(), "setActive:"),
                    InstanceSwizzle(cls: NSLayoutConstraint.classForCoder(), "setPriority:"),
                    
                    InstanceSwizzle(cls: UIView.classForCoder(), "addConstraint:"),
                    InstanceSwizzle(cls: UIView.classForCoder(), "removeConstraint:"),
                    InstanceSwizzle(cls: UIView.classForCoder(), "addConstraints:"),
                    InstanceSwizzle(cls: UIView.classForCoder(), "removeConstraints:")
                    
                ]
            }
            instanceSwizzles.enabled = swizzled
        }
    }
    
    // NSObject
    
    @objc func slaminate_willChangeValueForKey(_ key: String) {
        
        defer {
            slaminate_willChangeValueForKey(key)
        }
        
        guard Thread.isMainThread else { return }
        guard self as? NSLayoutConstraint == nil else { return }
        guard AnimationBuilder.top.setObjectFromValue(self, key: key, value: value(forKey: key) as? NSObject) else {
            return;
        }
        
    }
    
    @objc func slaminate_didChangeValueForKey(_ key: String) {
        
        defer {
            slaminate_didChangeValueForKey(key)
        }
        
        guard Thread.isMainThread else { return }
        guard self as? NSLayoutConstraint == nil else { return }
        guard AnimationBuilder.top.setObjectToValue(self, key: key, value: value(forKey: key) as? NSObject) else {
            return
        }
        
    }
    
    @objc func slaminate_setValue(_ value: AnyObject?, forKey key: String) {
        
        defer {
            slaminate_setValue(value, forKey: key)
        }
        
        guard Thread.isMainThread else { return }
        guard self as? NSLayoutConstraint == nil else { return }
        
        guard AnimationBuilder.top.setObjectFromToValue(self, key: key, fromValue: self.value(forKey: key) as? NSObject, toValue: value as? NSObject) else {
            return;
        }
        
    }
    
    // NSLayoutContraint
    
    fileprivate func setConstraintValue(_ key: String, newValue: AnyObject) {
        AnimationBuilder.top.setConstraintValue(
            self as! NSLayoutConstraint,
            key: key,
            fromValue: value(forKey: key) as! NSObject,
            toValue: newValue as! NSObject
        )
    }
    
    @objc func slaminate_setActive(_ active: Bool) {
        setConstraintValue("active", newValue: active as AnyObject)
        slaminate_setActive(active)
    }
    
    @objc func slaminate_setConstant(_ constant: CGFloat) {
        setConstraintValue("constant", newValue: constant as AnyObject)
        slaminate_setConstant(constant)
    }
    
    @objc func slaminate_setPriority(_ priority: UILayoutPriority) {
        setConstraintValue("priority", newValue: priority as AnyObject)
        slaminate_setPriority(priority)
    }
    
    // UIView
    
    @objc func slaminate_addConstraint(_ constraint: NSLayoutConstraint) {
        AnimationBuilder.top.addConstraintPresence(self as! UIView, constraint: constraint, added: true)
        slaminate_addConstraint(constraint)
    }
    
    @objc func slaminate_removeConstraint(_ constraint: NSLayoutConstraint) {
        AnimationBuilder.top.addConstraintPresence(self as! UIView, constraint: constraint, added: false)
        slaminate_removeConstraint(constraint)
    }
    
    @objc func slaminate_addConstraints(_ constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            AnimationBuilder.top.addConstraintPresence(self as! UIView, constraint: constraint, added: true)
        }
        slaminate_addConstraints(constraints)
    }
    
    @objc func slaminate_removeConstraints(_ constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            AnimationBuilder.top.addConstraintPresence(self as! UIView, constraint: constraint, added: false)
        }
        slaminate_removeConstraints(constraints)
    }
    
    func pick(animationForKey key: String, fromValue: Any?, toValue: Any, duration: TimeInterval, curve: Curve? = nil) -> Animation? {
        
        let curve = curve ?? Curve.linear;
        
        if LayerAnimation.canAnimate(self, key: key) {
            return LayerAnimation(duration: duration, object: self, key: key, fromValue: fromValue, toValue: toValue, curve: curve)
        }
            
        else if ConstraintConstantAnimation.canAnimate(self, key: key) {
            return ConstraintConstantAnimation(duration: duration, object: self, key: key, fromValue: fromValue, toValue: toValue, curve: curve)
        }
            
        else if DirectAnimation.canAnimate(self, key: key) {
            return DirectAnimation(duration: duration, object: self, key: key, fromValue: fromValue, toValue: toValue, curve: curve);
        }
        
        return nil
        
    }
    
}
