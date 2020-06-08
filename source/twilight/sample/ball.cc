
/*
** Ball, Release v1.0 - 19 July 1993.
**        Initial release for KansasFest '93.
**       Release v1.1 - 8 July 1994.
**        Sound routine oversights fixed and other misc. improvements.
**
** C Source Code - "ball.cc" - Main Source Segment         (4 spaces = 1 tab)
**
**  A Twilight II module by James C Smith and James R Maricondo.
**  Parts based off the original T2 C shell by Josef Wankerl.
**  Nothing fancy, this is mainly for demo/example purposes only!
**
** Copyright 1993-94 DigiSoft Innovations, All Rights Reserved.
**
** Permission granted to use this source in any module designed for
**  Twilight II for the Apple IIGS.
*/

/* pragmas */

#pragma keep "Ball.d"
#pragma cdev Ball
#pragma optimize -1
#pragma debug 0

/* defines */

#define ballCtlList		1l

#define RedStr			1l
#define BlueStr			2l
#define GreenStr		3l
#define PurpleStr		4l
#define YellowStr		5l
#define TurquoiseStr	6l
#define ballColorStr	10l
#define useSoundStr		20l

#define colorMenu		1l

#define colorCtl		1l
#define useSoundCtl		2l
#define ballStrCtl		3l
#define ballIconCtl		4l
#define ballLineCtl		5l

#define blueMenuItem	1l
#define greenMenuItem	2l
#define redMenuItem		3l
#define turquoiseMenuItem 4l
#define purpleMenuItem	5l
#define yellowMenuItem	6l

typedef struct rSoundSampleType {
     int SoundFormat;
     int WaveSize;
     int RealPitch;
     int StereoChannel;
     unsigned int SampleRate;
     char StartOfWaveData;
};


/* includes */

#include "T2.h"		/* include the C twilight II header file */
#include <quickdraw.h>
#include <control.h>
#include <resources.h>
#include <orca.h>		/* for toolerror only */
#include <memory.h>
#include <sound.h>
#include <locator.h>
#include <loader.h>
#include <misctool.h>	/* for SysBeep only */

#pragma lint -1


/* prototypes */

LongWord Ball(LongWord, LongWord, Word);
LongWord MakeT2Ball(void);
void LoadSetupT2Ball(void);
void SaveConfigResource(char *, Word);
Word LoadConfigResource(char *, Word);
LongWord HitT2Ball(LongWord);
void SaveT2Ball(void);
void make_palette(int, Word *);
handle LoadASound(unsigned long ResID, word *);
void PlayASound(handle, int, word);
void cycle(void);


/* globals */

Word MyID; 							/* our memory manager ID */
Word soundStatus;					/* boolean: old status of sound tool */

char *ConfigNameString="\pBall Setup"; /* rName to save config data under */

unsigned int BallColor, SoundFlag;
Word *movePtr; 						/* TRUE when we should exit the module */

Word SetupFileNumber;
GrafPortPtr SetupWindow;

Long X,Y,XV,YV, BallSize, GravityValue;
Rect MyRect;
Word MyColorTable[16];

Handle SoundHandleBoing;			/* handle to the boing rSound */
Word BoingFreq;						/* (converted) frequency of boing */
struct rSoundSampleType *SoundPtr;
Word LastGen, GenNum=0;
struct SoundParamBlock SoundPB;

/* this is the structure that allows us to have T2 convert the rSound header
   frequency to a frequency we can pass to FFStartSound */
struct freqOffsetOut FreqOut;


/* other source files */

#include "config.cc"


/* main functions */

/*
** BlankT2 message handler: Do the animation!
*/

LongWord BlankT2Ball(void) {

	unsigned int temp;
	int color = 0;
	int bounce = 0;
	int cycleIt = 0;

	struct startupToolsOut ballToolsOut;
	Ptr	ballToolsOutP = (Ptr) &ballToolsOut;

/* Start the sound tools if we need to */
/* Note that ball will only use sound if WE start the sound tools ourselves.
   If they were started by someone else, it's not safe to use them. */

	soundStatus = SoundToolStatus();
	if (!soundStatus) {
		SendRequest(t2StartupTools, stopAfterOne+sendToName, (long) toT2Str,
			(long) (((long) MyID<<16) + startshut_sound),
			(Ptr) ballToolsOutP);
		if (ballToolsOut.errors) {		/* if error starting up, bail out! */
			SysBeep();
			return (LongWord) NULL;
		}
	}
	
    make_palette(BallColor, &MyColorTable[0]);
    SetColorTable(0, MyColorTable);
	
    BallSize=10;
    GravityValue=8000;
    X=100<<16;
    Y=15<<16;
    XV=4<<16;
    YV=0;
	SetPenMode(modeCopy);

	while (!(*movePtr)) {				/* until MovePtr is true, do it! */
        YV+=GravityValue;				/* increase gravity */
        X+=XV;							/* update x velocity */
        Y+=YV;							/* update y velocity */
        if( (X+BallSize > (320<<16)) | (X-BallSize<0) ) {
			XV=-XV;						/* bounce off the sides */
			if (X+BallSize > (320<<16))	/* boing! */
				PlayASound(SoundHandleBoing, 0, BoingFreq);	/* right boing */
			else PlayASound(SoundHandleBoing, 1, BoingFreq);/* left boing */
		}
		if( (Y+BallSize > (200<<16)) | (Y-BallSize<0) ) {
			YV=-YV;						/* bounce off the bottom */
			bounce++;					/* increment bottom bounce counter */
		}

        MyRect.v1=(Y>>16)-BallSize;		/* move the ball! */
        MyRect.h1=(X>>16)-BallSize;
        MyRect.v2=(Y>>16)+BallSize;
        MyRect.h2=(X>>16)+BallSize;

        color = (color+1)&0xF;
        if (!color) color = 1;			/* no black! */
		SetSolidPenPat(color);			/* draw the ball! */
        PaintOval(&MyRect);

		if (((++cycleIt)&3)==0)			/* cycle every 4th time */
			cycle();

		if (bounce > 30) {				/* restart from beginning */
		    GravityValue=8000;
			X=X>>1;
		    Y=15<<16;
		    XV=4<<16;
		    YV=0;
			bounce = 0;
		    ClearScreen(0);
		}

    }

/* Shutdown the sound tools if we started them... */

	if (!soundStatus)
		SendRequest(t2ShutdownTools, stopAfterOne+sendToName, (long) toT2Str,
			(long) startshut_sound,
			(long) NULL);

/* No error occurred, so return a NULL handle */

	return (LongWord) NULL;
}



/*
** cycle - do the color cycling - quick and dirty assembly
*/

void cycle(void) {

	Word temp;

	asm {
		lda 0xe19e02
		sta temp
		lda 0xe19e04
		sta 0xe19e02
		lda 0xe19e06
		sta 0xe19e04
		lda 0xe19e08
		sta 0xe19e06
		lda 0xe19e0a
		sta 0xe19e08
		lda 0xe19e0c
		sta 0xe19e0a
		lda 0xe19e0e
		sta 0xe19e0c
		lda 0xe19e10
		sta 0xe19e0e
		lda 0xe19e12
		sta 0xe19e10
		lda 0xe19e14
		sta 0xe19e12
		lda 0xe19e16
		sta 0xe19e14
		lda 0xe19e18
		sta 0xe19e16
		lda 0xe19e1a
		sta 0xe19e18
		lda 0xe19e1c
		sta 0xe19e1a
		lda 0xe19e1e
		sta 0xe19e1c
		lda temp
		sta 0xe19e1e
	};
}
		
		

/*
** make_palette-given a color like $100 or $110, create a whole gradient
**              palette - e.g. $100, $200, ... $F00; or $110, $220 .. $FF0, etc
*/

void make_palette(int base, Word * palette) {

	Word color = base;
	int i;

	*palette = 0;
	for (i = 1; i<=15; i++) {
		palette++;
		*palette = color;
		color += base;
	}
}



/*
** SaveT2 message handler: Save our configuration to disk
*/

void SaveT2Ball(void) {

    Word OptionWord;
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);

/* Get control values */

	BallColor = GetCtlValue (GetCtlHandleFromID (SetupWindow, colorCtl));
	SoundFlag = GetCtlValue (GetCtlHandleFromID (SetupWindow, useSoundCtl));

/* combine them to our 2 byte option word format */

	OptionWord = BallColor;

	if (SoundFlag)
		OptionWord |= 0x8000;

/* Save control values */

	SaveConfigResource(ConfigNameString, OptionWord);

/* Restore old resource file */

	SetCurResourceFile (FileNumber);
}



/*
** HitT2 message handler: enable save when the popup or check box have been
**                        changed
*/

LongWord HitT2Ball(LongWord ControlHit) {

	LongWord EnableFlag = 0L;

	if (ControlHit == 1 || ControlHit == 2)
		EnableFlag = 1L;

	return EnableFlag;
}



/*
** MakeT2 message handler: make our setup controls and set them to their
**                         last saved or default values
*/

LongWord MakeT2Ball(void) {

	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile(SetupFileNumber);
	LoadSetupT2Ball();
	SetCurResourceFile(FileNumber);
	NewControl2(SetupWindow, resourceToResource, (long) ballCtlList);
	SetCtlValue(BallColor, GetCtlHandleFromID (SetupWindow, colorCtl));
	SetCtlValue(SoundFlag, GetCtlHandleFromID (SetupWindow, useSoundCtl));

	return 5L;	/* tell T2 we just made 5 controls with ids from 1 thru 5 */
}



/*
** LoadSetupT2 message handler: load the last saved setup values from the
**                              Twilight.Setup file on disk
*/

void LoadSetupT2Ball(void) {
	
    Word OptionWord;

/*  Option Word format
 *     0x0FFF = ball color, in a format that can be passed to make_palette
 *              (above) - also the menu item ID of the currently selected
 *              color 
 *     0x8000 = (bit 15) boolean - 1=use sound, 2=no sound
 */

	OptionWord = LoadConfigResource (ConfigNameString, 0x8110);
    BallColor = OptionWord & 0x0FFF;
	SoundFlag = OptionWord & 0x8000;
}




/*
** LoadASound - load an rSound from our resource fork and use a T2 IPC
**              request to have T2 convert the rSound header frequency to
**              a frequency we can use with FFStartSound
**
** NOTE that our resource fork must be opened beforehand!!!
*/

handle LoadASound(unsigned long ResID, word *freqOffset) {

    handle WorkHandle;

    WorkHandle=LoadResource(rSoundSample, ResID);
    if(toolerror())
        return 0;
    DetachResource(rSoundSample, ResID);
    SetHandleID(MyID, WorkHandle);
    HLock(WorkHandle);
    SoundPtr=(void *) *WorkHandle;
    SendRequest(t2CalcFreqOffset, stopAfterOne+sendToName, (longword) toT2Str,
				(long) (SoundPtr->RealPitch),(void *) &FreqOut);
    *freqOffset=FreqOut.freqOffset;
    HUnlock(WorkHandle);
    return WorkHandle;
}



/*
** PlayASound - play a sound effect.  Note that this routine only uses a
**              maximum of 2 oscillators (you can change it :-)
*/

void PlayASound(handle SoundHandle, int Channel, word Frequency) {

/* there are three cases where we will not have sound:
    1) the global sound override flag is set (in Setup: Options)
    2) the use sound checkbox is unchecked (in Ball's own options screen)
    3) the sound manager was already started when we were called (e.g. we
       didn't have to start it ourselves).  in this case, it's not safe to use
       sound effects
*/

    if((!SoundFlag)||(soundStatus)) /* are we supposed to have sound FX? */
        return;

    HLock(SoundHandle);	
    SoundPtr=(void *) *SoundHandle;

    SoundPB.waveStart=&SoundPtr->StartOfWaveData;
    SoundPB.waveSize=SoundPtr->WaveSize;
    SoundPB.freqOffset=Frequency;
    SoundPB.docBuffer=GenNum<<15;
    SoundPB.bufferSize=0x6;
    SoundPB.nextWavePtr=NULL;
    SoundPB.volSetting=255;
    FFStopSound((word) (1<<(GenNum&1)));	/* stop anything from earlier */
    FFStartSound((word) (Channel<<12 | ((GenNum&1)<<8) | ffSynthMode),
				(Pointer) &SoundPB);
    ++GenNum;						/* use a different generator next time */
    HUnlock(SoundHandle);
}



/*
** The Main Message Handler!  This dispatches the appropriate handler!
*/

LongWord Ball(LongWord data2, LongWord data1, Word message) {

	LongWord Result = 1L;
    word MyResFile, OldResFile;

	MyID=MMStartUp();			/* get our memory ID for the procs to use */
	switch (message) {
        case MakeT2:			/* draw and set our setup controls */
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Ball();
			break;
 	    case BlankT2:			/* blank the screen */
            movePtr=(Word *) data1;
 		    Result = BlankT2Ball();
			break;
		case SaveT2:			/* save the setup */
			SaveT2Ball();
		    break;
		case LoadSetupT2:		/* load the setup */
			LoadSetupT2Ball();	/* first actually load it then load sound */
			if ((int)data2&lmiOverrideSound==lmiOverrideSound)	
				SoundFlag=0;	/* respect global sound override flag */
			if (SoundFlag) {	/* load the rSound! */
    			OldResFile=GetCurResourceFile(); /* open our rfork! */
    			MyResFile=OpenResourceFile(1 /* read only */,
										NULL, LGetPathname2(MyID, 0x0001));
                SoundHandleBoing= LoadASound(1, &BoingFreq);
    			CloseResourceFile(MyResFile);	/* close our rfork */
    			SetCurResourceFile(OldResFile);	/* restore old resfile */
			}
            break;
		case HitT2:				/* handle control hit */
			Result = HitT2Ball(data2);
			break;
		case UnloadSetupT2:		/* unload our setup */
			if (SoundFlag)		/* dispose the sound, if loaded */
	        	DisposeHandle(SoundHandleBoing);
			break;
		case KillT2:			/* don't do anything special for KillT2 */
			break;
	}
	return Result;
}