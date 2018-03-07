#import <Foundation/Foundation.h>
#include "VideoPacket.h"

const uint8_t KStartCode[4] = {0, 0, 0, 1};

@implementation VideoPacket

- (instancetype)initWith:(uint8_t*)data size:(size_t)dataSize
{
    self = [super init];
    self.buffer = malloc(dataSize);
    self.size = dataSize;
    
    uint32_t nalSize = (uint32_t)(self.size - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    //same as HTONL()
    self.buffer[0] = *(pNalSize + 3);
    self.buffer[1] = *(pNalSize + 2);
    self.buffer[2] = *(pNalSize + 1);
    self.buffer[3] = *(pNalSize);
    
    memcpy( self.buffer+4, data+4, dataSize-4);
    
    return self;
}

-(void)dealloc
{
    free(self.buffer);
}
@end

