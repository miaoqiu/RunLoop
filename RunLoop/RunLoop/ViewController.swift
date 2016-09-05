//
//  ViewController.swift
//  RunLoop
//shui
//  Created by 邱淼 on 16/8/31.
//  Copyright © 2016年 txcap. All rights reserved.
//

import UIKit
import Foundation
class ViewController: UIViewController {
    
     var thread :NSThread?
    let runTextView = UIScrollView()
    let btn = UIButton()
    
 
      override func viewDidLoad() {
              super.viewDidLoad()
        runTextView.frame = CGRectMake(100, 100, 200, 300)
        runTextView.backgroundColor = UIColor.redColor()
        self.view.addSubview(runTextView)
        btn.frame = CGRectMake(100, 0, 100, 100)
        btn.backgroundColor = UIColor.yellowColor()
        btn.addTarget(self, action: #selector(ViewController.btnclick), forControlEvents: .TouchUpInside)
        self.view.addSubview(btn)
        self.observer()
  
//        self.thread = NSThread.init(target: self, selector:#selector(ViewController.run), object: nil)
//         self.thread?.start()
      }
//*****************************************************在所有UI相应操作之前处理任务**********************
    func btnclick() {
    
      
        print("点击了Btn")
        
    }
    
    
    func observer()  {
    
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,CFRunLoopActivity.AllActivities.rawValue , true, 0) { (observer, activity) in
            print("监听到RunLoop状态发生变化----\(activity)")
            
            
        }
        
        CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode)
        
    }
    
  
  
    
    
    
    
    
    
//*****************************************************在所有UI相应操作之前处理任务**********************
    
//*****************************************************常驻线程**********************

     func run() {
        
        print("run===========\(NSThread.currentThread())")
        //方法一
//        NSRunLoop.currentRunLoop().addPort(NSPort.init(), forMode:NSDefaultRunLoopMode)
        //方法二
//        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        //方法三
//        NSRunLoop.currentRunLoop().runUntilDate(NSDate.distantFuture())

        //方法四 添加NSTimer
//        NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(ViewController.test), userInfo: nil, repeats: true)
//        
        
//        
//        
//        NSRunLoop.currentRunLoop().run()
        
    }
    
    
    
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        
//         self.performSelector(#selector(ViewController.test), onThread: self.thread!, withObject: nil, waitUntilDone: false)
//        
//    }
//    
//    func test()  {
//             print("test---------------\(NSThread.currentThread())")
//     }
//    
    /*
     如果没有实现添加NSPort或者NSTimer，会发现执行完run方法，线程就会消亡，后续再执行touchbegan方法无效。
     
     我们必须保证线程不消亡，才可以在后台接受时间处理
     
     RunLoop 启动前内部必须要有至少一个 Timer/Observer/Source，所以在 [runLoop run] 之前先创建了一个新的 NSMachPort 添加进去了。通常情况下，调用者需要持有这个 NSMachPort (mach_port) 并在外部线程通过这个 port 发送消息到 loop 内；但此处添加 port 只是为了让 RunLoop 不至于退出，并没有用于实际的发送消息。
     
     可以发现执行完了run方法，这个时候再点击屏幕，可以不断执行test方法，因为线程self.thread一直常驻后台，等待事件加入其中，然后执行。
 */
    
//*****************************************************常驻线程**********************

    
    
    
    
//*****************************************************图片下载**********************
 
   
    
//    
//    //由于图片渲染到屏幕需要消耗较多资源，为了提高用户体验，当用户滚动tableview的时候，只在后台下载图片，但是不显示图片，当用户停下来的时候才显示图片。
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        
//        
//        self.performSelector(#selector(ViewController.userImageView), onThread: self.thread!, withObject: nil, waitUntilDone: false)
//    
//        
//    }
//    
//    
//    func userImageView()  {
//    
//        
//        self.imageView.performSelector(#selector(ViewController.setImage), withObject: UIImage(named: "qiyerongzi"), afterDelay: 3, inModes:[NSDefaultRunLoopMode])
//        
//    }
//    
//    //设置图片
//    func setImage()  {
//    
//        
//        
//        self.imageView.image = UIImage(named: "tianxingjiangtang")
//        
//    }
//    
//    /*
//     上面的代码可以达到如下效果：
//     
//     用户点击屏幕，在主线程中，三秒之后显示图片
//     
//     但是当用户点击屏幕之后，如果此时用户又开始滚动textview，那么就算过了三秒，图片也不会显示出来，当用户停止了滚动，才会显示图片。
//     
//     这是因为限定了方法setImage只能在NSDefaultRunLoopMode 模式下使用。而滚动textview的时候，程序运行在tracking模式下面，所以方法setImage不会执行。
// */
//    
//    
//*****************************************************图片下载**********************
    
    
    /**
     解决滚动scrollView导致定时器失效
     */
    func scrollerTimer()  {
        //RunLoop 解决滚动scrollView导致定时器失效
        //原因：因为当你滚动textview的时候，runloop会进入UITrackingRunLoopMode 模式，而定时器运行在defaultMode下面，系统一次只能处理一种模式的runloop，所以导致defaultMode下的定时器失效。
        //解决办法1：把定时器的runloop的model改为NSRunLoopCommonModes 模式，这个模式是一种占位mode，并不是真正可以运行的mode，它是用来标记一个mode的。默认情况下default和tracking这两种mode 都会被标记上NSRunLoopCommonModes 标签。改变定时器的mode为commonmodel，可以让定时器运行在defaultMode和trackingModel两种模式下，不会出现滚动scrollview导致定时器失效的故障
        //[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        
        //解决办法2：使用GCD创建定时器，GCD创建的定时器不会受runloop的影响
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

