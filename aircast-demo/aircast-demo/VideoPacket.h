#include <objc/NSObject.h>

@interface VideoPacket : NSObject

- (instancetype)initWith:(uint8_t*)data size:(size_t)dataSize;

@property uint8_t* buffer;
@property NSInteger size;

@end

