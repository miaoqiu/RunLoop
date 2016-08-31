# RunLoop
深入理解RunLoop
#RunLoop概念
###RunLoop 系统中和线程相关的基础架构的组成部分（和线程相关），一个RunLoop是一个事件处理环，系统用这个事件处理环安排事务，协调输入的各种事件。RunLoop 的目的是让你的线程有工作的时候忙碌，没有工作的时候休眠。我们把线程比作一辆跑车，RunLoop比作跑车的主人，假如跑车没有主人的话，这个跑车的生命就是直线型的，启动 运行完之后就会废弃(没有人对其进行控制，’撞坏’被回收)。当有了RunLoop 这个主人以后跑车的生命就是环形的，并且在主人有比赛任务的时候就会被RunLoop这个主人唤醒，在没有任务的时候就可以休眠（在iOS 中开启线程是非常耗资源的，开启主线程需要消耗1M内存，开启一个后台线程需要521k内存）这样就可以增加跑车的效率，也就是说RunLoop 是为了线程服务的，线程和RunLoop 直接是以键值对形式一一对应的，其中Key 是thread value 是runLoop。
#iOS中有2套API来访问和使用RunLoop
###Foundation中的NSRunLoop   Core Foundation中的CFRunLoopRef
###NSRunLoop是基于CFRunLoopRef的一层OC包装，所以要了解RunLoop内部结构，需要多研究CFRunLoopRef层面的API（Core Foundation层面）