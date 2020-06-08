
/********************************************
* File:	T2.h
*
* v1.0 - Josef W. Wankerl - 8 June 1992
* v1.0a - Jim R. Maricondo - 23 December 1992
* v1.0.1 - Jim R. Maricondo - 3 January 1993
* v1.0.2 - Jim R. Maricondo and James C. Smith - 9 January 1993
* v1.0.3 - Jim R. Maricondo - 31 January 1993 (bf)
* v1.0.4 - JRM - 03 Feb 1993 *ROJAC '93* - new ipc stuff
* v1.0.5 - JRM - 28 Feb 1993 *AFS_NYC!* - new blank_screen getbuffers..
* v1.0.6 - JRM - 03 Mar 1993 - new bmr and lmr, getinfo rec
* v1.0.7 - JRM - 06 Mar 1993 - (bmi/lmi/etc)
* v1.0.8 - JRM - 01 Apr 1993 - mcp lmr
* v1.0.9 - JRM - 31 May 1993 - new mr/mi for public release
* v1.1 - JRM 19 Jul 1993 - released to the public at KFest '93
*
********************************************/

#ifndef __TYPES__
#include <TYPES.h>
#endif

#ifndef __T2__
#define __T2__

#define toT2Str			"\pDYA~Twilight II~"

/* Action message codes sent to modules. */
#define MakeT2				0
#define SaveT2				1
#define BlankT2			2
#define LoadSetupT2		3
#define UnloadSetupT2		4
#define KillT2				5
#define HitT2				6

/* Resources types. */
#define rT2ModuleFlags		0x1000u
#define rT2ExtSetup1		0x1001u
#define rT2ModuleWord		0x1002u

/* DataField equates. */
#define SetFieldValue		0x8000u		/* custom control messages that are */
#define GetFieldValue		0x8001u     /* accepted by DataField            */

/* DataOut structure for t2StartupTools */
typedef struct startupToolsOut {
	Word recvCount;
	Word errors;						/* returned errors */
};

/* t2StartupTools flag bits */
#define startshut_sane		1ul
#define startshut_sound	2ul

/* DataOut structure for t2GetBuffers */
typedef struct getBuffersOut {
	Word recvCount;
	void ** shr_main_bufferH;			/* handle to bank E1 buffer */
	void ** shr_aux_bufferH;			/* handle to bank 01 buffer */
	void ** palette_bufferH;			/* handle to palette buffer */
};

/* this is wrigged to always return ALL info available */
/* to make it easier for C */

typedef struct getInfoOut {
	Word recvCount;
	Word start_offset;				/* -- $0 -- copy from this byte of the buffer */
	Word end_offset;				/* -- $E -- to this byte of the buffer */
	Word state_word;				/* state word */
	Word count_selected_modules;	/* # selected modules */
	Word tii_version;				/* version of T2 in Toolbox TN 100 format */
	void * noblank_cursor320P;		/* pointers to noblank cursors */
	void * noblank_cursor640P;
};

/*
* t2GetInfo -
* dataIn: reserved (pass zero)
* dataOut: pointer to structure
*  +00 - word output - count
*  +02 - word input - start buffer offset (FROM this byte)
*  +04 - word input - end buffer offset   (TO this byte)
* (end buffer offset minus start buffer offset = SIZE)
*  +06 - byte array output - returned information output buffer
*  +06+SIZE - eos - end of structure
*
* Buffer information available (`-`=through)
*  00,01= state word
*  02,03= number of modules selected in random mode (1 if rm off)
*  04,05= version of Twilight II
*  06,07,08,09= pointer to 320 mode don't blank cursor
*  0a,0b,0c,0d= pointer to 640 mode don't blank cursor
*/

/* T2 External IPC */
#define t2TurnOn		0x9000u
#define t2TurnOff		0x9001u
#define t2BoxOverrideOff 0x9002u
#define t2BoxOverrideOn 0x9003u
#define t2GetInfo		0x9004u
#define t2StartupTools	0x9005u
#define t2ShutdownTools 0x9006u
#define t2ShareMemory	0x9007u
#define t2SetBlinkProc	0x9008u
#define t2ForceBkgBlank 0x9009u
#define t2BkgBlankNow	0x900Au
#define t2GetBuffers	0x900Bu
#define t2Reserved1	0x900Cu	
#define t2CalcFreqOffset 0x900Du

/* bits of BlankT2's T2Result [blankMessageResult] */
#define bmrNextModule			0x01000000ul	/* goto next module */
#define bmrFadeIn				0x02000000ul	/* fade in after all */
#define bmrLeavesUsableScreen	0x04000000ul	/* leaves usable screen */
#define bmrLeavesCycleScreen	0x08000000ul	/* leaves cycle-able screen */

/* bits of LoadSetupT2's T2Result [loadMessageResult] */
#define lmrReqUsableScreen		0x0001ul	/* requires usable screen */
#define lmrFadeOut				0x0002ul	/* fade out after all */
#define lmrMostCommonPalette	0x0004ul	/* mcp after all */
#define lmrPrematureExit	 	0x0008ul	/* exits before movePtr=true */

/* Bits of flag word passed to modules at loadsetupT2 time in T2data2 (lo) */
/* lmi = loadmessageinput */
#define lmiOverrideSound	0x0001u		/* bit0- 1=override sound, 0=sound ok */

/* bits of flag word passed to mdoules at blankT2 time in T2Data2 (lo) */
/* (bmi = blankMessageInput) */
#define bmiBlankNow		0x0001u	    /* bit0- 1=from blank now, 0= not */
#define bmiCycleColors		0x0002u		/* prev mdl left cycle-able screen */

#endif /* __T2__ */