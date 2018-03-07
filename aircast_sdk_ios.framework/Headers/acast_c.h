#ifndef _AIRCAST_SDK_C_API_HEADER__
#define _AIRCAST_SDK_C_API_HEADER__

#include <inttypes.h>

#ifdef _MSC_VER

#if defined(ACSDK_EXPORTS)
#define ACSDK_API __declspec(dllexport)
#else
#define ACSDK_API __declspec(dllimport)
#endif

#else

//#define TXCOM_API __attribute__((visibility("hidden")))
#define ACSDK_API __attribute__((visibility("default")))

#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef enum _EACMsgType
{
	eACMsgType_Error = 0, 
	eACMsgType_Info,   //some information 
	eACMsgType_Connected,
	eACMsgType_MediaDesc,
	eACMsgType_Disconnected,
	eACMsgType_VideoData,
	eACMsgType_AudioData,
	eACMsgType_LicenseRequest
}EACMsgType;

#define MAX_AC_MSG_LEN 128
typedef struct _SACErrorInfo
{
	char info[MAX_AC_MSG_LEN];
}SACErrorInfo;

typedef enum _EACMediaType
{
	eACMediaType_VideoFrame = 0,
	eACMediaType_VideoStream,
	eACMediaType_AudioFrame,
}EACMediaType;

typedef enum _EACStreamType
{
	eACStreamType_All = 0,
	eACStreamType_Video,
	eACStreamType_Audio
}EACStreamType;

#define MAX_AC_ADDR_LEN 32
#define MAX_AC_NAME_LEN 64
typedef struct _SACConnectedInfo
{
	char peerIPAddr[MAX_AC_ADDR_LEN];
	char peerName[MAX_AC_NAME_LEN];
	char peerDeviceID[MAX_AC_NAME_LEN];
	char peerModel[MAX_AC_NAME_LEN];
}SACConnectedInfo;

typedef struct _SACVideoStreamInfo
{
	int width;
	int height;
	int bitrate; //in KB unit, always zero in current
	int rotate; //0, 90, 180 or 270
	int extraDataSize;
	void* extraData; //Read only, owned by sdk inside
}SACVideoStreamInfo;

typedef struct _SACAudioFrameInfo
{
	int sampleRate;
	int channels;
	int bitsPerSample;
}SACAudioFrameInfo;

typedef struct _SACMediaDescInfo 
{
	EACMediaType mediaType;
	union
	{
		SACAudioFrameInfo audioFrame;
		SACVideoStreamInfo videoStream;
	}info;
}SACMediaDescInfo;

typedef struct _SACDisconnectInfo
{
	EACStreamType streamType;
	char info[MAX_AC_MSG_LEN];
}SACDisconnectInfo;


//for SACAVDataInfo.flags
#define ACAVDATA_FLAG_EOS 1
#define ACAVDATA_FLAG_DISCONTINUE 2
#define ACAVDATA_FLAG_NEWFORMAT 4

typedef struct _SACAVDataInfo
{
	size_t dataSize;
	void* data;
	uint64_t ts; //timestamp
	uint32_t flags; //new frame, discontinuous and etc...
}SACAVDataInfo;


typedef enum _EACResOpt  //Airplay resolution adjust options
{
	eACResOpt_Auto = 0,
	eACResOpt_1080,   //res up to 1920x1080
	eACResOpt_720,    //1280x720
	eACResOpt_480,    //640x480
}EACResOpt;

//typedef int(__stdcall *AC_CALLBACK)(EACMsgType eType, void* data, size_t dataSize);
typedef int (*AC_CALLBACK)(EACMsgType eType, void* data, size_t dataSize, void* opaque);

typedef struct _SACStartParams
{
	EACResOpt eVideoOutputResOption; //low res is useful to save resource for constain environment
	bool enableAudio; //	
	//if no broadcastName specified, use the machine's name defaultly
	const char* broadcastName;
}SACStartParams;

//error code definitions
#define AC_OK 0
#define AC_ERROR_GENERAL -1
#define AC_ERROR_INVALID_STATE -2
#define AC_ERROR_INVALID_PARAMETER -3

//NOTE: ONLY sole functionality instance could be created for one time, so there is't session/context definition

ACSDK_API int ac_setup( AC_CALLBACK listener, void* opaque);
ACSDK_API void ac_finalize(void);

//NULL for all default parameters
ACSDK_API int ac_start(const SACStartParams* params);
//ACSDK_API int ac_getState();  //useless??
//ACSDK_API int ac_reAnnouce(); //useless??
ACSDK_API void ac_stop(void);

//ACSDK_API void ac_update_license(const uint8_t* data, size_t dataSize);
ACSDK_API void ac_update_license(const char* lic);
#ifdef __cplusplus
}
#endif

#endif //_AIRCAST_SDK_C_API_HEADER__

