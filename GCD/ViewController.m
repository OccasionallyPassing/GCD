//
//  ViewController.m
//  GCD
//
//  Created by apple on 16/12/1.
//  Copyright © 2016年 Wang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [self performQueuesUseSynchronization:[self getSerialQueue:@"syn.serial.queue"]];
//    [self performQueuesUseSynchronization:[self getConcurrentQueue:@"syn.concurrent.queue"]];
    
//    [self performQueuesUseAsynchronization:[self getSerialQueue:@"asyn.serial.queue"]];
//    [self performQueuesUseAsynchronization:[self getConcurrentQueue:@"asyn.concurrent.queue"]];
    
    
    
//    [self delayPerform:2.0];
    
    
//    [self globalQueuePriority];
    
//    [self performGroupQueue];
//    [self performGroupUseEnterAndLeave];
    
//    [self useSemaphoreLock];
    
//    [self useDispatchApply];
//    [self queueSuspendAndResume];
    
//    [self useBarrierAsync];
    
    
    [self useDispatchSourceAdd];
    [self useDispatchSourceOr];
//    [self useDispatchSourceTimer];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//获得当前线程
- (NSThread *)getCurrentThread{
    return [NSThread currentThread];
}

//线程休眠
- (void)currentThreadSleep:(NSTimeInterval)sleepTime{
    [NSThread sleepForTimeInterval:sleepTime];
}

//获取主队列
- (dispatch_queue_t)getMainQueue{
    return dispatch_get_main_queue();
}

//获取全局队列并设置优先级
/**
 DISPATCH_QUEUE_PRIORITY_HIGH 2
 DISPATCH_QUEUE_PRIORITY_DEFAULT 0
 DISPATCH_QUEUE_PRIORITY_LOW (-2)
 DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
 */
- (dispatch_queue_t)getGlobalQueue:(dispatch_queue_priority_t)queuePriority{
    return dispatch_get_global_queue(queuePriority, 0);
}

//创建并行队列
- (dispatch_queue_t)getConcurrentQueue:(NSString *)label{
    const char *labelIdentifier = [label UTF8String];
    return dispatch_queue_create(labelIdentifier, DISPATCH_QUEUE_CONCURRENT);
}

//创建串行队列
- (dispatch_queue_t)getSerialQueue:(NSString *)label{
    const char *labelIdentifier = [label UTF8String];
    return dispatch_queue_create(labelIdentifier, DISPATCH_QUEUE_SERIAL);
}

#pragma mark - 

//同步执行
- (void)performQueuesUseSynchronization:(dispatch_queue_t )queue{
    for (NSInteger i = 0; i < 3; i ++) {
        dispatch_sync(queue, ^{
            [self currentThreadSleep:1.0];
            NSLog(@"当前执行线程:%@",[self getCurrentThread]);
            NSLog(@"%ld",i);
        });
    }
    NSLog(@"所有队列使用同步当时执行完毕");
}
//同步执行结论：因为同步执行是在当前线程中来执行的任务，也就是说现在可以供队列使用的线程只有一个，所以串行队列与并行队列使用同步执行的结果是一样的，都必须等到上一个任务出队列并执行完毕后才可以去执行下一个任务。

//异步执行
- (void)performQueuesUseAsynchronization:(dispatch_queue_t)queue{
    dispatch_queue_t serialQueue = [self getSerialQueue:@"serialQueue"];
    for (NSInteger i = 0; i < 3; i ++) {
        dispatch_async(queue, ^{
            [self currentThreadSleep:(double)(arc4random()%3)];
            NSThread *currentThread = [self getCurrentThread];
            dispatch_sync(serialQueue, ^{
                NSLog(@"sleep的线程%@",currentThread);
                NSLog(@"当前输出内容的线程%@",[self getCurrentThread]);
                NSLog(@"执行%ld",i);
            });
        });
        NSLog(@"%ld加载完毕",i);
    }
    NSLog(@"使用异步方式添加队列");
}

/**
1.异步执行串行队列的分析。在线程1中的一个串行队列如果使用异步执行的话，会开辟一个新的线程2来执行队列中的Block任务。在新开辟的线程中依然是FIFO, 并且执行顺序是等待上一个任务执行完毕后才开始执行下一个任务。
2.并行队列异步执行时会开辟多个新的线程来执行队列中的任务，队列中的任务出队列的顺序仍然是FIFO，只不过是不需要等到前面的任务执行完而已，只要是有空余线程可以使用就可以按FIFO的顺序出队列进行执行。
 */
#pragma mark - delay

- (void)delayPerform:(NSTimeInterval)time{
    //dispatch_time用于计算相对时间，当设备休眠时，dispatch_time跟着休眠
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC));
    dispatch_after(delayTime, [self getGlobalQueue:DISPATCH_QUEUE_PRIORITY_DEFAULT], ^{
        NSLog(@"执行线程：%@\ndispatch_time延时时间：%lf", [self getGlobalQueue:DISPATCH_QUEUE_PRIORITY_DEFAULT],time);
    });
    
    double second, subsecond;
    struct timespec timespec;
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSinceNow:time];
    NSTimeInterval interval;
    interval = [date timeIntervalSince1970];
    subsecond = modf(interval, &second);
    timespec.tv_sec = second;
    timespec.tv_nsec = subsecond *NSEC_PER_SEC;
    dispatch_after(dispatch_walltime(&timespec, 0), [self getGlobalQueue:DISPATCH_QUEUE_PRIORITY_DEFAULT], ^{
        NSLog(@"执行线程：%@\ndispatch_walltime延时时间：%lf", [self getGlobalQueue:DISPATCH_QUEUE_PRIORITY_DEFAULT],time);
    });

}
#pragma mark - priority of the queue

//全局队列优先级
- (void)globalQueuePriority{
    dispatch_queue_t queueHigh = [self getGlobalQueue: DISPATCH_QUEUE_PRIORITY_HIGH];
    dispatch_queue_t queueDefault = [self getGlobalQueue: DISPATCH_QUEUE_PRIORITY_DEFAULT];
    dispatch_queue_t queueLow = [self getGlobalQueue: DISPATCH_QUEUE_PRIORITY_LOW];
    dispatch_queue_t queueBackground = [self getGlobalQueue: DISPATCH_QUEUE_PRIORITY_BACKGROUND];
    //优先级不是绝对的，大体会按照这个优先级来执行。一般都是使用默认优先级
    dispatch_async(queueHigh, ^{
        NSLog(@"High%@",[self getCurrentThread]);
     });
    dispatch_async(queueBackground, ^{
        NSLog(@"background%@",[self getCurrentThread]);
    });

    dispatch_async(queueLow, ^{
        NSLog(@"low%@",[self getCurrentThread]);
    });

    dispatch_async(queueDefault, ^{
        NSLog(@"default%@",[self getCurrentThread]);
    });

}

//为自创建的队列设置优先级
- (void)setTargetQueuePriority{
    dispatch_queue_t serialQueue = [self getSerialQueue:@"cn.zeluli.serial1"];
    //为serialQueue设定DISPATCH_QUEUE_PRIORITY_HIGH优先级
    dispatch_set_target_queue(serialQueue, [self getGlobalQueue:DISPATCH_QUEUE_PRIORITY_HIGH]);
}

#pragma mark - diapatch_group

/**
 一组队列执行完毕后，再执行需要执行的代码，可以使用diapatch_group来执行队列
 */
- (void)performGroupQueue{
    NSLog(@"\n任务组自动管理");
    dispatch_queue_t concurrentQueue = [self getConcurrentQueue:@"cn.zeluli"];
    dispatch_group_t group = dispatch_group_create();
    //将group和queue进行管理，并自动执行
    for (NSInteger i = 0; i < 3; i ++) {
        dispatch_group_async(group, concurrentQueue, ^{
            [self currentThreadSleep:1.0];
            NSLog(@"任务%ld执行完毕",i);
        });
    }
    
    //队列组的任务都执行完毕后会进行通知
    dispatch_group_notify(group, [self getMainQueue], ^{
        NSLog(@"所有任务组执行完毕");
    });
    NSLog(@"异步执行测试，不会阻塞当前线程");
}

/**
 使用enter和leave手动管理group和queue
 */
- (void)performGroupUseEnterAndLeave{
    NSLog(@"\n任务组手动管理");
    dispatch_queue_t concurrentQueue = [self getConcurrentQueue:@"cn.zeluli"];
    dispatch_group_t group = dispatch_group_create();
    //将group和queue进行管理，并自动执行
    for (NSInteger i = 0; i < 3; i ++) {
        dispatch_group_enter(group);//进入队列组
        dispatch_async(concurrentQueue, ^{
            [self currentThreadSleep:1.0];
            NSLog(@"任务%ld执行完毕",i);
            dispatch_group_leave(group);//离开队列组（位置要写对）
        });
    }
    
    //阻塞当前线程，直到所有任务执行完毕
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"所有任务组执行完毕");
    dispatch_group_notify(group, concurrentQueue, ^{
        NSLog(@"手动管理的队列执行ok");
    });

}

#pragma mark - semaphore

- (void)useSemaphoreLock{
    dispatch_queue_t concurrentQueue = [self getConcurrentQueue:@"cn.zeluli"];
    dispatch_semaphore_t semaphoreLock = dispatch_semaphore_create(1);
    __block NSInteger testNum = 0;
    for (NSInteger i = 0; i < 3; i ++) {
        dispatch_async(concurrentQueue, ^{
            dispatch_semaphore_wait(semaphoreLock, DISPATCH_TIME_FOREVER);//上锁
            testNum += 1;
            [self currentThreadSleep:1.0];
            NSLog(@"%@",[self getCurrentThread]);
            NSLog(@"第%ld次执行：testnum =%ld",i,testNum);
            dispatch_semaphore_signal(semaphoreLock);//开锁
        });
    }
    NSLog(@"异步执行测试");
}

#pragma mark - apply/resume/suspend

- (void)useDispatchApply{
    NSLog(@"循环多次执行并行队列");
    dispatch_queue_t concurrent = [self getConcurrentQueue:@"cn.zeluli"];
    dispatch_apply(2, concurrent, ^(size_t index){
        [self currentThreadSleep:1.0];
        NSLog(@"第%ld次执行\n%@",index,[self getCurrentThread]);
    });
    
    NSLog(@"循环多次执行串行队列");
    dispatch_queue_t serialQueue = [self getSerialQueue:@"cn.zeluli"];
    dispatch_apply(2, serialQueue, ^(size_t index) {
        [self currentThreadSleep:1.0];
        NSLog(@"第%ld次执行\n%@",index,[self getCurrentThread]);

    });
}

- (void)queueSuspendAndResume{
    dispatch_queue_t concurrent = [self getConcurrentQueue:@"cn.zeluli"];
    dispatch_suspend(concurrent);//将队列挂起
    dispatch_async(concurrent, ^{
        NSLog(@"任务执行");
    });
    [self currentThreadSleep:2.0];
    dispatch_resume(concurrent);
}

#pragma mark - dispatch_barrier

- (void)useBarrierAsync{
    dispatch_queue_t concurrent = [self getConcurrentQueue:@"cn.zeluli"];
    for (NSInteger i = 0; i < 3; i ++) {
        dispatch_async(concurrent, ^{
            [self currentThreadSleep:1.0];
            NSLog(@"第一批：%ld%@",i,[self getCurrentThread]);
        });
    }
    dispatch_barrier_async(concurrent, ^{
        NSLog(@"第一批执行完后才执行第二批%@",[self getCurrentThread]);
    });
    
    for (NSInteger i = 0; i < 3; i ++) {
        dispatch_async(concurrent, ^{
            [self currentThreadSleep:1.0];
            NSLog(@"第一批：%ld%@",i,[self getCurrentThread]);
        });
    }
    NSLog(@"异步执行测试");
}

#pragma mark - dispatch_souce

- (void)useDispatchSourceAdd{
    __block NSInteger sum = 0;
    dispatch_queue_t queue = [self getGlobalQueue:DISPATCH_QUEUE_PRIORITY_DEFAULT];
    dispatch_source_t dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, queue);
    
    dispatch_source_set_event_handler(dispatchSource, ^{
        NSLog(@"source中所有的数相加和等于%ld",dispatch_source_get_data(dispatchSource));
        NSLog(@"sum=%ld",sum);
        sum = 0;
        [self currentThreadSleep:0.3];
    });
    dispatch_resume(dispatchSource);
    for (NSInteger i = 0; i < 10; i ++) {
        sum += i;
        dispatch_source_merge_data(dispatchSource, i);
        [self currentThreadSleep:0.1];
    }
}

- (void)useDispatchSourceOr{
    __block NSInteger sum = 0;
    dispatch_queue_t queue = [self getGlobalQueue:DISPATCH_QUEUE_PRIORITY_DEFAULT];
    dispatch_source_t dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_OR, 0, 0, queue);
    
    dispatch_source_set_event_handler(dispatchSource, ^{
        NSLog(@"source中所有的数相加和等于%ld",dispatch_source_get_data(dispatchSource));
        NSLog(@"sum=%ld",sum);
        sum = 0;
        [self currentThreadSleep:0.3];
    });
    dispatch_resume(dispatchSource);
    for (NSInteger i = 0; i < 10; i ++) {
        sum += i;
        dispatch_source_merge_data(dispatchSource, i);
        [self currentThreadSleep:0.1];
    }
}


- (void)useDispatchSourceTimer{
    dispatch_queue_t queue = [self getGlobalQueue:DISPATCH_QUEUE_PRIORITY_DEFAULT];
    dispatch_source_t dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //设置间隔时间，从当前时间开始，允许偏差0纳秒
    dispatch_source_set_timer(dispatchSource, DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC), 0);
    __block NSInteger timeout = 10;
    
    //设置要处理的事件，在上面创建的queue队列中执行
    dispatch_source_set_event_handler(dispatchSource, ^{
        NSLog(@"%@",[self getCurrentThread]);
        if (timeout <= 0) {
            dispatch_source_cancel(dispatchSource);
        }else{
            NSLog(@"%ld",timeout);
            timeout -= 1;
        }
    });
    
    //倒计时结束的事件
    dispatch_source_set_cancel_handler(dispatchSource, ^{
        NSLog(@"倒计时结束");
    });
    dispatch_resume(dispatchSource);
}
@end
