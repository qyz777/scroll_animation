# scroll_animation

## 前言

看到这个标题你可能会觉得“这不是很简单吗？像下面这么一写就完了呗”
```
UIView.animate(withDuration: 0.25) {
    self.tableView.setContentOffset(CGPoint(x: 0, y: 500), animated: false)
}
```

不不不，如果你觉得就这么简单的话说明你还是太年轻了。这样写你的列表在滚动的一开始上面的cell就消失了，这种效果是完全过不了产品和视觉小姐姐的像素眼。

为了实现自定义滚动动效我们可以使用CADisplayLink来实现，至于为什么不用其他timer相信大家可以自己百度了解。

当然如果你并不想那么麻烦的自己写的话可以使用Facebook出品的Pop动画库，它也是基于CADisplayLink实现的。由于UIScrollView的滚动原理，我们可以用`POPBasicAnimation`设置UIScrollView的`bounds`属性动画即可。

## Demo

[自定义列表滚动动效](https://github.com/qyz777/scroll_animation)

## 实现

### Animator

首先我们先实现实际动画的类`ScrollViewAnimator`。

```
private class ScrollViewAnimator {
    
    weak var scrollView: UIScrollView?
    let timingFunction: ScrollTimingFunction
    
    var closure: (() -> Void)?
    
    //动画开始时间
    var startTime: TimeInterval = 0
    //动画初始的contentOffset
    var startOffset: CGPoint = .zero
    //动画目标的contentOffset
    var destinationOffset: CGPoint = .zero
    //动画时长
    var duration: TimeInterval = 0
    //动画已运行时长
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
        //设置需要的属性
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
            //把timer加入到common的runloop中
            timer?.add(to: .main, forMode: .common)
        }
    }
    
    @objc
    func animtedScroll() {
        guard let timer = timer else { return }
        guard let scrollView = scrollView else { return }
        //由于CADisplayLink每次回调的时间不固定，所以使用它自己记录的回调时间来增加运行时长
        runTime += timer.duration
        if runTime >= duration {
            //如果运行时长超过动画时长说明动画需要结束了
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
```

### UIScrollView拓展

我们用OC的runtime知识动态为分类添加属性方便使用

```
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
```

### ScrollTimingFunction枚举

动画缓冲函数的实现可以参考[http://robertpenner.com/easing/](http://robertpenner.com/easing/)。具体实现例子在[Demo](https://github.com/qyz777/scroll_animation)中

## 参考

[http://robertpenner.com/easing/](http://robertpenner.com/easing/)
[https://blog.csdn.net/S_clifftop/article/details/89490422](https://blog.csdn.net/S_clifftop/article/details/89490422)
[https://zsisme.gitbooks.io/ios-/content/index.html](https://zsisme.gitbooks.io/ios-/content/index.html)