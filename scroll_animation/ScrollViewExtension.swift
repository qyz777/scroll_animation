//
//  ScrollViewExtension.swift
//  scroll_animation
//
//  Created by qiyizhong on 2020/4/24.
//  Copyright © 2020 qiyizhong. All rights reserved.
//

import UIKit

public enum ScrollTimingFunction {
    
    case linear
    case quadIn
    case quadOut
    case quadInOut
    case cubicIn
    case cubicOut
    case cubicInOut
    case quartIn
    case quartOut
    case quartInOut
    case quintIn
    case quintOut
    case quintInOut
    case sineIn
    case sineOut
    case sineInOut
    case expoIn
    case expoOut
    case expoInOut
    case circleIn
    case circleOut
    case circleInOut
    
}

extension ScrollTimingFunction {
    
    /// 缓存函数
    /// - Parameters:
    ///   - t: time
    ///   - b: begin
    ///   - c: change
    ///   - d: duration
    fileprivate func compute(_ t: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
        var t = t
        switch self {
        case .linear:
            return c * t / d + b
        case .quadIn:
            t /= d
            return c * t * t + b
        case .quadOut:
            t /= d
            return -c * t * (t - 2) + b
        case .quadInOut:
            t /= d / 2
            if (t < 1) {
                return c / 2 * t * t + b
            }
            t -= 1
            return -c / 2 * (t * (t - 2) - 1) + b;
        case .cubicIn:
            t /= d
            return c * t * t * t + b
        case .cubicOut:
            t = t / d - 1
            return c * (t * t * t + 1) + b
        case .cubicInOut:
            t /= d / 2
            if (t < 1) {
                return c / 2 * t * t * t + b
            }
            t -= 2
            return c / 2 * (t * t * t + 2) + b
        case .quartIn:
            t /= d
            return c * t * t * t * t + b
        case .quartOut:
            t = t / d - 1
            return -c * (t * t * t * t - 1) + b
        case .quartInOut:
            t /= d / 2
            if (t < 1) {
                return c / 2 * t * t * t * t + b
            }
            t -= 2
            return -c / 2 * (t * t * t * t - 2) + b
        case .quintIn:
            t /= d
            return c * t * t * t * t * t + b
        case .quintOut:
            t = t / d - 1
            return c * ( t * t * t * t * t + 1) + b
        case .quintInOut:
            t /= d / 2
            if (t < 1) {
                return c / 2 * t * t * t * t * t + b
            }
            t -= 2
            return c / 2 * (t * t * t * t * t + 2) + b
        case .sineIn:
            return -c * cos(t / d * (CGFloat.pi / 2)) + c + b
        case .sineOut:
            return c * sin(t / d * (CGFloat.pi / 2)) + b
        case .sineInOut:
            return -c / 2 * (cos(CGFloat.pi * t / d) - 1) + b
        case .expoIn:
            return (t == 0) ? b : c * pow(2, 10 * (t / d - 1)) + b
        case .expoOut:
            return (t == d) ? b + c : c * (-pow(2, -10 * t / d) + 1) + b
        case .expoInOut:
            if (t == 0) {
                return b
            }
            if (t == d) {
                return b + c
            }
            t /= d / 2
            if (t < 1) {
                return c / 2 * pow(2, 10 * (t - 1)) + b
            }
            t -= 1
            return c / 2 * (-pow(2, -10 * t) + 2) + b
        case .circleIn:
            t /= d
            return -c * (sqrt(1 - t * t) - 1) + b
        case .circleOut:
            t = t / d - 1
            return c * sqrt(1 - t * t) + b
        case .circleInOut:
            t /= d / 2
            if (t < 1) {
                return -c / 2 * (sqrt(1 - t * t) - 1) + b
            }
            t -= 2
            return c / 2 * (sqrt(1 - t * t) + 1) + b
        }
    }
    
}

public extension UIScrollView {
    
    private struct AssociatedKeys {
        static var animator: String = "animator"
    }
    
    private var animator: ScrollViewAnimator? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.animator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.animator) as? ScrollViewAnimator
        }
    }
    
    func setContentOffset(_ contentOffset: CGPoint, duration: TimeInterval, timingFunction: ScrollTimingFunction = .linear, completion: (() -> Void)? = nil) {
        if animator == nil {
            animator = ScrollViewAnimator(scrollView: self, timingFunction: timingFunction)
        }
        animator!.closure = { [weak self] in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.animator = nil
            }
            completion?()
        }
        animator!.setContentOffset(contentOffset, duration: duration)
    }
    
}

private class ScrollViewAnimator {
    
    weak var scrollView: UIScrollView?
    let timingFunction: ScrollTimingFunction
    
    var closure: (() -> Void)?
    
    var startTime: TimeInterval = 0
    var startOffset: CGPoint = .zero
    var destinationOffset: CGPoint = .zero
    var duration: TimeInterval = 0
    var runTime: TimeInterval = 0
    
    var timer: CADisplayLink?
    
    init(scrollView: UIScrollView, timingFunction: ScrollTimingFunction) {
        self.scrollView = scrollView
        self.timingFunction = timingFunction
    }
    
    func setContentOffset(_ contentOffset: CGPoint, duration: TimeInterval) {
        guard let scrollView = scrollView else {
            return
        }
        startTime = Date().timeIntervalSince1970
        startOffset = scrollView.contentOffset
        destinationOffset = contentOffset
        self.duration = duration
        runTime = 0
        guard self.duration > 0 else {
            scrollView.setContentOffset(contentOffset, animated: false)
            return
        }
        if timer == nil {
            timer = CADisplayLink(target: self, selector: #selector(animtedScroll))
            timer?.add(to: .main, forMode: .common)
        }
    }
    
    @objc
    func animtedScroll() {
        guard let timer = timer else { return }
        guard let scrollView = scrollView else { return }
        runTime += timer.duration
        if runTime >= duration {
            scrollView.setContentOffset(destinationOffset, animated: false)
            timer.invalidate()
            self.timer = nil
            closure?()
            return
        }
        
        var offset = scrollView.contentOffset
        offset.x = timingFunction.compute(CGFloat(runTime), startOffset.x, destinationOffset.x - startOffset.x, CGFloat(duration))
        offset.y = timingFunction.compute(CGFloat(runTime), startOffset.y, destinationOffset.y - startOffset.y, CGFloat(duration))
        scrollView.setContentOffset(offset, animated: false)
    }
    
}
