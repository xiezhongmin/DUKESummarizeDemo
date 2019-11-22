//
//  BlockStrongCaptured1.m
//  DUKEBlockStrongCaptured
//
//  Created by duke on 2019/11/22.
//  Copyright © 2019 com.duke.DUKEBlockStrongCaptured. All rights reserved.
//  ------------------------------------ 简单取巧方式 ------------------------------------

#import "BlockStrongCaptured1.h"

static int32_t BLOCK_HAS_COPY_DISPOSE =  (1 << 25); // compiler
static int32_t BLOCK_HAS_EXTENDED_LAYOUT  =  (1 << 31); // compiler
static int32_t BLOCK_HAS_SIGNATURE = (1 << 30); // compiler

enum {
    BLOCK_LAYOUT_NON_OBJECT_BYTES = 1,    // N bytes non-objects
    BLOCK_LAYOUT_NON_OBJECT_WORDS = 2,    // N words non-objects
    BLOCK_LAYOUT_STRONG           = 3,    // N words strong pointers
    BLOCK_LAYOUT_BYREF            = 4,    // N words byref pointers
    BLOCK_LAYOUT_WEAK             = 5,    // N words weak pointers
    BLOCK_LAYOUT_UNRETAINED       = 6,    // N words unretained pointers
};

struct dk_block_descriptor_1 {
    uintptr_t reserved;
    uintptr_t size;
};

struct dk_block_descriptor_2 {
    // requires BLOCK_HAS_COPY_DISPOSE
    void *copy;
    void *dispose;
};

struct dk_block_descriptor_3 {
    // requires BLOCK_HAS_SIGNATURE
    const char *signature;
    const char *layout;     // contents depend on BLOCK_HAS_EXTENDED_LAYOUT
};

struct dk_block_layout {
    void *isa;
    volatile int32_t flags; // contains ref count
    int32_t reserved;
    void *invoke;
    struct dk_block_descriptor_1 *descriptor;
    // imported variables
};

size_t _dk_strongSizeEncodingForLayout(const char *aLayout)
{
    size_t strongSize = 0;
    if ((uintptr_t)aLayout < (1 << 12)) {
        // 0x0000000000000xyz
        uintptr_t onlineLayout = (uintptr_t)aLayout;
        unsigned int x = (onlineLayout & 0xf00) >> 8;
        strongSize += x;
    }
    else {
        // 0xPN (0x20 0x30 0x50 0x00 0x53 0x52 0x4c 0x61)
        while (aLayout && *aLayout != '\x00') {
            unsigned int P = (*aLayout & 0xf0) >> 4;
            unsigned int N = (*aLayout & 0xf) + 1;
            if (P == BLOCK_LAYOUT_STRONG) {
                strongSize += N;
            }
            aLayout++;
        }
    }
    return strongSize;
}

NSArray *dk_blockStrongCaptured1(id block)
{
    struct dk_block_layout *aLayout = (__bridge struct dk_block_layout *)block;
    
    // 没有签名
    if (!(aLayout->flags & BLOCK_HAS_SIGNATURE))
        return nil;
    
    // 如果没有引用外部对象也就是没有扩展布局标志的话则直接返回。
    if (! (aLayout->flags & BLOCK_HAS_EXTENDED_LAYOUT))
        return nil;
    
    uint8_t *desc = (uint8_t *)aLayout->descriptor;
    desc += sizeof(struct dk_block_descriptor_1);
    if (aLayout->flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += sizeof(struct dk_block_descriptor_2);
    }
    
    // 最终转化为dk_block_descriptor_3中的结构指针。并且当布局值为0时表明没有引用外部对象。
    struct dk_block_descriptor_3 *desc3 = (struct dk_block_descriptor_3 *)desc;
    if (!desc3->layout)
        return nil;
    
    const char *extendedLayout = desc3->layout;
    size_t size = _dk_strongSizeEncodingForLayout(extendedLayout);
    size_t blockAddressStart = sizeof(struct dk_block_layout) / sizeof(void *);
    void **blockReference = (__bridge void *)block;
    NSMutableSet *refObjects = [[NSMutableSet alloc] init];
    
    for (size_t i = blockAddressStart; i < blockAddressStart + size; i++) {
        void **reference = &blockReference[i];
        if (reference && (*reference)) {
            id object = (__bridge id)(*reference);
            [refObjects addObject:object];
        }
    }
    
    return refObjects.allObjects;
}
