//
//  ViewController.m
//  DUKEBlockStrongCaptured
//
//  Created by duke on 2019/11/8.
//  Copyright © 2019 com.duke.DUKEBlockStrongCaptured. All rights reserved.
//

// 参考了:
// https://github.com/tripleCC/Laboratory/tree/master/BlockStrongReferenceObject
// https://juejin.im/post/5d7e3b8de51d4561ac7bcd5f

#import "ViewController.h"
#import "BlockStrongCaptured.h"

@implementation ViewController
{
    void (^_block)(void);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSObject *o1 = [NSObject new];
    __weak NSObject *o2 = o1;
    __block NSObject *o3 = o1;
    NSObject *o4 = o1;
    NSObject *o5 = o1;
    NSObject *o6 = o1;
    NSObject *o7 = o1;
    NSObject *o8 = o1;
    NSObject *o9 = o1;
    NSObject *o10 = o1;
    NSObject *o11 = o1;
    NSObject *o12 = o1;
    NSObject *o13 = o1;
    NSObject *o14 = o1;
    NSObject *o15 = o1;
    NSObject *o16 = o1;
    NSObject *o17 = o1;
    NSObject *o18 = o1;
    NSObject *o19 = o1;

    _block = ^{
        o1;
        o2;
        o3;
        o4;
        o5;
        o6;
        o7;
        o8;
        o9;
        o10;
        o11;
        o12;
        o13;
        o14;
        o15;
        o16;
        o17;
        o18;
        o19;
    };
    
//   __block struct S {
//        int i;
//        __strong NSObject *o1;
//        long j;
//        __weak NSObject *o2;
//    } foo;
//    foo.o1 = [NSObject new];
//    foo.o2 = foo.o1;
//    _block = ^{
//        foo;
//    };
    
    BlockLayoutInfo *info = dk_blockStrongCaptured(_block);
    NSLog(@"%@", info);
}


@end
