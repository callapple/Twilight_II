/*****************************************************************************\
|*																									  *|
|*											   Messages  										  *|
|*																									  *|
|*										by: Josef W. Wankerl									  *|
|*																									  *|
|*											 Version: 1.0										  *|
|*												06/10/92											  *|
|*																									  *|
\*****************************************************************************/

#include <control.h>
#include <intmath.h>
#include <locator.h>
#include <memory.h>
#include <misctool.h>
#include <orca.h>
#include <quickdraw.h>
#include <resources.h>
#include <window.h>

#include <t2.h>

#define MainControlList		0x00000001L

#define IconCtl				0x00000001L
#define MessageTxtCtl		0x00000002L
#define MessageCtl			0x00000003L
#define RequestCtl			0x00000004L
#define MultipleTxtCtl		0x00000006L
#define MultipleCtl			0x00000006L
#define ZeroTxtCtl			0x00000007L

Word Message;		/* Display messages flag */
Word Request;		/* Display requests flag */
Word Multiple;		/* Number of messages to display */

Word SetupFileNumber;
GrafPortPtr SetupWindow;

#define MessageString	"\pMessages:  Message"
#define RequestString	"\pMessages:  Request"
#define MultipleString	"\pMessages:  Multiple"

#define BlankerName "\pTwilight II \
\x0D2Messages\x0D3 \
Blanker by Josef W. Wankerl"