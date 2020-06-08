/*
**                       Plasma for T2  by  James C. Smith
*/

#pragma keep "Plasma"
#pragma cdev Plasma
#pragma optimize -1
#pragma debug 0

#include "T2f.H"
#include "Random3.H"
#include "Plot2.h"


#define ControlList                     0x00001003

#define ColorsPopup                      0x00000001l
#define SmoothnesPopup                   0x00000002l
#define DelayPopup                       0x00000003l
#define CycleCheckBox                    0x00000004l
#define QuitAfterOneCB                   0x00000006l

#define ColorsMenu                       0x00000001
#define SmoothnesMenu                    0x00000002
#define DelayMenu                        0x00000003

/*#include <time.h>   */
#include <string.h>
#include <stdlib.h>
#include <quickdraw.h>
#include <control.h>
#include <resources.h>
#include <memory.h>
#include <orca.h>
#include <locator.h>

pascal void SysBeep() inline(0x2C03,dispatcher);
pascal LongWord TickCount() inline(0x1006,dispatcher);

#pragma lint -1

#define CycleSpeed 5

void CycleColors(void);
void subdivide(int x1, int y1, int x2, int y2);
void set_color(int xa, int ya, int x, int y, int xb, int yb);
void MySetColorTable(void);

LongWord MakeT2Plasma(void);
void LoadSetupT2Plasma(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Plasma(LongWord);
void SaveT2Plasma(void);

char *ConfigNameString="\pPlasma Configuration";
int Xres=319, Yres=199;
unsigned int ConfigSmoothnes, ConfigColors, ConfigDelay, ConfigDelay2, ConfigCycle, ConfigQuitAfterOne;
int ActSmoothnes;
Word *movePtr;
long NewTick, OldTick;
LongWord LastCycle;

Word SetupFileNumber;
GrafPortPtr SetupWindow;

long VRam;

void CycleColors(void)
{
    word tmp;

    tmp=*((word *) (VRam+0x009E02l));
    memmove((void *) (VRam+0x009E02l), (void *) (VRam+0x009E04l), 28);
    *((word *) (VRam+0x009E1El))=tmp;
}

struct getInfoOut T2Info={0,0,0xE};

LongWord BlankT2Plasma(void)
{
	init_random(toT2Str);
    set_random_seed();
    ActSmoothnes=ConfigSmoothnes-2;

    if((*((char *)0x00C035))& 0x08)
        VRam=0xE10000l;
    else
        VRam=0x010000l;
	init_plot((char *) VRam,(char *)GetAddress(1), toT2Str);

    SendRequest(t2GetInfo, stopAfterOne+sendToName, (longword) toT2Str, 0, (void *) &T2Info);

    while (!(*movePtr))
    {
        ClearScreen (0);
        MySetColorTable();
        set_pixel(0, 0, random() %16);
        set_pixel(Xres, 0, random() %16);
        set_pixel(Xres, Yres, random() %16);
        set_pixel(0, Yres, random() %16);
        subdivide(0,0,Xres,Yres);
        NewTick=OldTick=TickCount();
        while( (!(*movePtr)) && (NewTick<OldTick+(long)ConfigDelay2) ) {
            if(ConfigCycle && (TickCount() >= LastCycle+CycleSpeed))
            {
                CycleColors();
                LastCycle=TickCount();
            }
            NewTick=TickCount();
        }
        if(ConfigQuitAfterOne && (T2Info.count_selected_modules > 1))
            break;
	}
    if(*movePtr)
    {
        return (LongWord) 0;
    } else
	    return (LongWord) bmrNextModule;
}

int ColorTables[]=
{0x0007,0x0118,0x0229,0x033A,0x044B,0x055C,0x066D,0x077E,0x088F,0x099F,0x0AAF,0x0BBF,0x0CCF,0x0DDF,0x0EEF,0x0FFF,\
0x0666,0x0DDD,0x0DDD,0x0CCC,0x0BBB,0x0AAA,0x0999,0x0888,0x0777,0x0666,0x0555,0x0444,0x0333,0x0222,0x0111,0x0000,\
0x0118,0x0118,0x0118,0x0229,0x0589,0x08E8,0x07D7,0x06C6,0x05B5,0x04A4,0x0393,0x0282,0x0171,0x0260,0x0350,0x0240,\
0x0000,0x0C30,0x0960,0x0690,0x03C0,0x00F0,0x00C3,0x0096,0x0069,0x003C,0x000F,0x030C,0x0609,0x0906,0x0C03,0x0F00,\
0x0000,0x0FF0,0x0FD0,0x0FB0,0x0F90,0x0F70,0x0F50,0x0F30,0x0F10,0x0F30,0x0F50,0x0F70,0x0F90,0x0FB0,0x0FD0,0X0FE0};
/*{0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0}*/

void MySetColorTable(void)
{
    int tmp;

    tmp=ConfigColors;
    if(!tmp)
        tmp=random() % 5;
    else
        tmp--;
    memcpy((void *)(VRam+0x009E00l), &ColorTables[tmp<<4], 32);
}


void subdivide(int x1, int y1, int x2, int  y2)
{
    int x,y,color;

    if (*movePtr)
        return;
    if(ConfigCycle && (TickCount() >= LastCycle+CycleSpeed))
    {
        CycleColors();
        LastCycle=TickCount();
    }
    if((x2-x1<2) && (y2-y1<2))
        return;
    x=(x1+x2)>>1;
    y=(y1+y2)>>1;
    set_color(x1,y1,x,y1,x2,y1);
    set_color(x2,y1,x2,y,x2,y2);
    set_color(x1,y2,x,y2,x2,y2);
    set_color(x1,y1,x1,y,x1,y2);
    color=(get_pixel(x1,y1)+get_pixel(x2,y1)+get_pixel(x2,y2)+get_pixel(x1,y2))>>2;
    if(!get_pixel(x,y))
        set_pixel(x,y,color);
    subdivide(x1,y1,x,y);
    subdivide(x,y1,x2,y);
    subdivide(x,y,x2,y2);
    subdivide(x1,y,x,y2);
}

void set_color(int xa, int ya, int x, int y, int xb, int yb)
{
    long color;

    if(get_pixel(x,y))
        return;
    color=abs(xa-xb) + abs(ya-yb);
    if(ActSmoothnes>0)
        color>>=ActSmoothnes;
    if(ActSmoothnes<0)
        color<<=abs(ActSmoothnes);
    if(!color)
        color=1;
    color=(random() % (color<<1)+1 )-color;
    color+=(get_pixel(xa,ya)+get_pixel(xb,yb))>>1;
    if(color<1)
        color=1;
    if(color>15)
        color=15;
    set_pixel(x,y,(int) color);
}

void SaveT2Plasma(void)
{
    word OptionWord;
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigSmoothnes = GetCtlValue (GetCtlHandleFromID (SetupWindow, SmoothnesPopup));
	ConfigColors = GetCtlValue (GetCtlHandleFromID (SetupWindow, ColorsPopup))-1;
	ConfigDelay = GetCtlValue (GetCtlHandleFromID (SetupWindow, DelayPopup));
	ConfigCycle = GetCtlValue (GetCtlHandleFromID (SetupWindow, CycleCheckBox));
	ConfigQuitAfterOne = GetCtlValue (GetCtlHandleFromID (SetupWindow, QuitAfterOneCB));
    OptionWord=(ConfigSmoothnes<< 12) | (ConfigColors << 8) | (ConfigDelay << 4) | (ConfigQuitAfterOne << 1) | ConfigCycle;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Plasma(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == ColorsPopup)
		EnableFlag = 1L;
	if (ControlHit == SmoothnesPopup)
		EnableFlag = 1L;
	if (ControlHit == DelayPopup)
		EnableFlag = 1L;
	if (ControlHit == CycleCheckBox)
		EnableFlag = 1L;
	if (ControlHit ==QuitAfterOneCB)
		EnableFlag = 1L;

	return EnableFlag;
}

/*****************************************************************************\
|*																									  *|
|*	LoadConfigResource-	(updated)																  *|
|*			This function attempts to load a named rT2ModuleWord resource.  if  *|
|*			the resource exists, the value of the rT2ModuleWord resource is	  *|
|*			returned, otherwise a default value is returned.						  *|
|*																									  *|
\*****************************************************************************/

Word LoadConfigResource (char *Name, Word DefaultValue)
{
	Word Result, fileID;
	Long rID;
	Handle ConfigData;
    struct {
        word Type;
        Long ID;
    } HandleInfo;


/**************************************/
/* Attempt to load the named resource */
/**************************************/

	rID = RMFindNamedResource((Word) rT2ModuleWord, (Ptr) Name, &fileID);

	ConfigData = LoadResource((Word) rT2ModuleWord, rID);
	if (toolerror ())
		Result = DefaultValue; /* Resource does not exist, so return the default value */
	else
   {
       HLock(ConfigData);  /* Resource exists, return the rT2Module word value */
		Result = **(word **)ConfigData;
		HUnlock(ConfigData);

		ReleaseResource(3, (Word) rT2ModuleWord, rID);
    }

	 return Result;
}


/*****************************************************************************\
|*																									  *|
|*		SaveConfigResource-																	  *|
|*			This function takes a word value and saves it as a rT2ModuleWord	  *|
|*			resource in the Twilight.Setup file.  The value is saved and a		  *|
|*			name is added.  Any previous rT2ModuleWord with the same name is	  *|
|*			first removed before the new value is added.								  *|
|*																									  *|
\*****************************************************************************/

void SaveConfigResource (char *Name, Word SaveValue)
{
	Word FileID;
	Long ResourceID;
	Word **ConfigData;

/******************************************************/
/*  Check to see if the named resource already exists */
/******************************************************/

	ResourceID = RMFindNamedResource (rT2ModuleWord, Name, &FileID);
	if (!toolerror ())
	{
		char NullString = '\x000';

/**************************************************************/
/* The resource already exists, so first remove the name from */
/*	the resource, then remove the resource itself				  */
/**************************************************************/

		RMSetResourceName (rT2ModuleWord, ResourceID, &NullString);
		RemoveResource (rT2ModuleWord, ResourceID);
	}

/*********************************************/
/* Create new handle for the future resource */
/*********************************************/

	ConfigData =
		(Word **) NewHandle (sizeof (Word), GetCurResourceApp(), attrLocked, 0L);
	**ConfigData = SaveValue;

/*********************************************/
/* Find a new ID for the resource and add it */
/*********************************************/

	ResourceID = UniqueResourceID (0, rT2ModuleWord);
	AddResource((Handle) ConfigData, 0, rT2ModuleWord, ResourceID);
	if (toolerror ())
		DisposeHandle ((Handle) ConfigData);
	else
	{

/**********************************************************/
/* Set the name of the resource if it was added correctly */
/**********************************************************/

		RMSetResourceName (rT2ModuleWord, ResourceID, Name);
		UpdateResourceFile (SetupFileNumber);
		/*DisposeHandle (ConfigData);     */
	}
}


LongWord MakeT2Plasma (void)
{
    CtlRecHndl junk;
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Plasma();
	SetCurResourceFile (FileNumber);
	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigSmoothnes, GetCtlHandleFromID (SetupWindow, SmoothnesPopup));
	SetCtlValue (ConfigColors+1, GetCtlHandleFromID (SetupWindow, ColorsPopup));
	SetCtlValue (ConfigDelay, GetCtlHandleFromID (SetupWindow, DelayPopup));
	SetCtlValue (ConfigCycle, GetCtlHandleFromID (SetupWindow, CycleCheckBox));
	SetCtlValue (ConfigQuitAfterOne, GetCtlHandleFromID (SetupWindow, QuitAfterOneCB));
	return 6;
}

unsigned int DelayLookup[]={0,5*60, 10*60, 15*60, 30*80, 1*60*80, 2*60*60, 3*60*60, 5*60*60};



void LoadSetupT2Plasma(void)
{
    word OptionWord;

/*  Option word format
**     0xF000 = Smoothnes
**     0x0F00 = Colors
**     0x00F0 = Delay (pos in list)
**     0x0002 = Quit After One
**     0x0001 = Cycle flag
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x5040);
    ConfigSmoothnes = OptionWord >> 12;
    ConfigColors = (OptionWord & 0x0F00) >> 8;
    ConfigDelay = (OptionWord & 0x00F0) >> 4;
    ConfigDelay2 = DelayLookup[ConfigDelay-1];
    ConfigQuitAfterOne = (OptionWord & 0x0002) >> 1;
    ConfigCycle = OptionWord & 0x0001;
}



LongWord Plasma(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Plasma ();
			break;
 	    case BlankT2:
            if(data2 & bmiBlankNow)
                ConfigQuitAfterOne=0;
            movePtr=(Word *) data1;
 		    Result = BlankT2Plasma ();
			break;
		case SaveT2:
			SaveT2Plasma();
		    break;
		case LoadSetupT2:
			LoadSetupT2Plasma();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result = HitT2Plasma(data2);
			break;
	}
	return Result;
}