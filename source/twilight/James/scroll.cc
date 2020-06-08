/*
**                       Scroll for T2  by  James C. Smith
*/

#pragma keep "Scroll"
#pragma cdev Scroll
#pragma optimize -1
#pragma debug 0

#include "T23.H"
#include <string.h>
#include <memory.h>
#include <types.h>
#include <control.h>
#include <resources.h>


#define ScrollIcon                       0x0010DD01l

#define ControlList                      0x00001003l

#define IconSontrol                      0x00000001l
#define SizePopUp                        0x00000002l
#define LinesPerFramePopUp               0x00000003l

#define MaxLinesPerFrame 8

#pragma lint 0

pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);

LongWord MakeT2Scroll(void);
void LoadSetupT2Scroll(void);
void SaveConfigResource(char *, word);
word LoadConfigResource(char *, word);
LongWord HitT2Scroll(LongWord);
void SaveT2Scroll(void);

Word SetupFileNumber;
GrafPortPtr SetupWindow;
word OptionWord;
char *ConfigNameString="\pScroll Config";


word ConfigSize,ConfigLinesPerFrame;

long LinesPerFrame;
long NumLinesToScroll;
long FirstLine;
long YV;
long TimeTillMove;

Long OldTick=0, TmpTick;
Word *movePtr;
char Buffer[160*MaxLinesPerFrame];
long VRam;

int ColorTableCount[16]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

LongWord BlankT2Scroll(void)
{
    unsigned tmp2, SL, CT;

 /*   long NumLinesToScroll2, LinesPerFrame2, YV2;
    char *FirstLine2, Buffer2[MaxLinesPerFrame];      */

    if((*((char *)0x00C035))& 0x08)
        VRam=0xE12000l;
    else
        VRam=0x012000l;


    for(SL=0; SL<200; SL++)        /* Count the ocurences of references to each color table in the SCBs */
        ColorTableCount[*((char *) (0xE19D00+SL)) & 0x0F]++;
    SL=0;
    for(CT=1; CT<16; CT++)     /* find the color table that has the most ocurences */
        if(ColorTableCount[CT] > ColorTableCount[SL])
            SL=CT;


    /* make sure all SCBs are set to color table SL (the ones used the most)*/
    tmp2=*((char *) (0xE12000+0x007DC7)) & ((char)0xF0);
    tmp2|=SL;
    memset((void *) (0xE12000+0x007D00), tmp2, (size_t) 200);




    if(ConfigSize != 200)
    {
        if((ConfigLinesPerFrame<<1) > ConfigSize) ConfigLinesPerFrame=ConfigSize>>1;
        ConfigSize=(ConfigSize/ConfigLinesPerFrame)*ConfigLinesPerFrame;
    }
    LinesPerFrame=ConfigLinesPerFrame*160l;
/*    LinesPerFrame2=ConfigLinesPerFrame;      */
    NumLinesToScroll=ConfigSize*160l;
/*    NumLinesToScroll2=ConfigSize;       */
    FirstLine=0l*160l;
/*    FirstLine2=(void *) (0xE12000l+0x7D00l);     */
    YV=160l;
/*    YV2=1;     */
    TimeTillMove=0;

        while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
        {
          /*  TmpTick=OldTick;
            while((OldTick=TickCount())==(TmpTick));   */
            if(ConfigSize != 200) {
                if(!TimeTillMove) {
                    TimeTillMove=NumLinesToScroll;
                    FirstLine+=YV;
/*                    FirstLine2+=YV2;      */
                    if(FirstLine==0 | (FirstLine+NumLinesToScroll==200l*160l))
                    {
                        YV=(-YV);
/*                        YV2=(-YV2);   */
                    }
                }
                TimeTillMove-=LinesPerFrame;
            }
            BlockMove((void *)(VRam+FirstLine), Buffer, (long) (LinesPerFrame));
            BlockMove((void *)(VRam+LinesPerFrame+FirstLine), (void *)(VRam+FirstLine), (long) NumLinesToScroll-LinesPerFrame);
            BlockMove(Buffer, (void *)(VRam+ FirstLine+ (NumLinesToScroll-LinesPerFrame)), (long) LinesPerFrame);
/*          BlockMove((void *)(FirstLine2), Buffer2, (long) (LinesPerFrame2));
            BlockMove((void *)(LinesPerFrame2+FirstLine2), (void *)(FirstLine2), (long) NumLinesToScroll2-LinesPerFrame2);
            BlockMove(Buffer2, (void *)(FirstLine2+ (NumLinesToScroll2-LinesPerFrame2)), (long) LinesPerFrame2);*/
    	}
	return (LongWord) NULL;
}

void SaveT2Scroll(void)
{
	Word FileNumber;

/* Save current resource file and switch in Twilight.Setup */
	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
/* Save control values */
	ConfigSize = GetCtlValue (GetCtlHandleFromID (SetupWindow, SizePopUp));
	ConfigLinesPerFrame = GetCtlValue (GetCtlHandleFromID (SetupWindow, LinesPerFramePopUp));
    OptionWord=((ConfigLinesPerFrame-1)<<8) | ConfigSize;
	SaveConfigResource(ConfigNameString, OptionWord);

/*****************************/
/* Restore old resource file */
/*****************************/

	SetCurResourceFile (FileNumber);
}



LongWord HitT2Scroll(LongWord ControlHit)
{
	LongWord EnableFlag = 0L;

	if (ControlHit == LinesPerFramePopUp)
		EnableFlag = 1L;
	if (ControlHit == SizePopUp)
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

LongWord MakeT2Scroll (void)
{
    CtlRecHndl junk;
	Word FileNumber;

	FileNumber = GetCurResourceFile ();
	SetCurResourceFile (SetupFileNumber);
	LoadSetupT2Scroll();
    SetCurResourceFile (FileNumber);
	junk=NewControl2(SetupWindow, resourceToResource, (long) ControlList);
	SetCtlValue (ConfigSize, GetCtlHandleFromID (SetupWindow, SizePopUp));
	SetCtlValue (ConfigLinesPerFrame, GetCtlHandleFromID (SetupWindow, LinesPerFramePopUp));
	return 0x03l;
}



void LoadSetupT2Scroll(void)
{

/*  Option word format
**     0x0F00 = LinesPerFrame
**     0X00FF = Size
*/

	OptionWord = LoadConfigResource (ConfigNameString, 0x07C8);
    ConfigLinesPerFrame = ((OptionWord & 0x0F00)>>8)+1;
    ConfigSize = OptionWord & 0x00FF;
}



LongWord Scroll(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
        case MakeT2:
			SetupWindow = (GrafPortPtr) data1;
			SetupFileNumber = (Word) data2;
			Result = MakeT2Scroll ();
			break;
 	    case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2Scroll ();
			break;
		case SaveT2:
			SaveT2Scroll();
		    break;
		case LoadSetupT2:
			LoadSetupT2Scroll();
            break;
		case UnloadSetupT2:
	        break;
		case KillT2:
		    break;
		case HitT2:
			Result = HitT2Scroll(data2);
			break;
	}
	return Result;
}