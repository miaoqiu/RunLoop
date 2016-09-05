# RunLoop
深入理解RunLoop
# RunLoop概念
#### 官方定义:系统中和线程相关的基础架构的组成部分（和线程相关），一个RunLoop是一个事件处理环，系统用这个事件处理环安排事务，协调输入的各种事件。RunLoop 的目的是让你的线程有工作的时候忙碌，没有工作的时候休眠。（开启线程是非常好资源的，开启一个主线程需要消耗1M内存，开启一个后台线程需要521K内存）。我们可以把线程比作一辆跑车那么RunLoop就是跑车的主人。当有了RunLoop 这个主人以后跑车的生命就是环形的，并且在主人有比赛任务的时候就会被RunLoop这个主人唤醒，在没有任务的时候就可以休眠
# 使用RunLoop的优点
#### 保持程序的持续运行
#### 处理App中的各种事件（比如触摸事件、定时器事件、Selector事件）
#### 节省CPU资源，提高程序性能：该做事时做事，该休息时休息

# iOS中有2套API来访问和使用RunLoop
#### Foundation中的NSRunLoop  
#### Core Foundation中的CFRunLoopRef
#### NSRunLoop是基于CFRunLoopRef的一层OC包装，所以要了解RunLoop内部结构，需要多研究CFRunLoopRef层面的API（Core Foundation层面）
# RunLoop与线程
#### 每条线程都有唯一的一个与之对应的RunLoop对象
#### 主线程的RunLoop已经自动创建好了，子线程的RunLoop需要主动创建
#### 线程刚创建时并没有 RunLoop，如果你不主动获取，那它一直都不会有。RunLoop 的创建是发生在第一次获取时，RunLoop 的销毁是发生在线程结束时。你只能在一个线程的内部获取其 RunLoop（主线程除外）
# RunLoop的五个类
#### CFRunLoopRef
#### CFRunLoopModeRef
#### CFRunLoopSourceRef
#### CFRunLoopTimerRef
#### CFRunLoopObserverRef
#### 这5个类的关系如下图
![RunLoop结构图](/runLoop.png)
#### 虽然runloop包含了五个类，但是公开的类只有图中的三个。
- CFRunLoopSourceRef类

#### CFRunLoopSourceRef是事件源（输入源），比如外部的触摸，点击事件和系统内部进程间的通信等。
#### 按照官方文档，Source的分类
1. Port-Based Sources
2. Custom Input Sources
3. Cocoa Perform Selector Sources

#### 按照函数调用栈，Source的分类：
1. Source0：非基于Port的。只包含了一个回调（函数指针），它并不能主动触发事件。使用时，你需要先调用 CFRunLoopSourceSignal(source)，将这个 Source 标记为待处理，然后手动调用 CFRunLoopWakeUp(runloop) 来唤醒 RunLoop，让其处理这个事件。
2. Source1：基于Port的，通过内核和其他线程通信，接收、分发系统事件。这种 Source 能主动唤醒 RunLoop 的线程。后面讲到的创建常驻线程就是在线程中添加一个NSport来实现的。
- CFRunLoopTimerRef
1. CFRunLoopTimerRef是基于时间的触发器
2. CFRunLoopTimerRef基本上说的就是NSTimer 它受RunLoop的Mode影响
3. GCD的定时器不受RunLoop的Mode影响

- CFRunLoopObserverRef

#### 每个 Observer 都包含了一个回调（函数指针），当 RunLoop 的状态发生变化时，观察者就能通过回调接受到这个变化。可以观测的时间点有以下几个
<pre><code>typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity)
{ kCFRunLoopEntry = (1UL << 0), // 即将进入Loop （1）
kCFRunLoopBeforeTimers = (1UL << 1), // 即将处理 Timer （2）
kCFRunLoopBeforeSources = (1UL << 2), // 即将处理 Source （4）
kCFRunLoopBeforeWaiting = (1UL << 5), // 即将进入休眠 （32）
kCFRunLoopAfterWaiting = (1UL << 6), // 刚从休眠中唤醒 (64)
kCFRunLoopExit = (1UL << 7), // 即将退出Loop (128)
kCFRunLoopAllActivities = 0x0FFFFFFU, // 包含上面所有状态
};
</code></pre>

- CFRunLoopModeRef
#### 从图上可以看出每一个RunLoop包含多个mode 每一个mode 都是相互独立的，而且RunLoop 只能选择运行一个mode,也就是currentModel。如果需要切换 Mode，只能退出 Loop，再重新指定一个 Mode 进入。这样做主要是为了分隔开不同组的 Source/Timer/Observer，让其互不影响。

####系统默认注册了5个Mode:
1. NSDefaultRunLoopMode：App的默认Mode，通常主线程是在这个Mode下运行
2. UITrackingRunLoopMode：界面跟踪 Mode，用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他 Mode 影响
3. UIInitializationRunLoopMode: 在刚启动 App 时第进入的第一个 Mode，启动完成后就不再使用
4. GSEventReceiveRunLoopMode: 接受系统事件的内部 Mode，通常用不到

#### - NSRunLoopCommonModes: 这是一个占位用的Mode，不是一种真正的Mode commonModes:
#### 一个Mode 可以将自己标记成”Common”属性（通过将其ModelName 添加到RunLoop的"commonModes" 中）。每当 RunLoop 的内容发生变化时，RunLoop 都会自动将 _commonModeItems 里的 Source/Observer/Timer 同步到具有 "Common" 标记的所有Mode里。
#### 应用场景举例：主线程的 RunLoop 里有两个预置的 Mode：kCFRunLoopDefaultMode 和 UITrackingRunLoopMode。这两个 Mode 都已经被标记为"Common"属性。DefaultMode 是 App 平时所处的状态，TrackingRunLoopMode 是追踪 ScrollView 滑动时的状态。当你创建一个 Timer 并加到 DefaultMode 时，Timer 会得到重复回调，但此时滑动一个TableView时，RunLoop 会将 mode 切换为 TrackingRunLoopMode，这时 Timer 就不会被回调，并且也不会影响到滑动操作。
#### 有时你需要一个 Timer，在两个 Mode 中都能得到回调，一种办法就是将这个 Timer 分别加入这两个 Mode。还有一种方式，就是将 Timer 加入到commonMode 中。那么所有被标记为commonMode的mode（defaultMode和TrackingMode）都会执行该timer。这样你在滑动界面的时候也能够调用time。




