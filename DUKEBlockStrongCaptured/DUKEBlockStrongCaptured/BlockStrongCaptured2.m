//
//  BlockStrongCaptured2.m
//  DUKEBlockStrongCaptured
//
//  Created by duke on 2019/11/8.
//  Copyright © 2019 com.duke.DUKEBlockStrongCaptured. All rights reserved.
// 参考了:
// https://github.com/tripleCC/Laboratory/tree/master/BlockStrongReferenceObject
// https://juejin.im/post/5d7e3b8de51d4561ac7bcd5f

#import "BlockStrongCaptured2.h"

/* 扩展布局信息编码
// Extended layout encoding.

// Values for Block_descriptor_3->layout with BLOCK_HAS_EXTENDED_LAYOUT
// and for Block_byref_3->layout with BLOCK_BYREF_LAYOUT_EXTENDED

// If the layout field is less than 0x1000, then it is a compact encoding
// of the form 0xXYZ: X strong pointers, then Y byref pointers,
// then Z weak pointers.

// If the layout field is 0x1000 or greater, it points to a
// string of layout bytes. Each byte is of the form 0xPN.
// Operator P is from the list below. Value N is a parameter for the operator.
// Byte 0x00 terminates the layout; remaining block data is non-pointer bytes.

enum {
    BLOCK_LAYOUT_ESCAPE = 0, // N=0 halt, rest is non-pointer. N!=0 reserved.
    BLOCK_LAYOUT_NON_OBJECT_BYTES = 1,    // N bytes non-objects
    BLOCK_LAYOUT_NON_OBJECT_WORDS = 2,    // N words non-objects
    BLOCK_LAYOUT_STRONG           = 3,    // N words strong pointers
    BLOCK_LAYOUT_BYREF            = 4,    // N words byref pointers
    BLOCK_LAYOUT_WEAK             = 5,    // N words weak pointers
    BLOCK_LAYOUT_UNRETAINED       = 6,    // N words unretained pointers
    BLOCK_LAYOUT_UNKNOWN_WORDS_7  = 7,    // N words, reserved
    BLOCK_LAYOUT_UNKNOWN_WORDS_8  = 8,    // N words, reserved
    BLOCK_LAYOUT_UNKNOWN_WORDS_9  = 9,    // N words, reserved
    BLOCK_LAYOUT_UNKNOWN_WORDS_A  = 0xA,  // N words, reserved
    BLOCK_LAYOUT_UNUSED_B         = 0xB,  // unspecified, reserved
    BLOCK_LAYOUT_UNUSED_C         = 0xC,  // unspecified, reserved
    BLOCK_LAYOUT_UNUSED_D         = 0xD,  // unspecified, reserved
    BLOCK_LAYOUT_UNUSED_E         = 0xE,  // unspecified, reserved
    BLOCK_LAYOUT_UNUSED_F         = 0xF,  // unspecified, reserved
};
 
 // clang
 /// InlineLayoutInstruction - This routine produce an inline instruction for the
 /// block variable layout if it can. If not, it returns 0. Rules are as follow:
 /// If ((uintptr_t) layout) < (1 << 12), the layout is inline. In the 64bit world,
 /// an inline layout of value 0x0000000000000xyz is interpreted as follows:
 /// x captured object pointers of BLOCK_LAYOUT_STRONG. Followed by
 /// y captured object of BLOCK_LAYOUT_BYREF. Followed by
 /// z captured object of BLOCK_LAYOUT_WEAK. If any of the above is missing, zero
 /// replaces it. For example, 0x00000x00 means x BLOCK_LAYOUT_STRONG and no
 /// BLOCK_LAYOUT_BYREF and no BLOCK_LAYOUT_WEAK objects are captured.
 */

@interface LayoutInfoItem ()
@property (nonatomic, assign, readwrite) unsigned int type;
@property (nonatomic, assign, readwrite) NSInteger count;
+ (id)layoutInfoItemWithType:(unsigned int)type
                       count:(NSInteger)count;
@end

@implementation LayoutInfoItem

+ (id)layoutInfoItemWithType:(unsigned int)type
                       count:(NSInteger)count
{
    LayoutInfoItem *item = [[self alloc] init];
    item.type = type;
    item.count = count;
    return item;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"type: %d, count: %ld", _type, _count];
}

@end

@interface BlockLayoutInfo ()
@property (nonatomic, copy, readwrite) id block;
@property (nonatomic, copy, readwrite) NSArray *objects;
@property (nonatomic, copy, readwrite) NSArray <LayoutInfoItem *> *layoutInfos;
@property (nonatomic, copy, readwrite) NSArray <LayoutInfoItem *> *byrefLayoutInfos;
@end

@implementation BlockLayoutInfo
- (NSString *)description
{
    return [NSString stringWithFormat:@"\n block:%@\n layoutInfos:%@\n byrefLayoutInfos:%@\n objects:%@\n", _block, _layoutInfos, _byrefLayoutInfos, _objects];
}
@end

static int32_t BLOCK_HAS_COPY_DISPOSE =  (1 << 25); // compiler
static int32_t BLOCK_HAS_EXTENDED_LAYOUT  =  (1 << 31); // compiler
static int32_t BLOCK_HAS_SIGNATURE = (1 << 30); // compiler
static int32_t BLOCK_LAYOUT_CAPTURE_TYPE_COUNT = 16;

enum {
    BLOCK_LAYOUT_NON_OBJECT_BYTES = 1,    // N bytes non-objects
    BLOCK_LAYOUT_NON_OBJECT_WORDS = 2,    // N words non-objects
    BLOCK_LAYOUT_STRONG           = 3,    // N words strong pointers
    BLOCK_LAYOUT_BYREF            = 4,    // N words byref pointers
    BLOCK_LAYOUT_WEAK             = 5,    // N words weak pointers
    BLOCK_LAYOUT_UNRETAINED       = 6,    // N words unretained pointers
};

enum {
    // Byref refcount must use the same bits as Block_layout's refcount.
    // BLOCK_DEALLOCATING =      (0x0001),  // runtime
    // BLOCK_REFCOUNT_MASK =     (0xfffe),  // runtime
    BLOCK_BYREF_LAYOUT_MASK =       (0xf << 28), // compiler
    BLOCK_BYREF_LAYOUT_EXTENDED =   (  1 << 28), // compiler
    BLOCK_BYREF_LAYOUT_NON_OBJECT = (  2 << 28), // compiler
    BLOCK_BYREF_LAYOUT_STRONG =     (  3 << 28), // compiler
    BLOCK_BYREF_LAYOUT_WEAK =       (  4 << 28), // compiler
    BLOCK_BYREF_LAYOUT_UNRETAINED = (  5 << 28), // compiler
    
    BLOCK_BYREF_IS_GC =             (  1 << 27), // runtime
    
    BLOCK_BYREF_HAS_COPY_DISPOSE =  (  1 << 25), // compiler
    BLOCK_BYREF_NEEDS_FREE =        (  1 << 24), // runtime
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

// Byref 结构的布局
// 由 __block 修饰的捕获变量，会先转换成 byref 结构，再由这个结构去持有实际的捕获变量，block 只负责管理 byref 结构。
struct dk_block_byref {
    void *isa;
    struct dk_block_byref *forwarding;
    volatile int32_t flags; // contains ref count
    uint32_t size;
};

struct dk_block_byref_2 {
    // requires BLOCK_BYREF_HAS_COPY_DISPOSE
    void (*byref_keep)(struct dk_block_byref *dst, struct dk_block_byref *src);
    void (*byref_destroy)(struct dk_block_byref *);
};

struct dk_block_byref_3 {
    // requires BLOCK_BYREF_LAYOUT_EXTENDED
    const char *layout;
};

struct dk_block_layout {
    void *isa;
    volatile int32_t flags; // contains ref count
    int32_t reserved;
    void *invoke;
    struct dk_block_descriptor_1 *descriptor;
    void *captured[0];
    // imported variables
};


uint8_t *_dk_block_descriptor_3(struct dk_block_layout *aLayout)
{
    uint8_t *desc = (uint8_t *)aLayout->descriptor;
    desc += sizeof(struct dk_block_descriptor_1);
    // 得到描述信息，如果有BLOCK_HAS_COPY_DISPOSE则表示描述信息中有Block_descriptor_2中的内容，因此需要加上这部分信息的偏移。这里有BLOCK_HAS_COPY_DISPOSE的原因是因为当block持有了外部对象时，需要负责对外部对象的声明周期的管理，也就是当对block进行赋值拷贝以及销毁时都需要将引用的外部对象的引用计数进行添加或者减少处理。
    if (aLayout->flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += sizeof(struct dk_block_descriptor_2);
    }
    
    return desc;
}

uint8_t *_dk_block_byref_3(struct dk_block_byref *aByref)
{
    uint8_t *block_byref = (uint8_t *)aByref;
    block_byref += sizeof(struct dk_block_byref);
    if (aByref->flags & BLOCK_BYREF_HAS_COPY_DISPOSE) {
        block_byref += sizeof(struct dk_block_byref_2);
    }
    return block_byref;
}

const char *_dk_block_byref_extended_layout(struct dk_block_byref *aByref)
{
    uint8_t *byref = _dk_block_byref_3(aByref);
    struct dk_block_byref_3 *byref3 = (struct dk_block_byref_3 *)byref;
    return byref3->layout;
}

NSArray *_dk_objectsForBeginAddress(void *address, NSInteger count)
{
    if (!address || count == 0) return nil;
    
    uintptr_t *begin = (uintptr_t *)address;
    NSMutableSet *refObjects = [[NSMutableSet alloc] init];
    
    for (int i = 0; i < count; i++, begin++) {
        id object = (__bridge id _Nonnull)(*(void **)begin);
        if (object) [refObjects addObject:object];
    }
    
    return refObjects.allObjects;
}

NSArray <LayoutInfoItem *> * _dk_compactEncodingForLayout(const char *aLayout);
NSArray *_dk_objectsByrefForBlockByref(struct dk_block_byref *aByref, NSInteger count, BlockLayoutInfo *info)
{
    if (!aByref || count == 0)
        return nil;
    
    NSMutableSet *refObjects = [[NSMutableSet alloc] init];
    
    if (!(aByref->flags & BLOCK_BYREF_LAYOUT_EXTENDED))
        return nil;
    
    int32_t flag = aByref->flags & BLOCK_BYREF_LAYOUT_MASK;

    switch (flag) {
        case BLOCK_BYREF_LAYOUT_STRONG: {
            void **begin = (void **)(_dk_block_byref_3(aByref));
            id object = (__bridge id _Nonnull)(*(void **)begin);
            if (object) [refObjects addObject:object];
        }
            break;
        case BLOCK_BYREF_LAYOUT_EXTENDED: {
            uintptr_t *begin = (uintptr_t *)_dk_block_byref_3(aByref) + 1;
            const char *extendedLayout = _dk_block_byref_extended_layout(aByref);
            NSArray <LayoutInfoItem *> *compactEncoding = _dk_compactEncodingForLayout(extendedLayout);
            info.byrefLayoutInfos = compactEncoding;
            for (LayoutInfoItem *item in compactEncoding) {
                switch (item.type) {
                    case BLOCK_LAYOUT_STRONG: {
                        NSArray *objects = _dk_objectsForBeginAddress(begin, item.count);
                        [refObjects addObjectsFromArray:objects];
                        begin += item.count;
                    }
                        break;
                    case BLOCK_LAYOUT_NON_OBJECT_BYTES: {
                        begin = (uintptr_t *)((uintptr_t)begin + item.count);
                    }
                        break;
                    default: {
                        begin += item.count;
                    }
                        break;
                }
            }
        }
            break;
        default:
            break;
    }
    
    return refObjects.allObjects;
}

void _dk_compactEncoding_clear(unsigned int compactEncoding[16])
{
    if (!compactEncoding) return;
    
    for (int i = 0; i < BLOCK_LAYOUT_CAPTURE_TYPE_COUNT; i++) {
        compactEncoding[i] = 0;
    }
}

NSArray <LayoutInfoItem *> * _dk_compactEncodingForLayout(const char *aLayout)
{
    NSMutableArray <LayoutInfoItem *> *compactEncoding = [[NSMutableArray alloc]
                                                          initWithCapacity:BLOCK_LAYOUT_CAPTURE_TYPE_COUNT];
    if ((uintptr_t)aLayout < (1 << 12)) {
        // 0x0000000000000xyz
        uintptr_t onlineLayout = (uintptr_t)aLayout;
        unsigned int x = (onlineLayout & 0xf00) >> 8;
        unsigned int y = (onlineLayout & 0xf0) >> 4;
        unsigned int z = (onlineLayout & 0xf);
        [compactEncoding addObject:
        [LayoutInfoItem layoutInfoItemWithType:BLOCK_LAYOUT_STRONG count:x]];
        [compactEncoding addObject:
        [LayoutInfoItem layoutInfoItemWithType:BLOCK_LAYOUT_BYREF count:y]];
        [compactEncoding addObject:
        [LayoutInfoItem layoutInfoItemWithType:BLOCK_LAYOUT_WEAK count:z]];
    } else {
        // 1.每个对象类型超过16个
        // 2.捕获结构体里有对象类型
        // 0xPN (0x20 0x30 0x50 0x00 0x53 0x52 0x4c 0x61)
        while (aLayout && *aLayout != '\x00') {
            unsigned int P = (*aLayout & 0xf0) >> 4;
            unsigned int N = (*aLayout & 0xf) + 1;
            [compactEncoding addObject:
            [LayoutInfoItem layoutInfoItemWithType:P count:N]];
            aLayout++;
        }
    }
    
    return compactEncoding.copy;
}

BlockLayoutInfo *dk_blockStrongCaptured2(id block)
{
    if (!block)
        return nil;
    
    BlockLayoutInfo *info = [BlockLayoutInfo new];
    info.block = block;
    
    struct dk_block_layout *aLayout = (__bridge struct dk_block_layout *)block;
    
    // 没有签名
    if (!(aLayout->flags & BLOCK_HAS_SIGNATURE))
        return info;
    
    // 如果没有引用外部对象也就是没有扩展布局标志的话则直接返回。
    if (! (aLayout->flags & BLOCK_HAS_EXTENDED_LAYOUT))
        return info;
    
    uint8_t *desc = _dk_block_descriptor_3(aLayout);
    
    // 最终转化为dk_block_descriptor_3中的结构指针。并且当布局值为0时表明没有引用外部对象。
    struct dk_block_descriptor_3 *desc3 = (struct dk_block_descriptor_3 *)desc;
    if (!desc3->layout)
        return info;
    
    const char *extendedLayout = desc3->layout;
    uintptr_t *begin = (uintptr_t *)aLayout->captured;
    NSMutableSet *refObjects = [[NSMutableSet alloc] init];
    NSArray <LayoutInfoItem *> *compactEncoding = _dk_compactEncodingForLayout(extendedLayout);
    info.layoutInfos = compactEncoding;
    
    for (LayoutInfoItem *item in compactEncoding) {
        switch (item.type) {
            case BLOCK_LAYOUT_STRONG: {
                NSArray *objects = _dk_objectsForBeginAddress(begin, item.count);
                [refObjects addObjectsFromArray:objects];
                begin += item.count;
            }
                break;
            case BLOCK_LAYOUT_BYREF: {
                for (int j = 0; j < item.count; j++, begin++) {
                    struct dk_block_byref *aByref = *(struct dk_block_byref **)begin;
                    NSArray *objects = _dk_objectsByrefForBlockByref(aByref, item.count, info);
                    [refObjects addObjectsFromArray:objects];
                }
            }
                break;
            case BLOCK_LAYOUT_NON_OBJECT_BYTES: {
                begin = (uintptr_t *)((uintptr_t)begin + item.count);
            }
                break;
            default: {
                begin += item.count;
            }
                break;
        }
    }
    
    info.objects = refObjects.allObjects;
    
    return info;
}
