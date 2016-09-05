# RunLoop
深入理解RunLoop
#RunLoop概念
####官方定义:系统中和线程相关的基础架构的组成部分（和线程相关），一个RunLoop是一个事件处理环，系统用这个事件处理环安排事务，协调输入的各种事件。RunLoop 的目的是让你的线程有工作的时候忙碌，没有工作的时候休眠。（开启线程是非常好资源的，开启一个主线程需要消耗1M内存，开启一个后台线程需要521K内存）。我们可以把线程比作一辆跑车那么RunLoop就是跑车的主人。当有了RunLoop 这个主人以后跑车的生命就是环形的，并且在主人有比赛任务的时候就会被RunLoop这个主人唤醒，在没有任务的时候就可以休眠
#使用RunLoop的优点
####保持程序的持续运行
####处理App中的各种事件（比如触摸事件、定时器事件、Selector事件）
####节省CPU资源，提高程序性能：该做事时做事，该休息时休息

#iOS中有2套API来访问和使用RunLoop
####Foundation中的NSRunLoop  
####Core Foundation中的CFRunLoopRef
####NSRunLoop是基于CFRunLoopRef的一层OC包装，所以要了解RunLoop内部结构，需要多研究CFRunLoopRef层面的API（Core Foundation层面）
#RunLoop与线程
####每条线程都有唯一的一个与之对应的RunLoop对象
####主线程的RunLoop已经自动创建好了，子线程的RunLoop需要主动创建
####线程刚创建时并没有 RunLoop，如果你不主动获取，那它一直都不会有。RunLoop 的创建是发生在第一次获取时，RunLoop 的销毁是发生在线程结束时。你只能在一个线程的内部获取其 RunLoop（主线程除外）
#RunLoop的五个类
####CFRunLoopRef
####CFRunLoopModeRef
####CFRunLoopSourceRef
####CFRunLoopTimerRef
####CFRunLoopObserverRef
#### 这5个类的关系如下图
![RunLoop结构图](/runLoop.png)