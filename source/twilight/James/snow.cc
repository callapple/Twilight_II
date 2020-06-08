/*
**                       Snow for T2  by  James C. Smith
*/

#pragma keep "Snow"
#pragma cdev Snow
#pragma optimize -1
#pragma debug 0


#include "T2.H"
#include "Random3.h"
#include "Plot2.h"
#include <string.h>
#include <quickdraw.h>
#include <control.h>
#include <resources.h>
#include <memory.h>
#include <locator.h>


pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);

#pragma lint 0

#define ControlList                      0x00001003l

#define IconControl                      0x00000001l
#define TimeBeforeClearPopUp             0x00000002l
#define NumFlakesPopUp                   0x00000003l
#define ClearFirstCB                     0x00000004l


LongWord MakeT2Snow(void);
void LoadSetupT2Snow(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Snow(LongWord);
void SaveT2Snow(void);
LongWord BlankT2Snow(void);


Word SetupFileNumber;
GrafPortPtr SetupWindow;
word OptionWord;
char *VRam;
int MaxYV;

int i, OldX,OldY;
word ConfigNumFlakes, ConfigTimeBeforeClear, ConfigClearFirst;
Word *movePtr;
char *ConfigNameString="\pSnow Config";

typedef struct Flake {
	unsigned int    x;
	unsigned int    y;
    unsigned int    xv;
    unsigned int    yv;
    char            Under;
};


LongWord StartTime;
word Colors[16]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0x0FFF,0x0FFF};
struct Flake Flakes[130], *AFlake;

LongWord BlankT2Snow(void)
{
    int ScreenWasCleared=0;

    if(ConfigNumFlakes>130 || ConfigNumFlakes < 10)
    {
        SysBeep();
        SysBeep();
        ConfigNumFlakes=60;
    }
    MaxYV=ConfigNumFlakes>>1;
    if((*((char *)0x00C035))& 0x08)
        VRam=(void *) 0xE10000l;
    else
        VRam=(void *) 0x010000l;
	init_plot((char *) VRam,(char *)GetAddress(1), toT2Str);
	init_random(toT2Str);
    set_random_seed();

    if(ConfigClearFirst)
    {
        ScreenWasCleared=1;
        ClearScreen(0);
        SetAllSCBs(GetStandardSCB() & 0x7F);
        SetColorTable(0, (void *) Colors);
    }
    StartTime=TickCount();

    for(i=0; i<ConfigNumFlakes; i++)
    {
        Flakes[i].y=((random() % 185)+15)<<4;
        do {
            Flakes[i].x=((random() % 380)-60)<<4;
        } while(get_pixel(Flakes[i].x>>4,Flakes[i].y>>4)==15);
        Flakes[i].xv=random() % 10;
        Flakes[i].yv=(random() % MaxYV)+10;
        Flakes[i].Under=getset_pixel(Flakes[i].x>>4, Flakes[i].y>>4, 15);
    }
	while(!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
        if((TickCount()-StartTime)/3600 >= ConfigTimeBeforeClear)
        {
            ScreenWasCleared=1;
            ClearScreen(0);
            StartTime=TickCount();
            for(i=0; i<ConfigNumFlakes; i++)
                OldX=Flakes[i].Under=0;
        }
        for(i=0; i<ConfigNumFlakes; i++)
        {
            AFlake=&Flakes[i];
            OldX=AFlake->x;
            OldY=AFlake->y;
            set_pixel(OldX>>4,OldY>>4,AFlake->Under);
            AFlake->x+=AFlake->xv;
            AFlake->y+=AFlake->yv;
            /* try to slide left or right or stop if you have to if....  */
            if(get_pixel(AFlake->x>>4,AFlake->y>>4)==15)
            {
                AFlake->xv=0;
                AFlake->yv=16;       /*AFlake->yv > 16 ? 16:5;   */
                AFlake->x=OldX;
                AFlake->y=OldY+AFlake->yv;
                    if(get_pixel(AFlake->x>>4,AFlake->y>>4)==15 && OldX<(319<<4))
                        AFlake->x=OldX+16;
                    if(get_pixel(AFlake->x>>4,AFlake->y>>4)==15 && OldX>((0)+15))
                        AFlake->x=OldX-16;
                    if(random() & 0x07)
                    {
                        if(get_pixel(AFlake->x>>4,AFlake->y>>4)==15 && OldX>((1<<4)+15))
                            AFlake->x=OldX-32;
                        if(get_pixel(AFlake->x>>4,AFlake->y>>4)==15 && OldX<(318<<4))
                            AFlake->x=OldX+32;
                    }
                if(get_pixel(AFlake->x>>4,AFlake->y>>4)==15)
                {
                        AFlake->y=ConfigClearFirst ? 0:(13<<4);
                        do {
                            AFlake->x=((random() % 380)-60)<<4;
                        } while(get_pixel(AFlake->x>>4,AFlake->y>>4)==15);
                        AFlake->xv=random() % 10;
                        AFlake->yv=(random() % MaxYV)+10;
                        set_pixel(OldX>>4,OldY>>4,15);
                        AFlake->Under=getset_pixel(AFlake->x>>4, AFlake->y>>4, 15);
                } else {
                    AFlake->Under=getset_pixel(AFlake->x>>4, AFlake->y>>4, 15);
                }
            } else {
                AFlake->Under=getset_pixel(AFlake->x>>4, AFlake->y>>4, 15);
            }
        } /* end loop for num flakes */

	}  /* end while no movement */
    if(ScreenWasCleared)
        return(LongWord) bmrFadeIn;
    else
    	return(LongWord) NULL;
}


void SaveT2Snow(void)
{
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber=GetCurResourceFile();
	SetCurResourceFile(SetupFileNumber);
/* Save control values */
	ConfigNumFlakes=GetCtlValue(GetCtlHandleFromID(SetupWindow, NumFlakesPopUp));
	ConfigTimeBeforeClear=GetCtlValue(GetCtlHandleFromID(SetupWindow, TimeBeforeClearPopUp));
	ConfigClearFirst=GetCtlValue(GetCtlHandleFromID(SetupWindow, ClearFirstCB));
    OptionWord=(ConfigClearFirst<<15) | (ConfigNumFlakes<<8) |   ConfigTimeBeforeClear;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile(FileNumber);
}



LongWord HitT2Snow(LongWord ControlHit)
{
	LongWord EnableFlag=0L;

	if(ControlHit == NumFlakesPopUp)
		EnableFlag=1L;
	if(ControlHit == TimeBeforeClearPopUp)
		EnableFlag=1L;
	if(ControlHit == ClearFirstCB)
		EnableFlag=1L;
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


LongWord MakeT2Snow(void)
{
	Word FileNumber;

	FileNumber=GetCurResourceFile();
	SetCurResourceFile(SetupFileNumber);
	LoadSetupT2Snow();
    SetCurResourceFile(FileNumber);
	NewControl2(SetupWindow, resourceToResource,(long) ControlList);
	SetCtlValue(ConfigNumFlakes, GetCtlHandleFromID(SetupWindow, NumFlakesPopUp));
	SetCtlValue(ConfigTimeBeforeClear, GetCtlHandleFromID(SetupWindow, TimeBeforeClearPopUp));
	SetCtlValue(ConfigClearFirst, GetCtlHandleFromID(SetupWindow, ClearFirstCB));
	return 0x04l;
}



void LoadSetupT2Snow(void)
{

/*  Option word format
**     0x8000=ClearFirst
**     0x7F00=NumFlakes
**     0x00FF=TimeBeforeClear
*/

	OptionWord=LoadConfigResource(ConfigNameString, 0x3C3C);
    ConfigClearFirst     =(OptionWord & 0x8000) >> 15;
    ConfigNumFlakes      =(OptionWord & 0x7F00) >> 8;
    ConfigTimeBeforeClear= OptionWord & 0x00FF;
}

LongWord Snow(LongWord data2, LongWord data1, Word message)
{
	LongWord Result=0L;

	switch(message)
	{
        case MakeT2:
			SetupWindow=(GrafPortPtr) data1;
			SetupFileNumber=(Word) data2;
			Result=MakeT2Snow();
			break;
 	    case BlankT2:
            movePtr=(Word *) data1;
 		    Result=BlankT2Snow();
            break;
		case SaveT2:
			SaveT2Snow();
		    break;
		case LoadSetupT2:
			LoadSetupT2Snow();
            if(ConfigClearFirst)
                Result=lmrFadeOut;
            else
                Result=lmrReqUsableScreen;
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result=HitT2Snow(data2);
			break;
	}
	return Result;
}