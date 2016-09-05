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


# Apple使用RunLoop实现的功能
### AutoreleasePool
####自动释放池的创建和释放，销毁的时机如下所示
- kCFRunLoopEntry; // 进入runloop之前，创建一个自动释放池
- kCFRunLoopBeforeWaiting; // 休眠之前，销毁自动释放池，创建一个新的自动释放池
- kCFRunLoopExit; // 退出runloop之前，销毁自动释放池

###事件响应
#### 苹果注册了一个 Source1 (基于 mach port 的) 用来接收系统事件，当一个硬件事件(触摸/锁屏/摇晃等)发生后，首先由 IOKit.framework 生成一个 IOHIDEvent 事件并由 SpringBoard 接收。SpringBoard 只接收按键(锁屏/静音等)，触摸，加速，接近传感器等几种 Event，随后用 mach port 转发给需要的App进程。随后苹果注册的那个 Source1 就会触发回调，并调用 _UIApplicationHandleEventQueue() 进行应用内部的分发。 
####_UIApplicationHandleEventQueue() 会把 IOHIDEvent 处理并包装成 UIEvent 进行处理或分发，其中包括识别 UIGesture/处理屏幕旋转/发送给 UIWindow 等。通常事件比如 UIButton 点击、touchesBegin/Move/End/Cancel 事件都是在这个回调中完成的。
### 手势识别
####当上面的 _UIApplicationHandleEventQueue() 识别了一个手势时，其首先会调用 Cancel 将当前的 touchesBegin/Move/End 系列回调打断。随后系统将对应的 UIGestureRecognizer 标记为待处理。苹果注册了一个 Observer 监测 BeforeWaiting (Loop即将进入休眠) 事件，这个Observer的回调函数是 _UIGestureRecognizerUpdateObserver()，其内部会获取所有刚被标记为待处理的 GestureRecognizer，并执行GestureRecognizer的回调。当有 UIGestureRecognizer 的变化(创建/销毁/状态改变)时，这个回调都会进行相应处理。
### 界面更新
####当在操作 UI 时，比如改变了 Frame、更新了 UIView/CALayer 的层次时，或者手动调用了 UIView/CALayer 的 setNeedsLayout/setNeedsDisplay方法后，这个 UIView/CALayer 就被标记为待处理，并被提交到一个全局的容器去。苹果注册了一个 Observer 监听 BeforeWaiting(即将进入休眠) 和 Exit (即将退出Loop) 事件，回调去执行一个很长的函数：_ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv()。这个函数里会遍历所有待处理的 UIView/CAlayer 以执行实际的绘制和调整，并更新 UI 界面。
### 定时器
####NSTimer 其实就是 CFRunLoopTimerRef，他们之间是 toll-free bridged 的。一个 NSTimer 注册到 RunLoop 后，RunLoop 会为其重复的时间点注册好事件。例如 10:00, 10:10, 10:20 这几个时间点。RunLoop为了节省资源，并不会在非常准确的时间点回调这个Timer。Timer 有个属性叫做 Tolerance (宽容度)，标示了当时间点到后，容许有多少最大误差。

####如果某个时间点被错过了，例如执行了一个很长的任务，则那个时间点的回调也会跳过去，不会延后执行。就比如等公交，如果 10:10 时我忙着玩手机错过了那个点的公交，那我只能等 10:20 这一趟了。

#### CADisplayLink 是一个和屏幕刷新率一致的定时器（但实际实现原理更复杂，和 NSTimer 并不一样，其内部实际是操作了一个 Source）。如果在两次屏幕刷新之间执行了一个长任务，那其中就会有一帧被跳过去（和 NSTimer 相似），造成界面卡顿的感觉。在快速滑动TableView时，即使一帧的卡顿也会让用户有所察觉。Facebook 开源的 AsyncDisplayLink 就是为了解决界面卡顿的问题，其内部也用到了 RunLoop


# RunLoop 实践
### 滚动scrollview导致定时器失效
#### 产生的原因：因为当你滚动textview的时候，runloop会进入UITrackingRunLoopMode 模式，而定时器运行在defaultMode下面，系统一次只能处理一种模式的runloop，所以导致defaultMode下的定时器失效。
#### 解决办法1：把定时器的runloop的model改为NSRunLoopCommonModes 模式，这个模式是一种占位mode，并不是真正可以运行的mode，它是用来标记一个mode的。默认情况下default和tracking这两种mode 都会被标记上NSRunLoopCommonModes 标签。

####改变定时器的mode为commonmodel，可以让定时器运行在defaultMode和trackingModel两种模式下，不会出现滚动scrollview导致定时器失效的故障

####[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

#### 解决办法2： 使用GCD创建定时器，GCD创建的定时器不会受runloop的影响
<pre><code>
// 获得队列
dispatch_queue_t queue = dispatch_get_main_queue();

// 创建一个定时器(dispatch_source_t本质还是个OC对象)
self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

// 设置定时器的各种属性（几时开始任务，每隔多长时间执行一次）
// GCD的时间参数，一般是纳秒（1秒 == 10的9次方纳秒）
// 比当前时间晚1秒开始执行
dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));

//每隔一秒执行一次
uint64_t interval = (uint64_t)(1.0 * NSEC_PER_SEC);
dispatch_source_set_timer(self.timer, start, interval, 0);

// 设置回调
dispatch_source_set_event_handler(self.timer, ^{
NSLog(@"------------%@", [NSThread currentThread]);

});

// 启动定时器
dispatch_resume(self.timer);

</code></pre>

### 图片下载
####由于图片渲染到屏幕需要消耗较多资源，为了提高用户体验，当用户滚动tableview的时候，只在后台下载图片，但是不显示图片，当用户停下来的时候才显示图片。
#### 实现代码
<pre><code> 
- (void)viewDidLoad { 
[super viewDidLoad];
 self.thread = [[XMGThread alloc] initWithTarget:self selector:@selector(run) object:nil][self.thread start]; 
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event { 
[self performSelector:@selector(useImageView) onThread:self.thread withObject:nil waitUntilDone:NO]; }

- (void)useImageView { 
// 只在NSDefaultRunLoopMode模式下显示图片 [self.imageView performSelector:@selector(setImage:) withObject:[UIImage imageNamed:@"placeholder"] afterDelay:3.0 inModes:@[NSDefaultRunLoopMode]]; }

</pre></code>

#### 分析
####上面的代码可以达到如下效果：用户点击屏幕，在主线程中，三秒之后显示图片，但是当用户点击屏幕之后，如果此时用户又开始滚动textview，那么就算过了三秒，图片也不会显示出来，当用户停止了滚动，才会显示图片。
#### 这是因为限定了方法setImage只能在NSDefaultRunLoopMode 模式下使用。而滚动textview的时候，程序运行在tracking模式下面，所以方法setImage不会执行。

### 常驻线程
#### 需求
#### 需要创建一个在后台一直存在的程序，来做一些需要频繁处理的任务。比如检测网络状态等。默认情况一个线程创建出来，运行完要做的事情，线程就会消亡。而程序启动的时候，就创建的主线程已经加入到runloop，所以主线程不会消亡。这个时候我们就需要把自己创建的线程加到runloop中来，就可以实现线程常驻后台。
#### 实现代码 见本项目demo

#### 分析
#### 如果没有实现添加NSPort或者NSTimer，会发现执行完run方法，线程就会消亡，后续再执行touchbegan方法无效。我们必须保证线程不消亡，才可以在后台接受时间处理
#### RunLoop 启动前内部必须要有至少一个 Timer/Observer/Source，所以在 [runLoop run] 之前先创建了一个新的 NSMachPort 添加进去了。通常情况下，调用者需要持有这个 NSMachPort (mach_port) 并在外部线程通过这个 port 发送消息到 loop 内；但此处添加 port 只是为了让 RunLoop 不至于退出，并没有用于实际的发送消息。
#### 可以发现执行完了run方法，这个时候再点击屏幕，可以不断执行test方法，因为线程self.thread一直常驻后台，等待事件加入其中，然后执行。
### 在所有UI相应操作之前处理任务
#### 比如我们点击了一个按钮，在ui关联的事件开始执行之前，我们需要执行一些其他任务，可以在observer中实现
#### 代码见本项目demo
![btnClikc](/883F2856-D3FD-4093-84AF-00BD3C35917F.png)
#### 可以看到在按钮点击之前，先执行的observe方法里面的代码。这样可以拦截事件，让我们的代码先UI事件之前执行。