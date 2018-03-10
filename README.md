# aircast-ios

airplay mirroring and airplay casting SDK  


## Feature

- support sender and receiver on the same device
- can work without network
- raw h264 data out support
- hardware decode support with a low cpu usage
- audio data out support
- multi sessions support



## How to use 

```
pod 'aircast', :git => 'https://github.com/AirCastLab/aircast-ios.git'
```

then 

```
#import <aircast_sdk_ios/acast_c.h>
```

## Docs 


###  AC_CALLBACK

aircast instance callbacks

```
static int ac_callback( EACMsgType eType, void* data, size_t dataSize, void* opaque)
{
    switch (eType)
    {
        case eACMsgType_Error:
        {
            // error callback 
            break;
        }
        case eACMsgType_Info:
            // info callback
            break;
        case eACMsgType_Connected:
            // connected callback
            break;
        case eACMsgType_MediaDesc:
            // media desc callback, include audio and video 
            break;
        case eACMsgType_Disconnected:
            // disconnected clalback
            break;
        case eACMsgType_VideoData:
            // video data callback 
            break;
        case eACMsgType_AudioData:
            // audio data callback
            break;
        case eACMsgType_LicenseRequest:
            // license need request, when the sdk need license 
            ac_update_license(*license);
            break;
    }
}

```

### ac_setup 

aircat setup  

```
int ac_setup( AC_CALLBACK listener, void* opaque)

```

### ac_start

```
int ac_start(const SACStartParams* params)
```

### ac_stop 

```
void ac_stop(void);

```

### ac_finalize

```
void ac_finalize(void);
```

### ac_update_license

```

void ac_update_license(const char* license);

```



## Tips

- the demo is just for testing, please do not use in production
- if you does not provide license, the demo just can work for several minutes
- we only release the iOS sdk, other Platforms(android/windows/linux/mac) SDK can contact us 


## Contact & Commercial Licensing

- Email: leeoxiang@gmail.com 

