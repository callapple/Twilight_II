/*
**                       Twilight for T2  by  James C. Smith
*/

#pragma keep "Twilight"
#pragma cdev Twilight
#pragma optimize -1
#pragma debug 0

#include "T2.H"
#include "random3.h"
#include <quickdraw.h>
#include <string.h>
#include <memory.h>
#include <types.h>
#include <control.h>
#include <resources.h>


#define ClockIcon                        0x0010DD01

#define ControlList                      0x00001003

#define IconControl                      0x00000001
#define FastCB                           0x00000002
#define NumBuildingsPU                   0x00000003
#define NumStarsPU                       0x00000004
#define BuildingHeightPU                 0x00000005
#define BuildingWidthPU                  0x00000006
#define LimitCB                          0x00000007


#define MaxLinesPerFrame 8

#pragma lint 0

pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);

LongWord MakeT2Twilight(void);
void LoadSetupT2Twilight(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Twilight(LongWord);
void SaveT2Twilight(void);

void Wait(int);
int HitBuilding(int,int,int);
void Erase(int);

Word SetupFileNumber;
GrafPortPtr SetupWindow;
word OptionWord;
char *ConfigNameString="\pTwilightModule Config";


word ConfigNumBuildings, ConfigBuildingHeight, ConfigBuildingWidth, ConfigNumStars, ConfigFast, ConfigLimit;
word NumBuildings, BuildingHeight, BuildingWidth, NumStars;

Long OldTick=0, TmpTick;
Word *movePtr;
long VRam;


#define MaxNumStars        900
#define MaxNumBuildings    16

unsigned int X[MaxNumStars], Y[MaxNumStars];
int BX[MaxNumBuildings], BHeight[MaxNumBuildings], BWidth[MaxNumBuildings];
int XO[MaxNumBuildings], YO[MaxNumBuildings], XI[MaxNumBuildings], YI[MaxNumBuildings];

int Building, Star;

int MyColorTable[]={0x000,0xFF7,0xFFF,0xEEE,0xDDD,0xCCC,0xBBB,0xAAA,0x999,0x888,0x777,0x666,0x555,0x444,0x333,0x222};


void Wait(int WaitLength)
{
    TmpTick=OldTick;
    while(((OldTick=TickCount())<=TmpTick+WaitLength) && (!(*movePtr)));
}

int HitBuilding(int X,int Y, int B) /* b=building to start the search with */
{
    if(NumBuildings)
    for(; B<NumBuildings; B++)
        if(Y>=(200-BHeight[B])+YO[B] && X>=BX[B]+XO[B] && X<=BX[B]+BWidth[B]+XO[B])
            return 1;
    return 0;
}

void Erase(int StarNumber)
{
    unsigned int XD, YD;

    XD=X[StarNumber] & 0x800;
    YD=Y[StarNumber] & 0x800;
    X[StarNumber] &= 0x7FF;
    Y[StarNumber] &= 0x7FF;
    set_pixel(X[StarNumber], Y[StarNumber], 0);
    if(XD)
        set_pixel(X[StarNumber]+1, Y[StarNumber], 0);
    if(YD)
    {
        set_pixel(X[StarNumber], Y[StarNumber]+1, 0);
        if(XD)
            set_pixel(X[StarNumber]+1, Y[StarNumber]+1, 0);
    }
}


LongWord BlankT2Twilight(void)
{
    if((*((char *)0x00C035))& 0x08)
        VRam=0xE10000l;
    else
        VRam=0x010000l;


	init_plot((char *) VRam,(char *)GetAddress(1), toT2Str);
	init_random(toT2Str);
    set_random_seed();

    SetColorTable(0, (void *) MyColorTable);

    for(Star=0; Star<NumStars; Star++)
    {
        X[Star]=-1;
        Y[Star]=-1;
    }
    if(NumBuildings)
    for(Building=0; Building <NumBuildings; Building++)
    {
        do {
            XI[Building]=(random() % 4)+2;
            YI[Building]=((random()>>2) % 4)+2;
        } while (XI[Building]+YI[Building] < 7);
        XO[Building]=(random()>>1) % 8;
        YO[Building]=(random()>>2) % 8;
        BWidth[Building]=((random() % (BuildingWidth>>1)) + (BuildingWidth>>1))/XI[Building]*XI[Building]-1;
        BX[Building]=(random() % (320-BWidth[Building]))/XI[Building]*YI[Building];
        BHeight[Building]=(random() % (BuildingHeight>>1))+(BuildingHeight>>1);
    }
        while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
        {
            Star=random() % NumStars;
            if(X[Star]!=-1)
                Erase(Star);
            if(!ConfigFast)
                Wait((random() % 20)+5);
            if(NumBuildings && (random() & 0x13))
            {
                do{
                    Building=random() % NumBuildings;
                    X[Star]=((random() % BWidth[Building]) + BX[Building])/XI[Building]*XI[Building]+XO[Building];
                    Y[Star]=(200-(random() % BHeight[Building]))/YI[Building]*YI[Building]+YO[Building];
                } while(HitBuilding(X[Star],Y[Star],Building+1));
                set_pixel(X[Star], Y[Star], 1);
                if(!ConfigLimit)
                {
                    if(XI[Building] > 4)
                    {
                        set_pixel(X[Star]+1, Y[Star], 1);
                        if(YI[Building] > 4)
                            set_pixel(X[Star]+1, Y[Star]+1, 1);
                        X[Star] |=0x800;
                    }
                    if(YI[Building] > 4)
                    {
                        set_pixel(X[Star] & 0x7FF, Y[Star]+1, 1);
                        Y[Star] |=0x800;
                    }
                }
            } else {
                int tmp;

                do{
                    X[Star]=random() % 320;
                    tmp=(random() % 170)+10;
                    Y[Star]=tmp*tmp/190;
                } while(HitBuilding(X[Star],Y[Star],0));
                set_pixel(X[Star], Y[Star], (random() % 14) + 2);
            }
            if(!ConfigFast)
                Wait((random() % 20)+5);
    	}
	return (LongWord) NULL;
}

void SaveT2Twilight(void)
{
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigNumBuildings =GetCtlValue (GetCtlHandleFromID (SetupWindow, NumBuildingsPU))-1;
	ConfigBuildingHeight =GetCtlValue (GetCtlHandleFromID (SetupWindow, BuildingHeightPU))-1;
	ConfigBuildingWidth =GetCtlValue (GetCtlHandleFromID (SetupWindow, BuildingWidthPU))-1;
	ConfigNumStars = GetCtlValue (GetCtlHandleFromID (SetupWindow, NumStarsPU))-1;
	ConfigFast = GetCtlValue (GetCtlHandleFromID (SetupWindow, FastCB));
	ConfigLimit = GetCtlValue (GetCtlHandleFromID (SetupWindow, LimitCB));
    OptionWord=(ConfigLimit << 14) | (ConfigFast<<13)|(ConfigNumStars<<10)|(ConfigBuildingWidth<<7)|(ConfigBuildingHeight<<4)|ConfigNumBuildings;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Twilight(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == NumBuildingsPU)
		EnableFlag = 1L;
	if (ControlHit == BuildingHeightPU)
		EnableFlag = 1L;
	if (ControlHit == BuildingWidthPU)
		EnableFlag = 1L;
	if (ControlHit == NumStarsPU)
		EnableFlag = 1L;
	if (ControlHit == FastCB)
		EnableFlag = 1L;
	if (ControlHit == LimitCB)
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
		(Word **) NewHandle (sizeof (Word), GetCurResourceApp(), attrLocked, NULL);
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

LongWord MakeT2Twilight (void)
{
    CtlRecHndl junk;
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Twilight();
    SetCurResourceFile (FileNumber);
	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigNumBuildings+1, GetCtlHandleFromID (SetupWindow, NumBuildingsPU));
	SetCtlValue (ConfigBuildingHeight+1, GetCtlHandleFromID (SetupWindow, BuildingHeightPU));
	SetCtlValue (ConfigBuildingWidth+1, GetCtlHandleFromID (SetupWindow, BuildingWidthPU));
	SetCtlValue (ConfigNumStars+1, GetCtlHandleFromID (SetupWindow, NumStarsPU));
	SetCtlValue (ConfigFast, GetCtlHandleFromID (SetupWindow, FastCB));
	SetCtlValue (ConfigLimit, GetCtlHandleFromID (SetupWindow, LimitCB));
	return 0x07l;
}



void LoadSetupT2Twilight(void)
{

/*  Option word format
**     0X4000 = Limit
**     0X2000 = Fast
**     0X1C00 = NumStars
**     0X0380 = BuildingWidth
**     0X0070 = BuildingHeight
**     0X000F = NumBuildings
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x1C37);
    ConfigNumBuildings = OptionWord & 0x000F;
    NumBuildings=ConfigNumBuildings;
    ConfigBuildingHeight = (OptionWord & 0x0070) >> 4;
    BuildingHeight=(ConfigBuildingHeight+1)*25;
    ConfigBuildingWidth = (OptionWord & 0x0380) >> 7;
    BuildingWidth=(ConfigBuildingWidth+1)*20;
    ConfigNumStars = (OptionWord & 0x1C00) >>10;
    NumStars=(ConfigNumStars+1)*100;
    ConfigFast = (OptionWord & 0x2000) >> 13;
    ConfigLimit = (OptionWord & 0x4000) >> 14;
}



LongWord Twilight(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Twilight ();
			break;
 	    case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2Twilight ();
			break;
		case SaveT2:
			SaveT2Twilight();
		    break;
		case LoadSetupT2:
			LoadSetupT2Twilight();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result = HitT2Twilight(data2);
			break;
	}
	return Result;
}