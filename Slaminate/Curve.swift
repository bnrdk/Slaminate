//
//  Curve.swift
//  Slaminate
//
//  Created by Kristian Trenskow on 06/02/16.
//  Copyright © 2016 Trenskow.io. All rights reserved.
//

public typealias CurveTransform = ((Double) -> Double)

@objcMembers
public class Curve : NSObject {
    
    public let transform: CurveTransform
    
    public static let linear = Curve(transform: { $0 }).guarded
    public static let boolean = Curve(transform: { ($0 < 0.5 ? 0.0 : 1.0) }).guarded
    public static let reversed = Curve(transform: { 1.0 - $0 }).guarded
    
    public static let easeIn = Curve(mediaTimingFunction: convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeIn)).guarded
    public static let easeOut = Curve(mediaTimingFunction: convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeOut)).guarded
    public static let easeInOut = Curve(mediaTimingFunction: convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeInEaseOut)).guarded
    public static let easeDefault = Curve(mediaTimingFunction: convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.default)).guarded
    
    public static let easeInQuad = Curve(transform: { pow($0, 2) }).guarded
    public static let easeOutQuad = Curve(transform: { Double(-1.0) * $0 * Double($0 - 2.0) }).guarded
    public static let easeInOutQuad = easeInQuad | easeOutQuad.guarded
    
    public static let easeInCubic = Curve(transform: { pow($0, 3.0) }).guarded
    public static let easeOutCubic = Curve(transform: { pow($0 - 1.0, 3.0) + 1.0 }).guarded
    public static let easeInOutCubic = easeInCubic | easeOutCubic
    
    public static let easeInQuart = Curve(transform: { pow($0, 4.0) }).guarded
    public static let easeOutQuart = Curve(transform: { -1.0 * (pow($0 - 1.0, 4.0) - 1.0) }).guarded
    public static let easeInOutQuart = easeInQuart | easeOutQuart
    
    public static let easeInQuint = Curve(transform: { pow($0, 5.0) }).guarded
    public static let easeOutQuint = Curve(transform: { 1.0 * (pow($0 - 1.0, 5.0) + 1.0) }).guarded
    public static let easeInOutQuint = easeInQuint | easeOutQuint
    
    public static let easeInSine = Curve(transform: { (-1.0 * cos($0 * .pi / 2) + 1.0) }).guarded
    public static let easeOutSine = Curve(transform: { sin($0 * .pi / 2) }).guarded
    public static let easeInOutSine = Curve(transform: { (-0.5 * cos(.pi * $0) + 0.5) }).guarded
    
    public static let easeInExpo = Curve(transform: { ($0 == 0.0 ? 0.0 : pow(2.0, 10.0 * ($0 - 1.0))) }).guarded
    public static let easeOutExpo = Curve(transform: { -pow(2.0, -10.0 * $0) + 1.0 }).guarded
    public static let easeInOutExpo = easeInExpo | easeOutExpo
    
    public static let easeInCirc = Curve(transform: { -1.0 * (sqrt(1.0 - pow($0, 2.0)) - 1.0) }).guarded
    public static let easeOutCirc = Curve(transform: { sqrt(1.0 - pow($0 - 1.0, 2.0)) }).guarded
    public static let easeInOutCirc = easeInCirc | easeOutCirc
    
    public static let easeInElastic = Curve(transform: {
        
        var s = 1.70158
        var p = 0.3
        var a = 1.0
        
        if a < 1.0 {
            a = 1.0
            s = p / 4.0
        } else {
            s = p / (2.0 * .pi) * asin(1.0 / a)
        }
        
        return -(a * pow(2.0, 10.0 * ($0 - 1.0)) * sin((($0 - 1.0) - s) * (2.0 * .pi) / p))
        
    }).guarded
    public static let easeOutElastic = Curve(transform: {
        
        var s = 1.70158
        var p = 0.3
        var a = 1.0
        
        if a < 1.0 {
            a = 1.0
            s = p/4
        } else {
            s = p / (2.0 * .pi) * asin(1.0 / a)
        }
        
        return a * pow(2.0, -10.0 * $0) * sin(($0 - s) * (2 * .pi) / p) + 1.0
        
    }).guarded
    public static let easeInOutElastic = Curve(transform: {
        
        var s = 1.70158
        var p = 0.3 * 1.5
        var a = 1.0
        
        var t = $0 / 0.5
        
        if a < 1.0 {
            a = 1.0
            s = p / 4.0
        } else {
            s = p / (2.0 * .pi) * asin (1.0 / a)
        }
        
        if t < 1 {
            t -= 1.0
            return -0.5 * (a * pow(2.0,10.0 * t) * sin((t - s) * (2.0 * .pi) / p))
        }
        
        t -= 1.0
        
        return a * pow(2.0, -10.0 * t) * sin((t - s) * (2.0 * .pi) / p) * 0.5 + 1.0
        
    }).guarded
    
    public static let easeInBack = Curve(transform: { $0 * $0 * (Double(2.70158) * $0 - Double(1.70158)) }).guarded
    public static var easeOutBack = Curve(transform: {
        let s = 1.70158
        let s2 = 2.70158
        let n = $0 - 1.0;
        return n * n * (s2 * n + s) + 1.0
    }).guarded
    public static let easeInOutBack = easeInBack | easeOutBack
    
    public static let easeInBounce = Curve(transform: { 1.0 - easeOutBounce.transform(1.0 - $0) }).guarded
    public static let easeOutBounce = Curve(transform: {
        
        var r = 0.0
        
        var t = $0
        
        if t < (1/2.75) {
            r = 7.5625 * t * t
        } else if t < 2.0 / 2.75 {
            t -= 1.5 / 2.75;
            r = 7.5625 * t * t + 0.75
        } else if t < 2.5 / 2.75 {
            t -= 2.25 / 2.75;
            r = 7.5625 * t * t + 0.9375;
        } else {
            t -= 2.625 / 2.75;
            r = 7.5625 * t * t + 0.984375;
        }
        
        return r;
    }).guarded
    public static let easeInOutBounce = easeInBounce | easeOutBounce
    
    public init(transform: @escaping CurveTransform) {
        self.transform = transform
        super.init()
    }
    
    public func or(curve: Curve) -> Curve {
        let linear = Curve.linear
        return Curve(transform: {
            return self.delta(curve: linear).transform($0) + curve.delta(curve: linear).transform($0) + linear.transform($0)
        })
    }
    
    public func multiply(curve: Curve) -> Curve {
        return Curve(transform: { return curve.transform(self.transform($0)) })
    }
    
    public func add(curve: Curve) -> Curve {
        return Curve(transform: {
            if ($0 < 0.5) { return self.transform($0 * 2.0) / 2.0}
            return curve.transform(($0 - 0.5) * 2.0) / 2.0 + 0.5
        })
    }
    
    public var guarded: Curve {
        return Curve(transform: {
            guard $0 > 0.0 && $0 < 1.0 else { return $0 <= 0.0 ? 0.0 : 1.0 }
            return self.transform($0)
        })
    }
    
    public var reversed: Curve {
        return Curve(transform: {
            return 1.0 - self.transform(1.0 - $0)
        })
    }
    
    public func delta(curve: Curve) -> Curve {
        return Curve(transform: {
            return self.transform($0) - curve.transform($0)
        })
    }
    
}

private let cp0 = CGPoint(x: 0.0, y: 0.0)
private let cp3 = CGPoint(x: 1.0, y: 1.0)

extension Curve {
    
    fileprivate static func evaluateAtParameterWithCoefficients(_ t: CGFloat, coefficients: [CGFloat]) -> CGFloat {
        return coefficients[0] + t * coefficients[1] + t * t * coefficients[2] + t * t * t * coefficients[3]
    }
    
    fileprivate static func evaluateDerivationAtParameterWithCoefficients(_ t: CGFloat, coefficients: [CGFloat]) -> CGFloat {
        return coefficients[1] + 2 * t * coefficients[2] + 3 * t * t * coefficients[3]
    }
    
    fileprivate static func calcParameterViaNewtonRaphsonUsingXAndCoefficientsForX(_ x: CGFloat, coefficientX: [CGFloat]) -> CGFloat {
        
        var t: CGFloat = x
        for _ in 0..<10 {
            let x2 = evaluateAtParameterWithCoefficients(t, coefficients: coefficientX) - x
            let d = evaluateDerivationAtParameterWithCoefficients(t, coefficients: coefficientX)
            let dt = x2 / d
            t -= dt
        }
        return !t.isNaN ? t : 1.0
    }
    
    public convenience init(cp1: CGPoint, cp2: CGPoint) {
        let coefficientsX = [
            cp0.x,
            -3.0 * cp0.x + 3.0 * cp1.x,
            3.0 * cp0.x - 6.0 * cp1.x + 3.0 * cp2.x,
            -cp0.x + 3.0 * cp1.x - 3.0 * cp2.x + cp3.x
        ]
        let coefficientsY = [
            cp0.y,
            -3.0 * cp0.y + 3.0 * cp1.y,
            3.0 * cp0.y - 6.0 * cp1.y + 3.0 * cp2.y,
            -cp0.y + 3.0 * cp1.y - 3.0 * cp2.y + cp3.y
        ]
        self.init(transform: { position in
            let t = Curve.calcParameterViaNewtonRaphsonUsingXAndCoefficientsForX(CGFloat(position), coefficientX: coefficientsX);
            return Double(Curve.evaluateAtParameterWithCoefficients(t, coefficients: coefficientsY))
        })
    }
    
    public convenience init(mediaTimingFunction: String) {
        switch mediaTimingFunction {
        case convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.default):
            self.init(cp1: CGPoint(x: 0.25, y: 0.1), cp2: CGPoint(x: 0.25, y: 1.0))
        case convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeIn):
            self.init(cp1: CGPoint(x: 0.42, y: 0.0), cp2: CGPoint(x: 1.0, y: 1.0))
        case convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeOut):
            self.init(cp1: CGPoint(x: 0.0, y: 0.0), cp2: CGPoint(x: 0.58, y: 1.0))
        case convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeInEaseOut):
            self.init(cp1: CGPoint(x: 0.42, y: 0.0), cp2: CGPoint(x: 1.0, y: 1.0))
        default:
            self.init(transform: { $0 })
        }
    }
    
    public convenience init(viewAnimationCurve: UIView.AnimationCurve) {
        switch viewAnimationCurve {
        case .linear:
            self.init(mediaTimingFunction: convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.linear))
        case .easeIn:
            self.init(mediaTimingFunction: convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeIn))
        case .easeOut:
            self.init(mediaTimingFunction: convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeOut))
        case .easeInOut:
            self.init(mediaTimingFunction: convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeInEaseOut))
        }
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCAMediaTimingFunctionName(_ input: CAMediaTimingFunctionName) -> String {
	return input.rawValue
}
