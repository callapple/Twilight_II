/*
**                       Clock for T2  by  James C. Smith
*/

#pragma keep "Clock"
#pragma cdev Clock
#pragma optimize -1
#pragma debug 0

#include "T2.H"
#include "Random3.h"

#pragma lint 0


#include <misctool.h>
#include <quickdraw.h>
#include <font.h>
#include <string.h>
#include <stdlib.h>
#include <control.h>
#include <resources.h>
#include <memory.h>

pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);

LongWord MakeT2Clock(void);
void LoadSetupT2Clock(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Clock(LongWord);
void SaveT2Clock(void);


#define ClockIcon                        0x0010DD01l
#define ControlList                      0x00001003l
#define IconControl                      0x00000001l
#define SetFont                          0x00000002l
#define CurrentText                      0x00000003l


char *ConfigNameStringNumber="\pClock Config Font";
char *ConfigNameStringSize="\pClock Config Size";
LongWord ConfigFontID;

Word SetupFileNumber;
GrafPortPtr SetupWindow;


ColorTable DefColorTable={0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF,0,0x0FFF};
ColorTable MyColorTable;
int CurColor=1, FirstTime,x,y, oldx, oldy,xv,yv,MoveDelay=8;
char OldTime[21]={' ',0}, NewTime[21]={' ',0}, TmpTime[21];
Long OldTick=0, TmpTick;
int work;
Word *movePtr;

LongWord BlankT2Clock(void)
{
    int TextSize[4];

	init_random(toT2Str);
    set_random_seed();
    FirstTime=2;
    memcpy(MyColorTable, DefColorTable, 32);
    SetColorTable (0, MyColorTable);
    InstallFont(ConfigFontID, 0x0000); /* select configed font */
    ClearScreen (0);
    ReadAsciiTime(TmpTime);
    TmpTime[20]=0;
    for(work=0; TmpTime[work]; work++) TmpTime[work]&=0x7F;
    MoveTo(0,0);
    CStringBounds(TmpTime+9,(Rect *) TextSize);
    xv=(random() % 2) ? 1:-1;
    yv=(random() % 2) ? 1:-1;
    x=(random() % abs((640+TextSize[1])-TextSize[3]))-TextSize[1];
    y=(random() % abs((200+TextSize[0])-TextSize[2]))-TextSize[0];
    SetBackColor(0);
    ClearScreen (0);

	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
    ReadAsciiTime(TmpTime);
    TmpTime[20]=0;
    for(work=0; TmpTime[work]; work++) TmpTime[work]&=0x7F;

    if(strcmp(NewTime, TmpTime)!=0){
        SetForeColor(CurColor);
        if(FirstTime==0){
            SetTextMode(modeXOR);
            MoveTo(oldx,oldy);
            DrawCString(OldTime+9);
        }  else FirstTime--;
        oldx=x;
        oldy=y;
        if(!MoveDelay){
            x+=xv;
            y+=yv;
            MoveDelay=8;
        }
        MoveDelay--;
        if(x+TextSize[1]<0) {xv=abs(xv), x+=xv;}
        if(y+TextSize[0]<0) {yv=abs(yv), y+=yv;}
        if(x+TextSize[3]>640) {xv=-abs(xv), x+=xv;}
        if(y+TextSize[2]>200) {yv=-abs(yv), y+=yv;}
        SetTextMode(modeOR);
        MoveTo(x,y);
        DrawCString(TmpTime+9);
        strcpy(OldTime, NewTime);
        strcpy(NewTime, TmpTime);
        CurColor=3-CurColor;
    }
    if(CurColor==2){
        if(MyColorTable[2]){
            MyColorTable[1]+=273;
            MyColorTable[2]-=273;
        }
    } else {
        if(MyColorTable[1]){
            MyColorTable[1]-=273;
            MyColorTable[2]+=273;
        }
    }
    memcpy(&MyColorTable[4], MyColorTable, 8);
    memcpy(&MyColorTable[8], MyColorTable, 16);
    TmpTick=OldTick;
    while((OldTick=TickCount())<=(TmpTick+1));
    SetColorTable (0, MyColorTable);

	}
/*    ClearScreen (0);      */
    SetPurgeStat(ConfigFontID, (word) purgeBit);
	return (LongWord) NULL;
}
#pragma debug 0
void SaveT2Clock(void)
{
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	SaveConfigResource(ConfigNameStringNumber, ConfigFontID & 0x0000FFFF);
	SaveConfigResource(ConfigNameStringSize, ConfigFontID >> 16);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Clock(LongWord ControlHit)
{
    LongWord OldConfigFontID;
	LongWord EnableFlag = 0L;
    GrafPort MyPort,*OldPort;


	if (ControlHit == SetFont){
        OldConfigFontID=ConfigFontID;
        OldPort = GetPort ();                 /* Save grafport for future restore */
        OpenPort (&MyPort);             /* Create a new port                */
        ConfigFontID=ChooseFont((longword) ConfigFontID, (word) 0);
        SetPort (OldPort);
        ClosePort (&MyPort);         /* Restore grafport and kill ours      */
        if(ConfigFontID==0)
            ConfigFontID=OldConfigFontID;
		else
            if(OldConfigFontID != ConfigFontID) EnableFlag = 1L;
    }

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
		(Word **) NewHandle ((longword) (sizeof (Word)), GetCurResourceApp(), attrLocked, NULL);
	**ConfigData = SaveValue;

/*********************************************/
/* Find a new ID for the resource and add it */
/*********************************************/

	ResourceID = UniqueResourceID (0, rT2ModuleWord);
	AddResource ((Handle) ConfigData, 0, rT2ModuleWord, ResourceID);
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

LongWord MakeT2Clock (void)
{
    CtlRecHndl junk;
	Word FileNumber;


	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Clock();
	SetCurResourceFile (FileNumber);


	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	return 2l;
}


void LoadSetupT2Clock(void)
{
/*  Option word format
**     0x0010 = Big
**     0x000F = NumSparks
*/

	ConfigFontID = (((LongWord) LoadConfigResource (ConfigNameStringSize, 0x3000)) <<16 ) | ((LongWord) LoadConfigResource (ConfigNameStringNumber, 0x8235));
}



LongWord Clock(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Clock ();
			break;
 	    case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2Clock ();
			break;
		case SaveT2:
			SaveT2Clock();
		    break;
		case LoadSetupT2:
			LoadSetupT2Clock();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
 	        break;
		case HitT2:
			Result = HitT2Clock(data2);
			break;
	}
	return Result;
}