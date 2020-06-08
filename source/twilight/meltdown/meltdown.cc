
#pragma keep "meltdown.d"
#pragma cdev meltdown
#pragma optimize -1

#include <quickdraw.h>
#include "22:t2.h"
#include "22:link:random3.h"
#include <locator.h>

extern pascal LongWord GetTick(void) inline(0x2503,dispatcher);

#pragma lint -1
#pragma debug 0

#define SHR_BYTE_WIDTH 160
#define SHR_HEIGHT		199
#define TICKS_PER_SECOND 60
#define TICKS_PER_MINUTE TICKS_PER_SECOND*60
#define CLEAR_DELAY	TICKS_PER_SECOND*3*50

/* Strings */

char toT2String[]=toT2Str;

/* Prototypes */

	LongWord BlankT2Message(Word);

/* externals */

	extern void init_save_restore(char * screenPtr, char * lookupPtr);
	extern void save_pixels(char *, int, int, int);
	extern void restore_pixels(char *, int, int, int);
	extern void scroll_rect(Rect * rect, char * buffer);
	extern void restore_screen(void *);

/* Global Variables */

	Word *movePtr;
/*	unsigned int *ScreenTablePtr; */
	char *VRam;
	char pixels[160];
   

/*****************************************************************************\
|* BlankT2Message-																		  *|
|*  This function performs the screen blanking activities.				  *|
\*****************************************************************************/

LongWord BlankT2Message (Word blank_flags) {

	word temp,i;
	int start_byte_offset, byte_width, top;
	Rect newr;
	word start_left, end_right, width;

	long TargetTick;

	struct getBuffersOut meltBuffersOut;
	Ptr meltBuffersOutP = (Ptr) &meltBuffersOut;

	struct getInfoOut myGetInfoOut = {NULL,0,0xE,NULL,NULL,NULL,NULL,NULL};
	Ptr myGetInfoOutP = (Ptr) &myGetInfoOut;

   
	init_random(toT2String);

	if((*((char *)0xE0C035))& 0x08)
		VRam=(void *) 0xE10000l;
	else
		VRam=(void *) 0x010000l;

	init_save_restore((char *) VRam, (char *) GetAddress(1));

	SendRequest(t2GetBuffers, stopAfterOne+sendToName, (long) toT2String,
		(long) NIL, (Ptr) meltBuffersOutP);
      
	SendRequest(t2GetInfo, stopAfterOne+sendToName, (long) toT2String,
		(long) NIL, (Ptr) myGetInfoOutP);

	TargetTick = GetTick() + CLEAR_DELAY;

	while (!(*movePtr)) {

		do {

			while ((start_left = (random() & 0xFF)) >= 160)
				;
			while ((width = (random() & 0xFF)) > 160)
				;

			start_left &= 0xFFFE;
			width &= 0xFFFE;

			end_right = width+start_left;

/*			while (end_right > 160)
				end_right -= 4;    */

			if (width < 0)
				width = 10;

		} while (((end_right-start_left) > 30) || (end_right > 160));

		newr.h1 = start_left;
		newr.h2 = end_right;
		newr.v1 = random() % (SHR_HEIGHT/*+1*/);
		newr.v2 = SHR_HEIGHT;

/*		byte_width = newr.h2 - newr.h1;
		start_byte_offset = newr.h1;
		top = newr.v1;*/

		scroll_rect((Rect *)&newr, (char *)&pixels);

		if (GetTick() > TargetTick) {

			if ( ((blank_flags&bmiBlankNow) == bmiBlankNow) ||
			 (myGetInfoOut.count_selected_modules == 1) ) {
				TargetTick = GetTick() + CLEAR_DELAY;
				restore_screen(*meltBuffersOut.shr_main_bufferH);
			}

			else
				return (LongWord) bmrNextModule;
		}
	}

/* No error occurred, so return a NULL handle */

	return (LongWord) NULL;
}

/*****************************************************************************\
|* Messages-																				  *|
|*  This function checks the Twilight II message parameter and
|*  dispatches control to the appropriate message handler.
\*****************************************************************************/

LongWord meltdown (LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 1L;

	switch (message)
	{
		case BlankT2:
			movePtr=(Word *) data1;
			Result=BlankT2Message((Word) data2);
			break;
		case LoadSetupT2:
		case MakeT2:
		case SaveT2:
		case UnloadSetupT2:
		case KillT2:
		case HitT2:
			Result=NULL;
			break;
	}

	return Result;
}