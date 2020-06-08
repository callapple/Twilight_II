/*
**                       StringArt for T2  by  James C. Smith
*/

#pragma keep "StringArt"
#pragma cdev StringArt
#pragma optimize -1
#pragma debug 0

#include "T2f.H"
#include "Random3.h"

#pragma lint 0


#include <stdlib.h>
#include <quickdraw.h>
#include <control.h>
#include <resources.h>
#include <memory.h>
#include <locator.h>
#include <string.h>

pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);


LongWord MakeT2StringArt(void);
void LoadSetupT2StringArt(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2StringArt(LongWord);
void SaveT2StringArt(void);
void Wait(int);
int SinInt(int);
int CosInt(int);

#define StringArtIcon                    0x0010DD01l
#define ControlList                      0x00001003l
#define IconControl                      0x00000001l
#define DelayPU                          0x00000002l
#define NumLinesPU                       0x00000003l
#define QuitAfterOneCB                   0x00000004l


char *ConfigNameString="\pString Art Config";

Word SetupFileNumber;
GrafPortPtr SetupWindow;


Long OldTick=0, TmpTick;
Word *movePtr;
word ConfigDelay, ConfigNumLines=100, ConfigQuitAfterOne;
extended ActualSpeed;
word OptionWord;
ColorTable  MyColorTable;


void Wait(int WaitLength)
{
    TmpTick=OldTick;
    while(((OldTick=TickCount())<=TmpTick+WaitLength) && (!(*movePtr)));
}


int SinTable[]={
320,325,331,336,342,347,353,358,364,370,375,381,386,391,397,402,408,413,418,
424,429,434,439,445,450,455,460,465,470,475,479,484,489,494,498,503,508,512,
517,521,525,529,534,538,542,546,550,554,557,561,565,568,572,575,578,582,585,
588,591,594,597,599,602,605,607,610,612,614,616,618,620,622,624,626,627,629,
630,631,633,634,635,636,636,637,638,638,639,639,639,639,639,639,639,639,639,
638,638,637,636,636,635,634,633,631,630,629,627,626,624,622,620,618,616,614,
612,610,607,605,602,599,597,594,591,588,585,582,578,575,572,568,565,561,557,
554,550,546,542,538,534,529,525,521,517,512,508,503,498,494,489,484,480,475,
470,465,460,455,450,445,439,434,429,424,418,413,408,402,397,391,386,381,375,
370,364,358,353,347,342,336,331,325,320,315,309,304,298,293,287,282,276,270,
265,259,254,249,243,238,232,227,222,216,211,206,201,195,190,185,180,175,170,
165,161,156,151,146,142,137,132,128,123,119,115,111,106,102,98,94,90,86,
83,79,75,72,68,65,62,58,55,52,49,46,43,41,38,35,33,30,28,
26,24,22,20,18,16,14,13,11,10, 9, 7, 6, 5, 4, 4, 3, 2, 2,
 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4, 4, 5, 6, 7, 9,10,
11,13,14,16,18,20,22,24,26,28,30,33,35,38,41,43,46,49,52,
55,58,62,65,68,72,75,79,83,86,90,94,98,102,106,111,115,119,123,
128,132,137,142,146,151,156,160,165,170,175,180,185,190,195,201,206,211,216,
222,227,232,238,243,249,254,259,265,270,276,282,287,293,298,304,309,315};


int SinInt(int Degre)
{
    Degre%=360;
    return SinTable[Degre];
}

int CosInt(int Degre)
{
    Degre+=90;
    Degre%=360;
    return SinTable[Degre];
}


int XMultiplyer1, YMultiplyer1, XAdder1, YAdder1;
int XMultiplyer2, YMultiplyer2, XAdder2, YAdder2;
int Angle;

struct getInfoOut T2Info={0,0,0xE};

LongWord BlankT2StringArt(void)
{
    word RandomColor, R, G, B;

    init_random(toT2Str);
    set_random_seed();

    SendRequest(t2GetInfo, stopAfterOne+sendToName, (longword) toT2Str, 0, (void *) &T2Info);

    ActualSpeed=360 / (ConfigNumLines*20);
    SetSolidPenPat(15);
	SetPenMode(modeCopy);
	SetPenSize(1, 1);
    memset(MyColorTable, 0, sizeof MyColorTable);
	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
        ClearScreen(0);
        do {
            R=random() % 16;
            G=random() % 16;
            B=random() % 16;
        } while ((R<9) && (G<9) && (B<9));
        RandomColor=(R<<8) | (G<<4) | B;
        MyColorTable[3]=RandomColor;
        MyColorTable[7]=RandomColor;
        MyColorTable[11]=RandomColor;
        MyColorTable[15]=RandomColor;
        SetColorTable(0, MyColorTable);
        do {
            XMultiplyer1=random() % 4;
            YMultiplyer1=random() % 4;
            XMultiplyer2=random() % 4;
            YMultiplyer2=random() % 4;
        } while((XMultiplyer1==0) + (YMultiplyer1==0) + (XMultiplyer2==0) + (YMultiplyer2==0)>2);
        XAdder1=random() % 360;
        YAdder1=random() % 360;
        XAdder2=random() % 360;
        YAdder2=random() % 360;

        for(Angle=0; (Angle <360) && (*movePtr==0); Angle+=ActualSpeed)
        {
            MoveTo(CosInt(Angle * XMultiplyer1 + XAdder1) ,SinInt(Angle * YMultiplyer1 + YAdder1) * 50 / 160);
            LineTo(CosInt(Angle * XMultiplyer2 + XAdder2) ,SinInt(Angle * YMultiplyer2 + YAdder2) * 50 / 160);
        }
        if(ConfigDelay)
        {
            Wait(0);
            Wait(ConfigDelay*60);
        }
        if(ConfigQuitAfterOne && (T2Info.count_selected_modules > 1))
            break;
	}
    if(*movePtr)
	    return (LongWord) 0;
    else
	    return (LongWord) bmrNextModule;
}

void SaveT2StringArt(void)
{
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigDelay = GetCtlValue (GetCtlHandleFromID (SetupWindow, DelayPU))-1;
	ConfigNumLines = GetCtlValue (GetCtlHandleFromID (SetupWindow, NumLinesPU));
	ConfigQuitAfterOne = GetCtlValue (GetCtlHandleFromID (SetupWindow, QuitAfterOneCB));
    OptionWord=(ConfigQuitAfterOne<<15)|(ConfigDelay << 4) | ConfigNumLines;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2StringArt(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == DelayPU)
		EnableFlag = 1L;
	if (ControlHit == NumLinesPU)
		EnableFlag = 1L;
	if (ControlHit == QuitAfterOneCB)
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

LongWord MakeT2StringArt (void)
{
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2StringArt();
    SetCurResourceFile (FileNumber);
	NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigDelay+1, GetCtlHandleFromID (SetupWindow, DelayPU));
	SetCtlValue (ConfigNumLines, GetCtlHandleFromID (SetupWindow, NumLinesPU));
	SetCtlValue (ConfigQuitAfterOne, GetCtlHandleFromID (SetupWindow, QuitAfterOneCB));
	return 0x04l;
}


void LoadSetupT2StringArt(void)
{
/*  Option word format
**     0x8000 = QuitAfterOne
**     0x00F0 = Daley
**     0x000F = NumLines
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x0029);
    ConfigQuitAfterOne = (OptionWord & 0xF000) >> 15;
    ConfigDelay = (OptionWord & 0x00F0) >> 4;
    ConfigNumLines = OptionWord & 0x000F;
}



LongWord StringArt(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2StringArt ();
			break;
 	    case BlankT2:
            if(data2 & bmiBlankNow)
                ConfigQuitAfterOne=0;
            movePtr=(Word *) data1;
 		    Result = BlankT2StringArt ();
			break;
		case SaveT2:
			SaveT2StringArt();
		    break;
		case LoadSetupT2:
			LoadSetupT2StringArt();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
 	        break;
		case HitT2:
			Result = HitT2StringArt(data2);
			break;
	}
	return Result;
}