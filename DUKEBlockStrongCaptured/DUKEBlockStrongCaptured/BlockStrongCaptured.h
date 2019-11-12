//
//  BlockStrongCaptured.h
//  DUKEBlockStrongCaptured
//
//  Created by duke on 2019/11/8.
//  Copyright © 2019 com.duke.DUKEBlockStrongCaptured. All rights reserved.
//

#ifndef BlockStrongCaptured_h
#define BlockStrongCaptured_h

#import <Foundation/Foundation.h>

@interface LayoutInfoItem : NSObject
@property (nonatomic, assign, readonly) unsigned int type;
@property (nonatomic, assign, readonly) NSInteger count;
@end

@interface BlockLayoutInfo : NSObject
@property (nonatomic, copy, readonly) id block;
@property (nonatomic, copy, readonly) NSArray *objects;
@property (nonatomic, copy, readonly) NSArray <LayoutInfoItem *> *layoutInfos;
@property (nonatomic, copy, readonly) NSArray <LayoutInfoItem *> *byrefLayoutInfos;
@end

extern BlockLayoutInfo *dk_blockStrongCaptured(id block);

#endif /* BlockStrongCaptured_h */
