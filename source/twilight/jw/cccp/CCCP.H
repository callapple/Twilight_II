/********************************************
; File:	CCCP.h
;
; By:	 Josef W. Wankerl
;
; Copyright EGO Systems 1993
; All Rights Reserved
;
********************************************/

#ifndef __TYPES__
#include <TYPES.h>
#endif

#ifndef __LIST__
#include <LIST.h>
#endif

#ifndef __GSOS__
#include <GSOS.h>
#endif

#ifndef __STDFILE__
#include <STDFILE.h>
#endif

#ifndef __CCCP__
#define __CCCP__

/* target name for SendRequest to Cool Cursor */
#define NAME_OF_CCCP "\pEGO Systems~Cool Cursor~"

/*****************************************************************************/

/* SendRequest codes sent to Cool Cursor (target = "EGO Systems~Cool Cursor~") */
#define cccpAreYouThere	0x8000
#define cccpGetActive	0x8001
#define cccpSetActive	0x8002
#define cccpGetSpeed		0x8003
#define cccpSetSpeed		0x8004
#define cccpGetAppPriority 0x8005
#define cccpSetAppPriority 0x8006
#define cccpGetSafe		0x8007
#define cccpSetSafe		0x8008
#define cccpGetCursorList 0x8009
#define cccpSetCursorList 0x800A
#define cccpGetCursor	0x800B
#define cccpSetCursor	0x800C
#define cccpLoadCursor	0x800D
#define cccpDisposeCursor 0x800E
#define cccpAnimateCursor 0x800F
#define cccpGetCursorType 0x8010

/*****************************************************************************/

/* Cool Cursor constants */

#define cccpMode320	0x0000
#define cccpMode640	0x0001

#define cccpPointer	0x0000
#define cccpWait		0x0001
#define cccpIBeam		0x0002
#define cccpCustom	0x0003
#define cccpOther		0x0004

#define rSmooth		0x0001

#define cccpVersionError	0xCCC9

/*****************************************************************************/

/* Cool Cursor DataIn Structures */

typedef struct cccpSetActiveIn
{
	Word cccpActiveFlag;
} cccpSetActiveIn, *cccpSetActiveInPtr;

typedef struct cccpSetSpeedIn
{
	Word cccpSpeed;
} cccpSetSpeedIn, *cccpSetSpeedInPtr;

typedef struct cccpSetAppPriorityIn
{
	Word cccpPriority;
} cccpSetAppPriorityIn, *cccpSetAppPriorityInPtr;

typedef struct cccpSetSafeIn
{
	Word cccpSafeFlag;
} cccpSetSafeIn, *cccpSetSafeInPtr;

typedef struct cccpSetCursorListIn
{
	Handle cccpCursorListHandle;
} cccpSetCursorListIn, *cccpSetCursorListInPtr;

typedef struct cccpGetCursorIn
{
	Word cccpCursorMode;
} cccpGetCursorIn, *cccpGetCursorInPtr;

typedef struct cccpSetCursorIn
{
	Word cccpCursorMode;
	Handle cccpMasterHandle;
} cccpSetCursorIn, *cccpSetCursorInPtr;

typedef struct cccpLoadCursorIn
{
	GSString255Ptr cccpPathnamePtr;
	LongWord cccpCursorStartID;
} cccpLoadCursorIn, *cccpLoadCursorInPtr;

typedef struct cccpDisposeCursorIn
{
	Handle cccpMasterHandle;
} cccpDisposeCursorIn, *cccpDisposeCursorInPtr;

typedef struct cccpAnimateCursorIn
{
	Handle cccpMasterHandle;
} cccpAnimateCursorIn, *cccpAnimateCursorInPtr;

/*****************************************************************************/

/* Cool Cursor DataOut Structures */

typedef struct cccpAreYouThereOut
{
	Word recvCount;
	Word cccpID;
	LongWord cccpVersion;
} cccpAreYouThereOut, *cccpAreYouThereOutPtr;

typedef struct cccpGetActiveOut
{
	Word recvCount;
	Word cccpActiveFlag;
} cccpGetActiveOut, *cccpGetActiveOutPtr;

typedef struct cccpGetSpeedOut
{
	Word recvCount;
	Word cccpSpeed;
} cccpGetSpeedOut, *cccpGetSpeedOutPtr;

typedef struct cccpGetAppPriorityOut
{
	Word recvCount;
	Word cccpPriority;
} cccpGetAppPriorityOut, *cccpGetAppPriorityOutPtr;

typedef struct cccpGetSafeOut
{
	Word recvCount;
	Word cccpSafeFlag;
} cccpGetSafeOut, *cccpGetSafeOutPtr;

typedef struct cccpGetCursorListOut
{
	Word recvCount;
	Handle cccpCursorListHandle;
} cccpGetCursorListOut, *cccpGetCursorListOutPtr;

typedef struct cccpGetCursorOut
{
	Word recvCount;
	Handle cccpMasterHandle;
} cccpGetCursorOut, *cccpGetCursorOutPtr;

typedef struct cccpLoadCursorOut
{
	Word recvCount;
	Word cccpError;
	Handle cccpMasterHandle;
} cccpLoadCursorOut, *cccpLoadCursorOutPtr;

typedef struct cccpGetCursorTypeOut
{
	Word recvCount;
	Word cccpCursorType;
} cccpGetCursorTypeOut, *cccpGetCursorTypeOutPtr;

#endif